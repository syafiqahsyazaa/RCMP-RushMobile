import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_setup_dialog.dart';
import '../../theme/app_theme.dart';
import 'company_staff_screen.dart';
import '../../services/notification_service.dart'; // notifiction
import 'dart:async'; // !

class VendorDashboardScreen extends StatefulWidget {
VendorDashboardScreen({super.key});

@override
State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}
class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
Map<String, dynamic> _vendorData = {};
bool _isLoading = true;
bool _isInitialized = false;

int _currentMenuIndex = 0;
final TextEditingController _searchController = TextEditingController();
List<dynamic> _senaraiTiketVendorLive = [];
List<dynamic> _senaraiTiketTapisSearch = [];
bool _isTicketsLoading = true;

int _totalTickets = 0;
int _progressTickets = 0;
int _closedTickets = 0;

String _statusKadDipilihLive = 'ALL';

Timer? _notifPollTimer; // 🕒 PEMASA POLLING !
String _lastKnownTopTicketId = ""; // Track tiket terakhir

@override
void initState() {
super.initState();
_searchController.addListener(_jalankanPenapisSearchMurni);

// AKTIFKAN POLLING SETIAP 30 SAAT !
_notifPollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
  _tarikTiketVendorLive(isBackground: true);
});
}

@override
void dispose() {
_notifPollTimer?.cancel(); // Matikan pemasa bila keluar
_searchController.removeListener(_jalankanPenapisSearchMurni);
_searchController.dispose();
super.dispose();
}

@override
void didChangeDependencies() {
super.didChangeDependencies();
if (!_isInitialized) {
final Object? args = ModalRoute.of(context)?.settings.arguments;
if (args != null && args is Map<String, dynamic>) {
  // 🚀 KUNCI KESELAMATAN: Ambil data terus dari args murni!
  final rawFirstLogin = args['first_login'];

  setState(() {
    _vendorData = Map<String, dynamic>.from(args);
    _isLoading = false;
  });

  print("🔍 DASHBOARD DETECT LIVE STATUS: $rawFirstLogin");

  _tarikTiketVendorLive();

  // 🛠️ FORMULA TEGAR: Check guna toString() supaya kalis ralat murni!
  if (rawFirstLogin.toString() == '1') {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("🚀 TRIGGERING PROFILE SETUP DIALOG MURNI...");
      showProfileSetupDialog(
        context: context,
        vendorData: _vendorData,
        onProfileFinalized: () {
          setState(() { _vendorData['first_login'] = 0; });
          _tarikTiketVendorLive(); // Refresh murni
        },
      );
    });
  }
} else {
setState(() => _isLoading = false);
}
_isInitialized = true;
}
}

