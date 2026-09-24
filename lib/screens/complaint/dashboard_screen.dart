import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../main.dart';

/// Interface 9: Dashboard screen — "Quick Actions" + "Recent Activity".
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Tempat menyimpan senarai aduan daripada database unicomplaint
  List<dynamic> _senaraiAduanSaya = [];
  bool _isLoading = true;

  List<String> _readUserNotificationIdsList = [];


  @override
  void initState() {
    super.initState();
    _tarikDataAduanDashboard(); // Auto-panggil API apabila dashboard dibuka
  }

  // Fungsi memanggil API Laragon
  Future<void> _tarikDataAduanDashboard() async {
    if (currentLoggedInUserEmail == null || currentLoggedInUserEmail!.isEmpty) {
      print("Amaran: Tiada emel aktif di dalam session main.dart!");
      return;
    }

    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';

    // SUNTIKAN UTAMA: Memastikan emel dihantar bersih tanpa sisa cache anda!
    final url = Uri.parse('http://$domain/helpdesk_api/get_my_complaints.php?email=${currentLoggedInUserEmail!.trim()}');

    try {
      final respon = await http.get(url);

      if (respon.statusCode == 200) {
        final List<dynamic> dataDiterima = json.decode(respon.body);
        setState(() {
          _senaraiAduanSaya = dataDiterima;
          _isLoading = false;
        });
      } else {
        print("Gagal muat data dashboard. Status: ${respon.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Ralat sambungan ke Laragon: $e");
      setState(() => _isLoading = false);
    }
  }



  // Fungsi pembantu untuk menentukan warna tag status enum daripada database
  Color _dapatkanWarnaStatus(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return const Color(0xFF2E9E52);
      case 'in_progress':
        return const Color(0xFFC9A227);
      case 'open':
      default:
        return const Color(0xFF2F5FA3); // Warna biru untuk open/new ticket
    }
  }

  Color _dapatkanBgStatus(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return const Color(0xFFEAF7EE);
      case 'in_progress':
        return const Color(0xFFFFF8E6);
      case 'open':
      default:
        return const Color(0xFFEAF1FB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: Stack(
    children: [
    PortalTopBar(
    title: 'UNIKL RCMP',
    subtitle: 'Help Desk Dashboard',
    ),

    // button notifications
    Positioned(
    top: 55,
    right: 64,
    child: PopupMenuButton<void>(
    icon: Stack(
    children: [
    const Icon(Icons.notifications_none_rounded, color: AppColors.navy, size: 24),
    Positioned(
    right: 0, top: 0,
    child: Container(
    padding: const EdgeInsets.all(2),
    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
    child: Text(
    _senaraiAduanSaya.length.toString(), // Auto-mengira bilangan aduan aktif real-time anda!
    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
    textAlign: TextAlign.center,
    ),
    ),
    )
    ],
    ),
    offset: const Offset(0, 42),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 5,
    color: Colors.white,
    itemBuilder: (BuildContext context) {
    return [
    PopupMenuItem<void>(
    enabled: false,
    child: StatefulBuilder(
    builder: (BuildContext context, StateSetter setMenuState) {
    List<dynamic> senaraiNotifUserLiveDB = _senaraiAduanSaya;

    return SizedBox(
    width: 320,
    child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    const Text('Notifications', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.navy)),
    Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: const Color(0xFFEAF1FB), borderRadius: BorderRadius.circular(12)),
    child: Text('${senaraiNotifUserLiveDB.length} active', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.navy)),
    ),
    ],
    ),
    const Divider(height: 18, color: AppColors.border),

    senaraiNotifUserLiveDB.isEmpty
    ? const Center(
    child: Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Column(
    children: [
    Icon(Icons.notifications_off_outlined, size: 24, color: Colors.grey),
    SizedBox(height: 6),
    Text('No recent updates found.', style: TextStyle(fontSize: 11, color: Colors.grey)),
    ],
    ),
    ),
    )
        : ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 280),
    child: ListView.separated(
    shrinkWrap: true,
    physics: const ClampingScrollPhysics(),
    itemCount: senaraiNotifUserLiveDB.length,
    separatorBuilder: (context, index) => const SizedBox(height: 8),
    itemBuilder: (context, index) {
    final aduan = senaraiNotifUserLiveDB[index];
    String ticketIdReal = (aduan['ticket_id'] ?? 'No ID').toString();
    String statusLabelReal = (aduan['status'] ?? 'open').toString().toLowerCase().trim();

    String statusDipaparTeks = statusLabelReal == 'in_progress' ? 'In Progress' : (statusLabelReal == 'closed' ? 'Closed' : 'Open');
    String ikonStatusEmoji = statusLabelReal == 'in_progress' ? '⏳' : (statusLabelReal == 'closed' ? '✅' : '📩');
    bool adakahTiketIniBreachedSlaLive = statusLabelReal.contains('breach');

    return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () async {
    Navigator.pop(context); // Auto-tutup popup menu loceng!
    Navigator.pushNamed(context, '/tickets/user-detail', arguments: aduan);
    },
    child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
    color: const Color(0xFFF3F7FC),
    borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    CircleAvatar(
    radius: 16,
    backgroundColor: const Color(0xFF2E9E52),
    child: const Text('S', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    ),
    const SizedBox(width: 10),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Expanded(
    child: RichText(
    overflow: TextOverflow.ellipsis,
    text: TextSpan(
    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontFamily: 'PlusJakartaSans'),
    children: [
    const TextSpan(text: 'Staff ', style: TextStyle(fontWeight: FontWeight.bold)),
    const TextSpan(text: 'updated ', style: TextStyle(color: Colors.black54)),
    TextSpan(text: ticketIdReal, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
    ],
    ),
    ),
    ),
    ],
    ),
    const SizedBox(height: 3),
    Text('$ikonStatusEmoji Ticket marked as $statusDipaparTeks', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),

    const SizedBox(height: 4),
    Text('${aduan['my_department'] ?? "IT Dept"} · ${aduan['created_at'] ?? "Just Now"}', style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
    ],
    ),
    )
    ],
    ),
    ),
    );
    },
    ),
    ),
    ],
    ),
    );
    },
    ),
    )
    ];
    },
    ),
    ),
