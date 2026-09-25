import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../main.dart';
import '../../services/notification_service.dart';
import 'dart:async';

const _staffNavItems = [
  AdminNavItem(Icons.dashboard_outlined, 'Dashboard', '/staff/dashboard'),
  AdminNavItem(
      Icons.confirmation_number_outlined, 'All Tickets', '/staff/tickets'),
];

/// "Information Technology" — staff dashboard for a department member handling assigned tickets.
class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _tab = 0;
  final _tabs = const ['My Tasks', 'High Priority', 'SLA Breached'];

// Pengurus data dinamik dari database unicomplaint
  Map<String, dynamic> _stats = {
    "open": "0",
    "in_progress": "0",
    "closed": "0",
    "unresolved": "0"
  };
  List<dynamic> _openTickets = [];
  List<dynamic> _displayedTickets = [];

//MENYIMPAN DATA CARTA DARI DATABASE
  List<dynamic> _chartData = [];

  List<dynamic> _rawAllTicketsFromDB = [];

  String _namaJabatanStaffLive = "Loading Department...";

  bool _isLoading = true;

  String _namaStaffLive = "";

  List<String> _readTicketIdsListLive = [];

  Timer? _notifPollTimer; // PEMASA POLLING !
  String _lastKnownTopTicketId = ""; // Track tiket terakhir

  // Warna standard yang kita tetapkan untuk 3 pecahan carta donat
  final List<Color> _chartColors = [
    const Color(0xFF7C3AED),
    const Color(0xFF2F5FA3),
    const Color(0xFF2E9E52)
  ];

  @override
  void initState() {
    super.initState();
    _ambilDataStaffDashboard();

    // AKTIFKAN POLLING SETIAP 30 SAAT !
    _notifPollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _ambilDataStaffDashboard(isBackground: true);
    });
  }

  @override
  void dispose() {
    _notifPollTimer?.cancel(); // kill timer bila keluar
    super.dispose();
  }