// =========================================================================
// get DATA TIKET VENDOR LIVE DARI DATABASE LARAGON
// =========================================================================
Future<void> _tarikTiketVendorLive({bool isBackground = false}) async {
final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
final String idVendorSemasa = (_vendorData['vendor_id'] ?? '0').toString();

final url = Uri.parse('http://$domain/helpdesk_api/get_vendor_tickets.php?vendor_id=$idVendorSemasa&b_cache=${DateTime.now().millisecondsSinceEpoch}');

try {
if (!isBackground) setState(() => _isTicketsLoading = true);
final respon = await http.get(url);
if (respon.statusCode == 200) {
final List<dynamic> dataDisedut = json.decode(respon.body);

int kaunterTotal = dataDisedut.length;
int kaunterProgress = 0;
int kaunterClosed = 0;

for (var tiket in dataDisedut) {
String stat = (tiket['status'] ?? 'open').toString().toLowerCase().trim();
if (stat == 'closed') {
kaunterClosed++;
} else {
kaunterProgress++; 
}
}

// NOTIFIKASI PHONE DIBUANG!

setState(() {
_senaraiTiketVendorLive = dataDisedut;
_senaraiTiketTapisSearch = dataDisedut;
_totalTickets = kaunterTotal;
_progressTickets = kaunterProgress;
_closedTickets = kaunterClosed;
_isTicketsLoading = false;
});
}
} catch (e) {
if (!isBackground) {
  print("Ralat sedut tiket vendor live: $e");
  setState(() => _isTicketsLoading = false);
}
}
}

  // =========================================================================
  // 🎨 WIDGET HELPER UNTUK NOTIFIKASI VENDOR
  // =========================================================================
  Widget _buildNotifItem(dynamic tkt) {
    String initials = (tkt['title'] ?? 'T').toString().substring(0, 2).toUpperCase();
    bool isBreached = false;
    try {
      String dateStr = tkt['created_at'] ?? '';
      if (dateStr.isNotEmpty) {
        DateTime createdTime = DateTime.parse(dateStr);
        int mins = _kiraMinitBekerjaSLA(createdTime, DateTime.now());
        isBreached = mins > 300; // Vendor deadline typically 5 hours (300 mins)
      }
    } catch (e) {}

    return InkWell(
      onTap: () {
        Navigator.pop(context); // Tutup menu loceng
        Navigator.pushNamed(context, '/vendor_ticket_workspace', arguments: tkt);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isBreached ? const Color(0xFFFDF2F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isBreached ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isBreached ? const Color(0xFFD64545) : const Color(0xFF3B82F6),
              child: isBreached 
                ? const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white)
                : Text(initials, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tkt['title'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      if (isBreached)
                        const Text('BREACHED •', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFD64545))),
                    ],
                  ),
                  Text(tkt['ticket_id'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    isBreached ? 'SLA clock breached! Fix action required.' : 'Ticket status — ${tkt['status']}',
                    style: TextStyle(fontSize: 10, color: isBreached ? const Color(0xFFB91C1C) : Colors.grey, fontWeight: isBreached ? FontWeight.w500 : FontWeight.normal),
                  ),
                  if (!isBreached)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('${tkt['my_department'] ?? 'Dept'} · ${tkt['created_at'] ?? ''}', style: const TextStyle(fontSize: 9, color: Colors.black26)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _kiraMinitBekerjaSLA(DateTime start, DateTime end) {
    int minutes = 0;
    DateTime current = start;
    while (current.isBefore(end)) {
      if (current.weekday <= 5 && current.hour >= 8 && current.hour < 17) {
        minutes++;
      }
      current = current.add(const Duration(minutes: 1));
    }
    return minutes;
  }

  // =========================================================================
  // =========================================================================
  void _jalankanPenapisSearchMurni() {
    String teksCarian = _searchController.text.toLowerCase().trim();

    setState(() {
      _senaraiTiketTapisSearch = _senaraiTiketVendorLive.where((tiket) {
        // FASA 1: Saringan berasaskan Kotak Carian (Search Text)
        String id = (tiket['ticket_id'] ?? '').toString().toLowerCase();
        String title = (tiket['title'] ?? '').toString().toLowerCase();
        String dept = (tiket['my_department'] ?? '').toString().toLowerCase();

        bool matchSearch = teksCarian.isEmpty ||
            id.contains(teksCarian) ||
            title.contains(teksCarian) ||
            dept.contains(teksCarian);

        // FASA 2: Saringan berasaskan Kad Atas yang sedang aktif!
        String statRaw = (tiket['status'] ?? 'open').toString().toLowerCase().trim();
        bool matchCard = true;

        if (_statusKadDipilihLive == 'IN_PROGRESS') {
          matchCard = (statRaw != 'closed'); // Mengambil data open dan in_progress seacuan pembahagi kaunter
        } else if (_statusKadDipilihLive == 'CLOSED') {
          matchCard = (statRaw == 'closed');
        }

        return matchSearch && matchCard;
      }).toList();
    });
    print("FILTER STATE SYNCED: Card [$_statusKadDipilihLive] | Search keyword: '$teksCarian'");
  }


Widget _buildPureUIStatCard({required String value, required String label, required String subLabel, required IconData icon, required Color color}) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
child: Row(
children: [
CircleAvatar(radius: 14, backgroundColor: color.withOpacity(0.1), child: Icon(icon, size: 13, color: color)),
const SizedBox(width: 6),
Expanded(
child: FittedBox(
fit: BoxFit.scaleDown,
alignment: Alignment.centerLeft,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.1)),
Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.3)),
Text(subLabel, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w500)),
],
),
),
)
],
),
);
}

Widget _buildPureUITicketCard(Map<String, dynamic> tiket) {
String id = tiket['ticket_id'] ?? '—';
String title = tiket['title'] ?? 'No Title';
String dept = tiket['my_department'] ?? 'IT Department';
String statusRaw = (tiket['status'] ?? 'OPEN').toString().toUpperCase();
String priorityRaw = (tiket['priority'] ?? 'MEDIUM').toString().toUpperCase();

return Container(
margin: const EdgeInsets.only(bottom: 14),
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
CircleAvatar(radius: 18, backgroundColor: const Color(0xFF0D3B66).withOpacity(0.08), child: const Icon(Icons.confirmation_number_outlined, size: 16, color: Color(0xFF0D3B66))),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text('TICKET ID: #$id', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0D3B66))),
Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
decoration: BoxDecoration(color: statusRaw == 'CLOSED' ? const Color(0xFFEAF7EE) : const Color(0xFFFFF8E6), borderRadius: BorderRadius.circular(6)),
child: Text(statusRaw, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: statusRaw == 'CLOSED' ? const Color(0xFF2E9E52) : const Color(0xFFC9A227)))
),
],
),
const SizedBox(height: 6),
Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
const SizedBox(height: 6),
Text('🏢 From Department: $dept', style: const TextStyle(fontSize: 11, color: Colors.black87)),
const SizedBox(height: 8),
const Divider(height: 10, color: Colors.black12),
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Row(children: [const Icon(Icons.flag_outlined, size: 12, color: Colors.grey), const SizedBox(width: 4), Text('PRIORITY: $priorityRaw', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: priorityRaw == 'HIGH' ? Colors.red : Colors.grey))]),

