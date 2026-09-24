import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../main.dart';

const _staffNavItems = [
  AdminNavItem(Icons.dashboard_outlined, 'Dashboard', '/staff/dashboard'),
  AdminNavItem(Icons.confirmation_number_outlined, 'All Tickets', '/staff/tickets'),
];

/// "All Tickets" — staff view of every ticket assigned to their department, filterable by status tab.
class StaffAllTicketsScreen extends StatefulWidget {
  const StaffAllTicketsScreen({super.key});

  @override
  State<StaffAllTicketsScreen> createState() => _StaffAllTicketsScreenState();
}

class _StaffAllTicketsScreenState extends State<StaffAllTicketsScreen> {
int _tab = 0;
final _tabs = const ['All Tickets', 'Open', 'In Progress', 'Closed'];

// Pengurusan Senarai Data
List<dynamic> _allTickets = [];       // Menyimpan data asal dari database
List<dynamic> _displayedTickets = []; // Menyimpan data selepas ditapis & disususn

// CONTROLLER UNTUK KOTAK CARIAN & VARIABEL UNTUK DROPDOWN SORT
final TextEditingController _searchController = TextEditingController();
String _sortBy = 'Latest'; // Nilai lalai susunan sort
String _namaJabatanStaffLive = "Loading Department...";
bool _isLoading = true;



@override
void initState() {
super.initState();
_ambilSemuaTickets();

// Aktifkan listener untuk kesan taipan user pada kotak carian
_searchController.addListener(_prosesTapisDanSusunData);
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

Future<void> _ambilSemuaTickets() async {
final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
final url = Uri.parse('http://$domain/helpdesk_api/get_staff_dashboard.php?email=$currentLoggedInUserEmail');

try {
final respon = await http.get(url);

if (respon.statusCode == 200) {
final Map<String, dynamic> data = json.decode(respon.body);
setState(() {
  _namaJabatanStaffLive = data['department_label'] ?? 'Staff Support Workspace';
_allTickets = data['open_tickets'] ?? [];
_prosesTapisDanSusunData(); // Jalankan tapisan & susunan pertama kali
_isLoading = false;
});
} else {
print("Gagal muat semua tiket. Status: ${respon.statusCode}");
setState(() => _isLoading = false);
}
} catch (e) {
print("Ralat sambungan Laragon: $e");
setState(() => _isLoading = false);
}
}

// MENAPIS (SEARCH) DAN MENYUSUN (SORT)
void _prosesTapisDanSusunData() {
String kataKunci = _searchController.text.toLowerCase().trim();
List<dynamic> hasilTapisan = [];

// --- BAHAGIAN A: TAPISAN BERDASARKAN TAB STATUS ---
  if (_tab == 0) {
    hasilTapisan = List.from(_allTickets);
  } else {
    String statusTab = _tabs[_tab].toLowerCase().replaceAll(' ', '_');

    hasilTapisan = _allTickets.where((ticket) {
      //  Letak .toLowerCase() pada ticket['status'] so that sama dengan tab!
      String dbStatus = (ticket['status'] ?? 'open').toString().toLowerCase().trim();
      return dbStatus == statusTab;
    }).toList();
  }

// --- BAHAGIAN B: TAPISAN BERDASARKAN TEXT CARIAN (SEARCH BOX) ---
if (kataKunci.isNotEmpty) {
hasilTapisan = hasilTapisan.where((ticket) {
String ticketId = (ticket['ticket_id'] ?? '').toString().toLowerCase();
String title = (ticket['title'] ?? '').toString().toLowerCase();
String email = (ticket['submitter_email'] ?? '').toString().toLowerCase();
String dept = (ticket['my_department'] ?? '').toString().toLowerCase();

return ticketId.contains(kataKunci) ||
title.contains(kataKunci) ||
email.contains(kataKunci) ||
dept.contains(kataKunci);
}).toList();
}

// --- BAHAGIAN C: MENYUSUN DATA BERDASARKAN DROPDOWN SORT (SORTING) ---
if (_sortBy == 'Latest') {
// Susun dari tarikh baharu ke lama
hasilTapisan.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
} else if (_sortBy == 'Oldest') {
// Susun dari tarikh lama ke baharu
hasilTapisan.sort((a, b) => (a['created_at'] ?? '').toString().compareTo((b['created_at'] ?? '').toString()));
} else if (_sortBy == 'Priority') {
// Susun mengikut tahap kritikal: High -> Medium -> Low
Map<String, int> priorityWeight = {'high': 3, 'medium': 2, 'low': 1};
hasilTapisan.sort((a, b) {
int weightA = priorityWeight[(a['priority'] ?? 'medium').toString().toLowerCase()] ?? 2;
int weightB = priorityWeight[(b['priority'] ?? 'medium').toString().toLowerCase()] ?? 2;
return weightB.compareTo(weightA);
});
}

setState(() {
_displayedTickets = hasilTapisan;
});
}

Color _getStatusColor(String status) {
switch (status.toLowerCase()) {
case 'closed':
return const Color(0xFF2E9E52);
case 'in_progress':
return const Color(0xFFC9A227);
default:
return const Color(0xFF2F5FA3);
}
}

Color _getStatusBg(String status) {
switch (status.toLowerCase()) {
case 'closed':
return const Color(0xFFEAF7EE);
case 'in_progress':
return const Color(0xFFFFF8E6);
default:
return const Color(0xFFEAF1FB);
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.pageBackground,
drawer:  PortalNavDrawer(
departmentLabel: '$_namaJabatanStaffLive · Staff',
currentRoute: '/staff/tickets',
items: _staffNavItems,
staffName: (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['full_name'] ??
(ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['name'] ??
"STAFF", // Auto-fallback jikalau arguments kosong!
role: 'Staff',
),
appBar: AppBar(
backgroundColor: Colors.white,
elevation: 0,
iconTheme: const IconThemeData(color: AppColors.navy),
title: const Text('All Tickets',
style: TextStyle(color: AppColors.navy, fontSize: 14, fontWeight: FontWeight.w700)),
),
body: SafeArea(
child: _isLoading
? const Center(child: CircularProgressIndicator())
: ListView(
padding: const EdgeInsets.all(16),
children: [
// Bahagian Suis Penapis Status Tab (ChoiceChips)
SizedBox(
height: 34,
child: ListView(
scrollDirection: Axis.horizontal,
children: List.generate(_tabs.length, (i) {
final active = i == _tab;
return Padding(
padding: const EdgeInsets.only(right: 8),
child: ChoiceChip(
label: Text(_tabs[i], style: const TextStyle(fontSize: 11.5)),
selected: active,
selectedColor: AppColors.navy,
backgroundColor: Colors.white,
labelStyle: TextStyle(color: active ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
onSelected: (_) {
setState(() {
_tab = i;
_prosesTapisDanSusunData(); // Laksanakan tapisan semula setiap kali tukar tab
});
},
),
);
}),
),
),
const SizedBox(height: 14),

// GANTIKAN SEARCHFILTERBAR STATIK KEPADA BAR CARIAN & SORT DROPDOWN
Row(
children: [
// Kotak Teks Carian Aktif (70% Ruang Lebar)
Expanded(
flex: 3,
child: Container(
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(8),
border: Border.all(color: AppColors.border),
),
child: TextField(
controller: _searchController,
style: const TextStyle(fontSize: 13),
decoration: const InputDecoration(
hintText: 'Search ID, title or email',
hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textMuted),
border: InputBorder.none,
contentPadding: EdgeInsets.symmetric(vertical: 12),
),
),
),
),
const SizedBox(width: 10),

// Kotak Dropdown Mengurus Susunan
Expanded(
flex: 2,
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 10),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(8),
border: Border.all(color: AppColors.border),
),
child: DropdownButtonHideUnderline(
child: DropdownButton<String>(
value: _sortBy,
icon: const Icon(Icons.sort, size: 16, color: AppColors.navy),
style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
isExpanded: true,
items: <String>['Latest', 'Oldest', 'Priority'].map((String value) {
return DropdownMenuItem<String>(
value: value,
child: Text(value),
);
}).toList(),
onChanged: (String? newValue) {
if (newValue != null) {
setState(() {_sortBy = newValue;_prosesTapisDanSusunData();
 });
}},),),),),],),
const SizedBox(height: 14),
// Memaparkan info jumlah rekod dikira dinamik
Text('Showing ${_displayedTickets.length} of ${_allTickets.length} tickets',style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),const SizedBox(height: 10),
if (_displayedTickets.isEmpty)Padding(padding: const EdgeInsets.symmetric(vertical: 40),child: Center(child: Text('No matching tickets found.',style: const TextStyle(color: AppColors.textMuted, fontSize: 13),),),),

// === PERULANGAN KAD TIKET DINAMIK (sorting) ===
..._displayedTickets.map((ticket) {
  String currentStatus = ticket['status'] ?? 'open';

  String staffName = ticket['remarks'] ?? 'Unassigned';
  if (staffName.isEmpty) staffName = 'Unassigned';

return Padding(
padding: const EdgeInsets.only(bottom: 12.0),
child: TicketCard(
ticketId: ticket['ticket_id'] ?? 'No ID',
title: "${ticket['title'] ?? 'No Title'} — $staffName",
submittedBy: ticket['submitter_email'] ?? 'testing',
department: ticket['my_department'] ?? 'No Department',
category: ticket['created_at'] ?? 'No Date',
priority: ticket['priority'] ?? 'Medium',
status: currentStatus.toUpperCase().replaceAll('_', ' '),
statusColor: _getStatusColor(currentStatus),
statusBg: _getStatusBg(currentStatus),
onView: () {Navigator.pushNamed(context,'/tickets/workspace',
arguments: ticket,);},),);}),],),),);}}