// Fungsi menarik maklumat statistik & aduan masuk dari Laragon API
  Future<void> _ambilDataStaffDashboard({bool isBackground = false}) async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_staff_dashboard.php?email=$currentLoggedInUserEmail');

    try {
      final respon = await http.get(url);

      if (respon.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(respon.body);
        setState(() {
          _namaJabatanStaffLive =
              data['department_label'] ?? 'Staff Support Workspace';
          _stats = {
            "open": (data['stats']['open'] ?? 0).toString(),
            "in_progress": (data['stats']['in_progress'] ?? 0).toString(),
            "closed": (data['stats']['closed'] ?? 0).toString(),
            "unresolved": (data['stats']['unresolved'] ?? 0).toString(),
          };
          _namaStaffLive = (data['staff_name'] ?? '').toString().trim();

          List<dynamic> freshTickets = data['incoming_tickets'] ?? [];

          // NOTIFIKASI PHONE DIBUANG!

          _openTickets = freshTickets;
          _chartData = data['top_departments'] ?? []; // live data
          _rawAllTicketsFromDB = freshTickets;
          _prosesTapisTiketDashboard();
          _isLoading = false;
        });
      } else {
        if (!isBackground) {
          print(
              "Gagal muat data staff dashboard. Status: ${respon.statusCode}");
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (!isBackground) {
        print("Ralat sambungan Laragon: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'closed':
        return const Color(0xFF2E9E52); //  Teks hijau pekat untuk Closed!
      case 'in_progress':
        return const Color(0xFFC9A227); // Teks emas amaran
      default:
        return const Color(0xFF2F5FA3); // Teks biru korporat untuk Open
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase().trim()) {
      case 'closed':
        return const Color(0xFFEAF7EE); // Hijau lembut untuk Closed!
      case 'in_progress':
        return const Color(0xFFFFF8E6); // Kuning amaran lembut
      default:
        return const Color(0xFFEAF1FB); // Biru lembut untuk Open
    }
  }

  void _prosesTapisTiketDashboard() {
    List<dynamic> hasilTapis = [];
    String currentStaffName = _namaStaffLive.toLowerCase().trim();

    if (currentStaffName.isEmpty || _rawAllTicketsFromDB.isEmpty) {
      setState(() {
        _displayedTickets = [];
      });
      return;
    }

    if (_tab == 0) {
      // TAB 0: MY TASKS (Only my assigned cases)
      hasilTapis = _rawAllTicketsFromDB.where((ticket) {
        String ticketRemarks =
            (ticket['remarks'] ?? '').toString().toLowerCase().trim();
        return ticketRemarks == currentStaffName;
      }).toList();
    } else if (_tab == 1) {
      // TAB 1: HIGH PRIORITY (My cases that are HIGH priority)
      hasilTapis = _rawAllTicketsFromDB.where((ticket) {
        String ticketRemarks =
            (ticket['remarks'] ?? '').toString().toLowerCase().trim();
        String priority =
            (ticket['priority'] ?? '').toString().toLowerCase().trim();
        return ticketRemarks == currentStaffName && priority == 'high';
      }).toList();
    } else if (_tab == 2) {
      // TAB 2: SLA BREACHED (My cases that exceeded 8 working hours)
      hasilTapis = _rawAllTicketsFromDB.where((ticket) {
        String ticketRemarks =
            (ticket['remarks'] ?? '').toString().toLowerCase().trim();
        if (ticketRemarks != currentStaffName) return false;

        String dateStr = ticket['created_at'] ?? '';
        if (dateStr.isEmpty) return false;

        DateTime createdTime = DateTime.parse(dateStr);
        String status = (ticket['status'] ?? 'open').toString().toLowerCase();
        DateTime endTime = status == 'open'
            ? DateTime.now()
            : DateTime.parse(ticket['updated_at'] ?? dateStr);

        int minutesUsed = _kiraMinitBekerjaSLA(createdTime, endTime);
        return minutesUsed > 480; // 8 Hours limit
      }).toList();
    }

    setState(() {
      _displayedTickets = hasilTapis;
    });
  }

  int _kiraMinitBekerjaSLA(DateTime start, DateTime end) {
    int minutes = 0;
    DateTime current = start;
    if (current.hour >= 17) {
      current = DateTime(current.year, current.month, current.day + 1, 8, 0);
    } else if (current.hour < 8) {
      current = DateTime(current.year, current.month, current.day, 8, 0);
    }
    while (current.isBefore(end)) {
      if (current.weekday <= 5 && current.hour >= 8 && current.hour < 17) {
        minutes++;
      }
      current = current.add(const Duration(minutes: 1));
    }
    return minutes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      bottomNavigationBar: PortalBottomNav(
        items: _staffNavItems,
        currentRoute: '/staff/dashboard',
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy),
        title: Text(
          _namaJabatanStaffLive,
          style: const TextStyle(
              color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<void>(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: AppColors.navy, size: 24),
                // 🔴 Merah: Mengira jumlah baki tiket AKTIF milik saya dari database complaints
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    constraints:
                        const BoxConstraints(minWidth: 12, minHeight: 12),
                    child: Text(
                        _openTickets
                            .where((t) =>
                                (t['remarks'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .trim() ==
                                _namaStaffLive.toLowerCase().trim())
                            .length
                            .toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                )
              ],
            ),
            offset: const Offset(0, 45),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 5,
            color: Colors.white,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<void>(
                  enabled: false,
                  child: StatefulBuilder(builder:
                      (BuildContext context, StateSetter setMenuState) {
                    // Takungan status index sub-tab (0 = All, 1 = Assigned to Me, 2 = Deadlines)
                    // menggunakan local parameter premium context hash agar tersimpan selamat !
                    _stats['notif_tab_active_index'] ??= 1;
                    int currentNotificationTab =
                        _stats['notif_tab_active_index'];

                    // amik DATA REAL-TIME JABATAN: Membaca terus dari takungan array _openTickets data !
                    List<dynamic> senaraiAduanTiketSemasaDB = _openTickets;

                    //  FORMULA TAPISAN 3 PENJURU
                    List<dynamic> senaraiNotifikasiYangDahDitapis = [];

                    if (currentNotificationTab == 0) {
                      // 🟢 TAB ALL: Memaparkan semua aduan tiket jabatan yang ditarik dari database Laragon!
                      senaraiNotifikasiYangDahDitapis =
                          senaraiAduanTiketSemasaDB;
                    } else if (currentNotificationTab == 1) {
                      // 🟢 TAB ASSIGNED TO ME: Hanya menapis aduan tiket Hak Milik yang sedang login!
                      senaraiNotifikasiYangDahDitapis =
                          senaraiAduanTiketSemasaDB.where((tkt) {
                        String ticketRemarks = (tkt['remarks'] ?? '')
                            .toString()
                            .toLowerCase()
                            .trim();
                        return ticketRemarks ==
                            _namaStaffLive.toLowerCase().trim();
                      }).toList();
                    } else if (currentNotificationTab == 2) {
                      // 🟢 TAB DEADLINES: Menyuntik formula _kiraMinitBekerjaSLA asli anda untuk menapis tiket breached KPI 8 jam (>480 minit)!
                      senaraiNotifikasiYangDahDitapis =
                          senaraiAduanTiketSemasaDB.where((tkt) {
                        String dateStr = tkt['created_at'] ?? '';
                        if (dateStr.isEmpty) return false;
                        DateTime createdTime = DateTime.parse(dateStr);
                        String status =
                            (tkt['status'] ?? 'open').toString().toLowerCase();
                        DateTime endTime = status == 'open'
                            ? DateTime.now()
                            : DateTime.parse(tkt['updated_at'] ?? dateStr);

                        int minutesUsed =
                            _kiraMinitBekerjaSLA(createdTime, endTime);
                        return minutesUsed > 480;
                      }).toList();
                    }

                    // INLINE WIDGET METHOD TAB DEKORASI
                    Widget buildLocalNotificationTabButton(
                        String label, bool isBtnActive, VoidCallback onBtnTap) {
                      return InkWell(
                        onTap: onBtnTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isBtnActive
                                ? const Color(0xFFEAF1FB)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: isBtnActive
                                    ? FontWeight.w900
                                    : FontWeight.w500,
                                color: isBtnActive
                                    ? const Color(0xFF2F5FA3)
                                    : Colors.grey.shade600),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      width: 320,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Notifications',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.navy)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFEAF1FB),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                    '${senaraiNotifikasiYangDahDitapis.length} active',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.navy)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // TIER PANEL MINI SUB-TAB NOTIFIKASI
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              buildLocalNotificationTabButton(
                                  'All',
                                  currentNotificationTab == 0,
                                  () => setMenuState(() =>
                                      _stats['notif_tab_active_index'] = 0)),
                              buildLocalNotificationTabButton(
                                  'Assigned to Me',
                                  currentNotificationTab == 1,
                                  () => setMenuState(() =>
                                      _stats['notif_tab_active_index'] = 1)),
                              buildLocalNotificationTabButton(
                                  'Deadlines',
                                  currentNotificationTab == 2,
                                  () => setMenuState(() =>
                                      _stats['notif_tab_active_index'] = 2)),
                            ],
                          ),
                          const Divider(height: 16, color: AppColors.border),

                          // TIER ISI KANDUNGAN LOOPING DATA REAL-TIME DIKIRA AMAN DARI MYSQL COMPLAINTS
                          senaraiNotifikasiYangDahDitapis.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 24),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              shape: BoxShape.circle),
                                          child: Icon(
                                              Icons.notifications_off_outlined,
                                              size: 26,
                                              color: Colors.grey.shade300),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text('No notifications',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary)),
                                        const SizedBox(height: 2),
                                        const Text("You're all caught up!",
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                )
                              : ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 280),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    itemCount:
                                        senaraiNotifikasiYangDahDitapis.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final tiket =
                                          senaraiNotifikasiYangDahDitapis[
                                              index];
// Semak baki waktu bekerja SLA tiket ini secara real-time!
                                      String dateStr =
                                          tiket['created_at'] ?? '';
                                      DateTime createdTime =
                                          DateTime.parse(dateStr);
                                      String currentStatus =
                                          (tiket['status'] ?? 'open')
                                              .toString()
                                              .toLowerCase();
                                      DateTime endTime = currentStatus == 'open'
                                          ? DateTime.now()
                                          : DateTime.parse(
                                              tiket['updated_at'] ?? dateStr);
                                      bool adakahTiketIniBreachedSlaLive =
                                          _kiraMinitBekerjaSLA(
                                                  createdTime, endTime) >
                                              480;
// PERISAI INTERAKTIF: Klik untuk terus ke workspace tiket!
                                      return InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () async {
// Auto-tutup popup menu loceng terlebih dahulu
                                          Navigator.pop(context);
// Terus membawa petugas masuk ke skrin workspace detail tiket!
                                          final muatSemulaDashboardStaff =
                                              await Navigator.pushNamed(
                                                  context, '/tickets/workspace',
                                                  arguments: tiket);
                                          if (muatSemulaDashboardStaff ==
                                              true) {
                                            _ambilDataStaffDashboard();
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: adakahTiketIniBreachedSlaLive
                                                ? const Color(0xFFFDF2F2)
                                                : const Color(0xFFF3F7FC),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                radius: 15,
                                                backgroundColor:
                                                    adakahTiketIniBreachedSlaLive
                                                        ? const Color(
                                                            0xFFD64545)
                                                        : const Color(
                                                            0xFF3B82F6),
                                                child: Text(
                                                    adakahTiketIniBreachedSlaLive
                                                        ? '⚠️'
                                                        : 'NT',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                            child: Text(
                                                                tiket['title'] ??
                                                                    'Complaint Ticket',
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: AppColors
                                                                        .textPrimary),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis)),
                                                        Text(
                                                            adakahTiketIniBreachedSlaLive
                                                                ? 'BREACHED •'
                                                                : '',
                                                            style: TextStyle(
                                                                fontSize: 8.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: adakahTiketIniBreachedSlaLive
                                                                    ? const Color(
                                                                        0xFFD64545)
                                                                    : Colors
                                                                        .blue)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                        tiket['ticket_id'] ??
                                                            '',
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .textSecondary)),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                        adakahTiketIniBreachedSlaLive
                                                            ? 'SLA clock breached! Fix action required immediately!'
                                                            : 'Ticket status — ${tiket['status']}',
                                                        style: const TextStyle(
                                                            fontSize: 10.5,
                                                            color: AppColors
                                                                .textMuted)),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                        '${tiket['my_department'] ?? "IT Dept"} · ${tiket['created_at']}',
                                                        style: const TextStyle(
                                                            fontSize: 9,
                                                            color:
                                                                Colors.grey)),
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
                  }),
                )
              ];
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () =>
                    _ambilDataStaffDashboard(), // Tarik data baru apabila skrin di-pull down
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(
                      height: 92,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
// Nilai kad di bawah kini membaca dari database Laragon secara langsung
                          StatMiniCard(
                              value: _stats['open']!,
                              label: 'Open Tickets',
                              icon: Icons.mark_email_unread_outlined,
                              color: const Color(0xFF2F5FA3)),
                          const SizedBox(width: 10),
                          StatMiniCard(
                              value: _stats['in_progress']!,
                              label: 'In Progress',
                              icon: Icons.autorenew,
                              color: const Color(0xFFC9A227)),
                          const SizedBox(width: 10),
                          StatMiniCard(
                              value: _stats['closed']!,
                              label: 'Recently Closed',
                              icon: Icons.check_circle_outline,
                              color: const Color(0xFF2E9E52)),
                          const SizedBox(width: 10),
                          StatMiniCard(
                              value: _stats['unresolved']!,
                              label: 'Unresolved',
                              icon: Icons.error_outline,
                              color: const Color(0xFFD64545)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Top Department Filing Complaints',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                          ),
                          const SizedBox(height: 12),
// JIKA DATA CARTA MASIH KOSONG DI DATABASE
                          _chartData.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                      'No complaint data available for chart analysis.',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted)),
                                )
                              : Column(
                                  children: [
                                    //  JANA KANDUNGAN SLICES SECARA LIVE BERDASARKAN HASIL SQL
                                    SimpleDonutChart(
                                      slices: _chartData
                                          .map<MapEntry<String, double>>(
                                              (item) {
                                        String namaDept =
                                            (item['name'] ?? 'General')
                                                .toString();
                                        double jumlahDouble = double.parse(
                                            (item['total'] ?? 0).toString());
                                        return MapEntry<String, double>(
                                            namaDept, jumlahDouble);
                                      }).toList(),
                                      colors: _chartColors
                                          .take(_chartData.length)
                                          .toList(),
                                    ),
                                    const SizedBox(height: 12),

                                    // Penunjuk warna (Legend)
                                    ChartLegend(
                                      items: List<
                                              MapEntry<String, Color>>.generate(
                                          _chartData.length, (index) {
                                        String namaDept = (_chartData[index]
                                                    ['name'] ??
                                                'General')
                                            .toString();
                                        return MapEntry<String, Color>(
                                            namaDept, _chartColors[index]);
                                      }),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================== KONTENA TAB CHOICECHIPS ====================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Barisan Pilihan Suis Tab ChoiceChips
                          SizedBox(
                            height: 34,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: List.generate(_tabs.length, (i) {
                                final active = i == _tab;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(_tabs[i],
                                        style: const TextStyle(fontSize: 11.5)),
                                    selected: active,
                                    selectedColor: AppColors.navy,
                                    backgroundColor: Colors.white,
                                    labelStyle: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w600),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: const BorderSide(
                                            color: AppColors.border)),
                                    onSelected: (_) {
                                      setState(() {
                                        _tab = i;
                                      });
                                      _prosesTapisTiketDashboard(); // Jalankan tapisan hantaran ke dalam kad induk ini
                                    },
                                  ),
                                );
                              }),
                            ),
                          ),
                          const Divider(height: 24, color: AppColors.border),

                          // Tajuk Kecil Maklumat Tab Terpilih
                          Text(
                            "Overview: ${_tabs[_tab]} (${_displayedTickets.length} items)",
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 10),

                          // Keadaan jika tiada data dalam tab yang ditapis
                          _displayedTickets.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                      child: Text(
                                          'No active records under this profile track.',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted))),
                                )
                              : Column(
                                  children: _displayedTickets.map((ticket) {
                                    String idTiket =
                                        ticket['ticket_id'] ?? 'No ID';
                                    String katName = ticket['category'] ??
                                        ticket['title'] ??
                                        'General';
                                    String deptName =
                                        ticket['my_department'] ?? 'No Dept';
                                    String rawStatus =
                                        (ticket['status'] ?? 'open')
                                            .toString()
                                            .toUpperCase()
                                            .replaceAll('_', ' ');

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.pageBackground,
                                        borderRadius: BorderRadius.circular(8),
                                        border:
                                            Border.all(color: AppColors.border),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(idTiket,
                                                  style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.navy)),
                                              Text(rawStatus,
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: _getStatusColor(
                                                          ticket['status'] ??
                                                              'open'))),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text("Category: $katName",
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textPrimary)),
                                          const SizedBox(height: 2),
                                          Text("From: $deptName",
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textSecondary)),
                                          const Divider(height: 16),

                                          // Butang Kecil untuk Terus ke Rincian Workspace
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: InkWell(
                                              onTap: () async {
                                                final muatSemula =
                                                    await Navigator.pushNamed(
                                                        context,
                                                        '/tickets/workspace',
                                                        arguments: ticket);
                                                if (muatSemula == true)
                                                  _ambilDataStaffDashboard();
                                              },
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text("View Details",
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              AppColors.navy)),
                                                  SizedBox(width: 4),
                                                  Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 12,
                                                      color: AppColors.navy),
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }
}