TextButton.icon(
icon: const Icon(Icons.launch_rounded, size: 12, color: Color(0xFF0D3B66)),
label: const Text('View Workspace', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0D3B66))),
onPressed: () async {
// Tolong daftarkan route nama '/vendor_ticket_workspace' di fail main.dart
final hasilRefresh = await Navigator.pushNamed(
context,
'/vendor_ticket_workspace',
arguments: tiket
);
if (hasilRefresh == true) {
_tarikTiketVendorLive(); // Auto-refresh data kaunter bila vendor patah balik belakang!

}
}
),
],
)
],
),
)
],
),
);
}

  Widget _buildWorkOrdersLayoutView(String syarikat) {
    return RefreshIndicator(
      onRefresh: _tarikTiketVendorLive,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Work Orders — $syarikat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Tickets assigned to your company by staff.', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
          const SizedBox(height: 20),

          // =========================================================================
          // BAHAGIAN A: TIGA KAD
          // =========================================================================
          Row(
            children: [
              // 1. KAD TOTAL ALL TICKETS
              Expanded(
                child: InkWell(
                  onTap: () {
                    _statusKadDipilihLive = 'ALL';
                    _jalankanPenapisSearchMurni(); // Cetus saringan gabungan!
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _statusKadDipilihLive == 'ALL' ? const Color(0xFF0D3B66) : Colors.black12,
                          width: _statusKadDipilihLive == 'ALL' ? 2.0 : 1.0
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 16, backgroundColor: const Color(0xFF0D3B66).withOpacity(0.1), child: const Icon(Icons.assignment_outlined, size: 14, color: Color(0xFF0D3B66))),
                        const SizedBox(width: 8),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('$_totalTickets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.1)), const Text('TOTAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black54, letterSpacing: 0.3)), const Text('ALL', style: TextStyle(fontSize: 8, color: Color(0xFF0D3B66), fontWeight: FontWeight.bold))]))
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. KAD PROGRESS ACTIVE TICKETS
              Expanded(
                child: InkWell(
                  onTap: () {
                    _statusKadDipilihLive = 'IN_PROGRESS';
                    _jalankanPenapisSearchMurni();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: _statusKadDipilihLive == 'IN_PROGRESS' ? const Color(0xFFC9A227) : Colors.transparent,
                          width: _statusKadDipilihLive == 'IN_PROGRESS' ? 2.0 : 0.0
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildPureUIStatCard(value: '$_progressTickets', label: 'PROGRESS', subLabel: 'ACTIVE', icon: Icons.schedule_outlined, color: const Color(0xFFC9A227)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3. KAD CLOSED DONE TICKETS
              Expanded(
                child: InkWell(
                  onTap: () {
                    _statusKadDipilihLive = 'CLOSED';
                    _jalankanPenapisSearchMurni();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: _statusKadDipilihLive == 'CLOSED' ? const Color(0xFF2E9E52) : Colors.transparent,
                          width: _statusKadDipilihLive == 'CLOSED' ? 2.0 : 0.0
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildPureUIStatCard(value: '$_closedTickets', label: 'CLOSED', subLabel: 'DONE', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF2E9E52)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // =========================================================================
          // 🏢 BAHAGIAN B: KOTAK TEXTFIELD SEARCH
          // =========================================================================
          Row(
            children: [
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
                      child: TextField(
                          controller: _searchController, // memanggil controller asal anda!
                          decoration: const InputDecoration(
                              hintText: 'Search by ticket ID, department, title...',
                              hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey),
                              prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12)
                          )
                      )
                  )
              ),
            ],
          ),
          const SizedBox(height: 24),

          // =========================================================================
          // 🧑‍💻 BAHAGIAN C: ENGINE RENDERING SENARAI LIST CARDS TIKET VENDOR LIVE 🧑‍💻
          // =========================================================================
          _isTicketsLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              : _senaraiTiketTapisSearch.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(30), child: Text("No tickets assigned to your workspace.", style: TextStyle(fontSize: 12, color: Colors.grey))))
              : Column(
            children: _senaraiTiketTapisSearch.map((tiket) {
              return _buildPureUITicketCard(tiket);
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
String syarikat = _vendorData['company_name'] ?? 'Vendor Company';
return Scaffold(
backgroundColor: const Color(0xFFF4F6F9),
appBar: AppBar(
backgroundColor: Colors.white,
elevation: 0.5,
automaticallyImplyLeading: false,
title: Row(
children: [
  Image.asset(
    'lib/assets/images/unikl_logo.png',
    width: 70,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) => Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: Colors.red, size: 18),
    ),
  ),
const SizedBox(width: 10),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: const [
Text('UNIKL RCMP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy)),
Text('Vendor Portal', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
],
),
],
),
actions: [
Padding(
padding: const EdgeInsets.only(right: 16),
child: Row(
children: [
PopupMenuButton<void>(
icon: Stack(
children: [
const Icon(Icons.notifications_none_rounded, color: AppColors.navy, size: 18),
if (_senaraiTiketVendorLive.where((t) => (t['status'] ?? '').toString().toLowerCase() != 'closed').isNotEmpty)
Positioned(
right: 0, top: 0,
child: Container(
padding: const EdgeInsets.all(2),
decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
child: Text(
_senaraiTiketVendorLive.where((t) => (t['status'] ?? '').toString().toLowerCase() != 'closed').length.toString(),
style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
textAlign: TextAlign.center
),
),
)
],
),
offset: const Offset(0, 45),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
elevation: 8,
color: Colors.white,
itemBuilder: (BuildContext context) {
return [
PopupMenuItem<void>(
enabled: false,
child: SizedBox(
width: 320,
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text('Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
decoration: BoxDecoration(color: const Color(0xFFEAF1FB), borderRadius: BorderRadius.circular(12)),
child: Text('${_senaraiTiketVendorLive.where((t) => (t['status'] ?? '').toString().toLowerCase() != 'closed').length} active', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.navy)),
),
],
),
const Divider(height: 24, color: AppColors.border),
_senaraiTiketVendorLive.where((t) => (t['status'] ?? '').toString().toLowerCase() != 'closed').isEmpty
? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Text("No active notifications!", style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic))))
: SizedBox(
height: 350,
child: ListView.builder(
itemCount: _senaraiTiketVendorLive.where((t) => (t['status'] ?? '').toString().toLowerCase() != 'closed').length,
itemBuilder: (context, idx) {
final tkt = _senaraiTiketVendorLive.where((t) => (t['status'] ?? '').toString().toLowerCase() != 'closed').toList()[idx];
return _buildNotifItem(tkt);
},
),
),
],
),
),
),
];
},
),
const SizedBox(width: 8),
GestureDetector(
onTap: () {
showProfileSetupDialog(
context: context,
vendorData: _vendorData,
onProfileFinalized: () {
_tarikTiketVendorLive(); // Refresh balik senarai bila nama company bertukar
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(backgroundColor: Colors.green, content: Text('Company configurations successfully updated live! 🚀')),
);
},
);
},
child: MouseRegion(
cursor: SystemMouseCursors.click,
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
child: Row(
children: [
const Icon(Icons.business_center_outlined, size: 14, color: AppColors.navy),
],
),
),
),
),
const SizedBox(width: 4),
IconButton(
tooltip: 'Company Staff',
icon: Icon(
Icons.people_outline,
size: 18,
color: _currentMenuIndex == 1 ? const Color(0xFF1A365D) : Colors.grey,
),
onPressed: () => setState(() => _currentMenuIndex = 1),
),
IconButton(
tooltip: 'Logout',
icon: const Icon(Icons.logout, size: 16, color: Colors.redAccent),
onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
),
],
),
),
],
),
body: _isLoading
? const Center(child: CircularProgressIndicator())
    : _vendorData['first_login'] == 1 || _vendorData['first_login'] == '1'
? const Center(child: Text("Awaiting profile configuration validation...", style: TextStyle(color: Colors.grey, fontSize: 12)))
    : _currentMenuIndex == 0
? _buildWorkOrdersLayoutView(syarikat)
    : CompanyStaffScreen(
vendorData: _vendorData,
onBackPressed: () {
setState(() { _currentMenuIndex = 0; });
_tarikTiketVendorLive(); // Refresh kaunter tiket bila balik dari sub-menu
},
),
);
}
}