// 💎 TIER 2: BUTANG PROFILE AVATAR (BELAH KANAN REKOD ASAL ANDA)
    Positioned(
    top: 55,
    right: 16,
    child: PopupMenuButton(
    icon: CircleAvatar(
    radius: 16,
    backgroundColor: AppColors.navy.withOpacity(0.1),
    child: const Icon(Icons.person_outline, size: 18, color: AppColors.navy),
    ),
    offset: const Offset(0, 40),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onSelected: (dynamic value) {
    if (value == 'logout') {
    Navigator.pushNamedAndRemoveUntil(context, '/helpdesk_home_screen', (route) => false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out successfully.')));
    }
    },
      itemBuilder: (BuildContext context) {
        // get NAMA REAL-TIME: Ambil nama submitter dari rekod aduan pertama database jika ada,
        // jika masih loading/kosong, kita letak fallback 'Loading Profile...'
        String namaUserTulenLive = _senaraiAduanSaya.isNotEmpty
            ? (_senaraiAduanSaya[0]['submitter_name'] ?? 'User Complainant')
            : 'User Complainant';

        return [
          // PAPARAN MAKLUMAT USER
          PopupMenuItem<dynamic>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaUserTulenLive.toUpperCase(), // Auto-huruf besar
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentLoggedInUserEmail ?? 'user@gmail.com', // apply EMAL LIVE SESSION JABATAN!
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: AppColors.border, height: 1),
              ],
            ),
          ),
    const PopupMenuItem(
    value: 'logout',
    child: Row(
    children: [
    Icon(Icons.logout_outlined, size: 16, color: Colors.redAccent),
    SizedBox(width: 10),
    Text('Log Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent)),
    ],
    ),
    ),
    ];
    },
    ),
    ),
    ],
    ),
    ),



    body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 480;
                      final cards = [
                        _QuickActionCard(
                          icon: Icons.add_box_outlined,
                          title: 'Submit Complaint',
                          subtitle: 'Report a new issue',
                          onTap: () => Navigator.pushNamed(context, '/complaint/fill'),
                        ),
                        _QuickActionCard(
                          icon: Icons.list_alt_outlined,
                          title: 'My Submissions',
                          subtitle: 'View & track all submissions',
                          onTap: () => Navigator.pushNamed(context, '/my-submissions'),
                        ),
                      ];
                      return isNarrow
                          ? Column(
                        children: [
                          cards[0],
                          const SizedBox(height: 12),
                          cards[1],
                        ],
                      )
                          : Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Activity',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/my-submissions'),
                        child: const Text('View all',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // =========================================================================
                  // LOOPING RECENT ACTIVITY
                  // Kita balut parsing substring dengan try-catch agar senarai database terkeluar!
                  // =========================================================================
                  if (_isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_senaraiAduanSaya.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No recent complaints found.', style: TextStyle(color: AppColors.textSecondary))),
                    )
                  else
                  // Menjana baris aktiviti secara automatik (looping)
                    ..._senaraiAduanSaya.map((aduan) {
                      String currentStatus = aduan['status'] ?? 'open';
                      String tarikhMentah = (aduan['created_at'] ?? '').toString().trim();
                      String tarikhDipapar = 'No Date';

                      //  KUNCI FAIL-SAFE: Memastikan data substring terselamat dari RangeError
                      try {
                        if (tarikhMentah.isNotEmpty && tarikhMentah.length >= 10) {
                          String ymd = tarikhMentah.substring(0, 10);
                          List<String> susunan = ymd.split('-');
                          if (susunan.length == 3) {
                            tarikhDipapar = "${susunan[2]}-${susunan[1]}-${susunan[0]}";
                          }
                        } else if (tarikhMentah.isNotEmpty) {
                          tarikhDipapar = tarikhMentah; // Fallback jika teks pendek
                        }
                      } catch (e) {
                        tarikhDipapar = 'Just Now'; // Jika parsing gagal, paksa paparkan Just Now
                      }

                      return _ActivityRow(
                        reference: aduan['ticket_id'] ?? 'No Reference',
                        title: aduan['title'] ?? 'No Description Provided',
                        department: tarikhDipapar,
                        statusLabel: currentStatus == 'open' ? 'Open' : (currentStatus == 'in_progress' ? 'In Progress' : 'Closed'),
                        statusColor: _dapatkanWarnaStatus(currentStatus),
                        statusBg: _dapatkanBgStatus(currentStatus),
                        onView: () {
                          Navigator.pushNamed(
                            context,
                            '/tickets/user-detail',
                            arguments: aduan,
                          );
                        },
                      );
                    }),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.gold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
final String reference;
final String title;
final String department;
final String statusLabel;
final Color statusColor;
final Color statusBg;
final VoidCallback onView;

const _ActivityRow({
required this.reference,
required this.title,
required this.department,
required this.statusLabel,
required this.statusColor,
required this.statusBg,
required this.onView,
});

@override
Widget build(BuildContext context) {
return Container(
margin: const EdgeInsets.only(top: 10),
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(10),
border: Border.all(color: AppColors.border),
),
child: Row(
children: [
const StatusTag(label: 'Complaint'),
const SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(reference, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
const SizedBox(height: 2),Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color:
AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
const SizedBox(height: 2),
Text(department, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
],
),
),
const SizedBox(width: 10),
Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
decoration: BoxDecoration(
color: statusBg,
borderRadius: BorderRadius.circular(6),
),
  child: Text(
    statusLabel,
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
  ),
),
  const SizedBox(width: 8),
  IconButton(
    icon: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
    onPressed: onView,
  ),
],
),
);
}
}