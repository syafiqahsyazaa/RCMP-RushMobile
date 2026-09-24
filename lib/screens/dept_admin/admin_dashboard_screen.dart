import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../main.dart';
import '../../services/notification_service.dart';
import 'dart:async';

const _adminNavItems = [
  AdminNavItem(Icons.dashboard_outlined, 'Dashboard', '/admin/dashboard'),
  AdminNavItem(
      Icons.confirmation_number_outlined, 'All Tickets', '/admin/tickets'),
  AdminNavItem(Icons.people_outline, 'Manage Users', '/admin/users'),
  AdminNavItem(Icons.storefront_outlined, 'Manage Vendors', '/admin/vendors'),
  AdminNavItem(Icons.category_outlined, 'Categories', '/admin/categories'),
  AdminNavItem(
      Icons.bar_chart_outlined, 'Reports & Analytics', '/admin/reports'),
];

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedCardIndex = 0; // 0=All, 1=Open, 2=Closed, 3=Avg Rating
  bool _isLoading = true;

  Map<String, String> _counters = {
    "all": "0",
    "open": "0",
    "closed": "0",
    "rating": "0.0"
  };

  List<dynamic> _statusChartData = [];
  List<dynamic> _priorityChartData = [];
  List<dynamic> _closedFreqChartData = [];
  List<dynamic> _starsChartData = [];
  List<dynamic> _incomingTickets = []; // : Simpan list tiket masuk!

  Timer? _notifPollTimer; // 🕒 PEMASA POLLING !
  String _lastKnownTopTicketId = ""; // Track tiket terakhir

  @override
  void initState() {
    super.initState();
    _ambilDataAdminDashboard();

    // AKTIFKAN POLLING SETIAP 30 SAAT
    _notifPollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _ambilDataAdminDashboard(isBackground: true);
    });
  }

  @override
  void dispose() {
    _notifPollTimer?.cancel(); // Matikan pemasa bila keluar
    super.dispose();
  }

  // Tempat menyimpan nama jabatan dari database
  String _namaJabatanLive = "IT Department · Admin";
  String _namaAdminLive = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AMBIL NAMA DARI ARGUMENTS JIKA ADA SEBAGAI INITIAL DATA
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _namaAdminLive.isEmpty) {
      setState(() {
        _namaAdminLive =
            (args['full_name'] ?? args['name'] ?? "").toString().trim();
      });
    }
  }

  // =========================================================================
  // sekat data kosong PHP daripada memadamkan nama login asal !
  // =========================================================================
  Future<void> _ambilDataAdminDashboard({bool isBackground = false}) async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_admin_dashboard.php?email=$currentLoggedInUserEmail');

    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(respon.body);

        // get data arguments login asal di context sebagai backup
        final Map<String, dynamic>? argsBackup =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        String namaAsalLoginArguments =
            (argsBackup?['full_name'] ?? argsBackup?['name'] ?? "")
                .toString()
                .trim();

        setState(() {
          _namaJabatanLive =
              data['department_label'] ?? 'IT Department · Admin';

          // Jika PHP memulangkan data admin_name kosong, kita paksa enjin guna nama dari arguments login asal!
          String namaDariPhp = (data['admin_name'] ?? '').toString().trim();
          if (namaDariPhp.isNotEmpty && namaDariPhp != 'null') {
            _namaAdminLive = namaDariPhp;
          } else if (namaAsalLoginArguments.isNotEmpty) {
            _namaAdminLive = namaAsalLoginArguments;
          } else {
            _namaAdminLive = "Admin UniKL"; // Fallback mutlak terakhir
          }

          _counters = Map<String, String>.from(data['counters']);
          _statusChartData = data['charts']['status'] ?? [];
          _priorityChartData = data['charts']['priority'] ?? [];
          _closedFreqChartData = data['charts']['closed_frequency'] ?? [];
          _starsChartData = data['charts']['stars'] ?? [];

          List<dynamic> freshTickets = data['incoming_tickets'] ?? [];

          // NOTIFIKASI PHONE DIBUANG!
          // logic bell

          _incomingTickets = freshTickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!isBackground) {
        print("Ralat memuat data admin dashboard: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  String _getChartTitle() {
    if (_selectedCardIndex == 0) return 'All Tickets Status Overview';
    if (_selectedCardIndex == 1) return 'Open Tickets Priority Breakdown';
    if (_selectedCardIndex == 2)
      return 'Top Closed Complaints Frequency by Category';
    return 'Customer Feedback Rating Distribution';
  }

  String _getChartSubtitle() {
    if (_selectedCardIndex == 0)
      return 'Real-time volume overview segmented by complaint status tracks.';
    if (_selectedCardIndex == 1)
      return 'Urgency assessment metrics for active open complaints.';
    if (_selectedCardIndex == 2)
      return 'Category tracks with the highest number of fully resolved tickets.';
    return 'Total counts recorded for each feedback score star packet.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      drawer: PortalNavDrawer(
        departmentLabel: '$_namaJabatanLive · Admin',
        currentRoute: '/admin/dashboard',
        items: _adminNavItems,
        staffName: _namaAdminLive.isNotEmpty ? _namaAdminLive : "Admin UniKL",
        role: 'Admin',
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_namaJabatanLive,
                style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const Text('Dashboard Overview',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
        actions: [
          PopupMenuButton<void>(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: AppColors.navy, size: 24),
                if (_incomingTickets.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(_incomingTickets.length.toString(),
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
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            color: Colors.white,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<void>(
                  enabled: false,
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setMenuState) {
                      //  AKTIF TAB NOTIFIKASI ADMIN
                      _counters['notif_tab_active_index'] ??= '0';
                      int currentTab =
                          int.parse(_counters['notif_tab_active_index']!);

                      // Formula tapisan
                      List<dynamic> filteredNotifs = [];
                      if (currentTab == 0) {
                        filteredNotifs = _incomingTickets;
                      } else if (currentTab == 1) {
                        filteredNotifs = _incomingTickets
                            .where((t) =>
                                (t['remarks'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .trim() ==
                                _namaAdminLive.toLowerCase().trim())
                            .toList();
                      } else if (currentTab == 2) {
                        filteredNotifs = _incomingTickets.where((t) {
                          try {
                            DateTime createdTime =
                                DateTime.parse(t['created_at'] ?? '');
                            int mins = _kiraMinitBekerjaSLA(
                                createdTime, DateTime.now());
                            return mins > 480; // Lebih 8 jam
                          } catch (e) {
                            return false;
                          }
                        }).toList();
                      }

                      return SizedBox(
                        width: 340,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                              child: Row(
                                children: [
                                  const Text('Notifications',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.navy)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFEAF1FB),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Text(
                                        '${_incomingTickets.length} active',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF2F5FA3),
                                            fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildMiniTab(
                                    0,
                                    'All',
                                    currentTab,
                                    () => setMenuState(() =>
                                        _counters['notif_tab_active_index'] =
                                            '0')),
                                _buildMiniTab(
                                    1,
                                    'Assigned to Me',
                                    currentTab,
                                    () => setMenuState(() =>
                                        _counters['notif_tab_active_index'] =
                                            '1')),
                                _buildMiniTab(
                                    2,
                                    'Deadlines',
                                    currentTab,
                                    () => setMenuState(() =>
                                        _counters['notif_tab_active_index'] =
                                            '2')),
                              ],
                            ),
                            const Divider(height: 24),
                            if (filteredNotifs.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Text("No relevant notifications!",
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic)),
                              )
                            else
                              SizedBox(
                                height: 350,
                                child: ListView.builder(
                                  itemCount: filteredNotifs.length,
                                  itemBuilder: (context, idx) {
                                    final tkt = filteredNotifs[idx];
                                    bool isBreached = false;
                                    try {
                                      int mins = _kiraMinitBekerjaSLA(
                                          DateTime.parse(
                                              tkt['created_at'] ?? ''),
                                          DateTime.now());
                                      isBreached = mins > 480;
                                    } catch (e) {}

                                    return _buildNotifItem(tkt, isBreached);
                                  },
                                ),
                              ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ====================  4 KAD INTERAKTIF ====================
                  SizedBox(
                    height: 105,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildGlowStatCard(
                            0,
                            _counters['all']!,
                            'All Tickets',
                            Icons.confirmation_number_outlined,
                            const Color(0xFF2F5FA3)),
                        const SizedBox(width: 12),
                        _buildGlowStatCard(
                            1,
                            _counters['open']!,
                            'Open Tickets',
                            Icons.mark_email_unread_outlined,
                            const Color(0xFFD64545)),
                        const SizedBox(width: 12),
                        _buildGlowStatCard(
                            2,
                            _counters['closed']!,
                            'Closed Tickets',
                            Icons.check_circle_outline,
                            const Color(0xFF2E9E52)),
                        const SizedBox(width: 12),
                        _buildGlowStatCard(
                            3,
                            "${_counters['rating']} ",
                            'Avg Rating',
                            Icons.star_outline_rounded,
                            const Color(0xFFC9A227)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==================== BOX PUTIH CARTA DYNAMIC PREMIUM ====================
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _selectedCardIndex == 0
                                    ? const Color(0xFFEAF1FB)
                                    : _selectedCardIndex == 1
                                        ? const Color(0xFFFDF2F2)
                                        : _selectedCardIndex == 2
                                            ? const Color(0xFFEAF7EE)
                                            : const Color(0xFFFFF8E6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _selectedCardIndex == 0
                                    ? Icons.bar_chart_rounded
                                    : _selectedCardIndex == 1
                                        ? Icons.notification_important_rounded
                                        : _selectedCardIndex == 2
                                            ? Icons.pie_chart_outline_rounded
                                            : Icons.star_rounded,
                                size: 18,
                                color: _selectedCardIndex == 0
                                    ? const Color(0xFF2F5FA3)
                                    : _selectedCardIndex == 1
                                        ? const Color(0xFFD64545)
                                        : _selectedCardIndex == 2
                                            ? const Color(0xFF2E9E52)
                                            : const Color(0xFFC9A227),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_getChartTitle(),
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(_getChartSubtitle(),
                                      style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 40, color: AppColors.border),
                        if (_selectedCardIndex == 0)
                          _buildVerticalBars(_statusChartData,
                              startColor: const Color(0xFF3B82F6),
                              endColor: const Color(0xFF1D4ED8)),
                        if (_selectedCardIndex == 1)
                          _buildVerticalBars(_priorityChartData,
                              startColor: const Color(0xFFF87171),
                              endColor: const Color(0xFFDC2626)),
                        if (_selectedCardIndex == 2)
                          _buildHorizontalCardBars(_closedFreqChartData),
                        if (_selectedCardIndex == 3)
                          _buildAvgRatingSpecialSection(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // === BAHAGIAN QUICK ACCESS PANEL DI DALAM ADMIN DASHBOARD ANDA ===
                  const Text('Quick Access Panel',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),

                  _QuickLink(
                      icon: Icons.people_outline,
                      label: 'All Tickets',
                      onTap: () => Navigator
                              .pushNamed(context, '/admin/tickets', arguments: {
                            "email": ((ModalRoute.of(context)
                                            ?.settings
                                            .arguments
                                        as Map<String, dynamic>?)?['email'] ??
                                    currentLoggedInUserEmail)
                                .toString(),
                            "full_name": _namaAdminLive.isNotEmpty
                                ? _namaAdminLive
                                : "Admin UniKL",
                            "role": "Admin"
                          })),

                  _QuickLink(
                      icon: Icons.people_outline,
                      label: 'Manage Users',
                      onTap: () => Navigator
                              .pushNamed(context, '/admin/users', arguments: {
                            "email": ((ModalRoute.of(context)
                                            ?.settings
                                            .arguments
                                        as Map<String, dynamic>?)?['email'] ??
                                    currentLoggedInUserEmail)
                                .toString(),
                            "full_name": _namaAdminLive.isNotEmpty
                                ? _namaAdminLive
                                : "Admin UniKL",
                            "role": "Admin"
                          })),

                  _QuickLink(
                    icon: Icons.storefront_outlined,
                    label: 'Manage Vendors',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/admin/vendors',
                      arguments: {
                        "email": ((ModalRoute.of(context)?.settings.arguments
                                    as Map<String, dynamic>?)?['email'] ??
                                currentLoggedInUserEmail)
                            .toString(),
                        "full_name": _namaAdminLive.isNotEmpty
                            ? _namaAdminLive
                            : "Admin UniKL",
                        "role": "Admin",
                        "departmentLabel": '$_namaJabatanLive · Admin',
                      },
                    ),
                  ),

                  _QuickLink(
                      icon: Icons.category_outlined,
                      label: 'Categories',
                      onTap: () => Navigator.pushNamed(
                              context, '/admin/categories',
                              arguments: {
                                "email":
                                    ((ModalRoute.of(context)?.settings.arguments
                                                    as Map<String, dynamic>?)?[
                                                'email'] ??
                                            currentLoggedInUserEmail)
                                        .toString(),
                                "full_name": _namaAdminLive.isNotEmpty
                                    ? _namaAdminLive
                                    : "Admin UniKL",
                                "role": "Admin"
                              })),

                  _QuickLink(
                      icon: Icons.bar_chart_outlined,
                      label: 'Reports & Analytics',
                      onTap: () => Navigator
                              .pushNamed(context, '/admin/reports', arguments: {
                            "email": ((ModalRoute.of(context)
                                            ?.settings
                                            .arguments
                                        as Map<String, dynamic>?)?['email'] ??
                                    currentLoggedInUserEmail)
                                .toString(),
                            "full_name": _namaAdminLive.isNotEmpty
                                ? _namaAdminLive
                                : "Admin UniKL",
                            "role": "Admin"
                          })),

                  const SizedBox(height: 30),
                ],
              ),
      ),
    );
  }

  // Generator Rekaan Kad Atas Bercahaya  (Glow Stat Card)
  Widget _buildGlowStatCard(
      int index, String value, String label, IconData icon, Color themeColor) {
    bool isSelected = _selectedCardIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedCardIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 145,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? themeColor : AppColors.border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: themeColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6)),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary)),
                Icon(icon,
                    size: 18, color: isSelected ? Colors.white : themeColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // RENDERING A: Carta Bar Menegak Dengan Warna Dinamik Ikut Label (Kalis Sama Warna!)
  Widget _buildVerticalBars(List<dynamic> data,
      {required Color startColor, required Color endColor}) {
    if (data.isEmpty)
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("No analytic logs track records found.",
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted))));

    int maxVal = data
        .map<int>((e) => (e['value'] ?? 0) as int)
        .reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Garis Panduan Sisi Belakang (Background Grid Lines)
            Column(
              children: List.generate(
                  4,
                  (i) => Container(
                      margin: const EdgeInsets.only(bottom: 34),
                      width: double.infinity,
                      height: 1,
                      color: AppColors.border.withOpacity(0.5))),
            ),

            // Render Carta Menegak Sebenar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((item) {
                  int count = item['value'] ?? 0;
                  double barHeight = (count / maxVal) * 110;
                  String label = (item['label'] ?? '').toString();

                  //  Tentukan pasangan warna gradien premium berdasarkan teks label!
                  List<Color> dynamicGradientColors = [
                    startColor,
                    endColor
                  ]; // Fallback default

                  // 1. Pilihan warna untuk tab STATUS (All Tickets)
                  if (label == 'Open') {
                    dynamicGradientColors = [
                      const Color(0xFF60A5FA),
                      const Color(0xFF1D4ED8)
                    ]; // Biru Premium
                  } else if (label == 'In Progress') {
                    dynamicGradientColors = [
                      const Color(0xFFFBBF24),
                      const Color(0xFFD97706)
                    ]; // Kuning/Oren Amaran
                  } else if (label == 'Closed') {
                    dynamicGradientColors = [
                      const Color(0xFF34D399),
                      const Color(0xFF047857)
                    ]; // Hijau Kejayaan
                  }

                  // 2. Pilihan warna untuk tab PRIORITY (Open Tickets)
                  else if (label == 'Low') {
                    dynamicGradientColors = [
                      const Color(0xFF93C5FD),
                      const Color(0xFF2563EB)
                    ]; // Biru Lembut
                  } else if (label == 'Medium') {
                    dynamicGradientColors = [
                      const Color(0xFFFB923C),
                      const Color(0xFFEA580C)
                    ]; // Oren
                  } else if (label == 'High') {
                    dynamicGradientColors = [
                      const Color(0xFFF87171),
                      const Color(0xFFDC2626)
                    ]; // Merah
                  }

                  return Column(
                    children: [
                      Text("$count",
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 42,
                        height: barHeight < 6 ? 6 : barHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: dynamicGradientColors,
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter),
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

// Carta Bar Melintang Bertingkat Berprofil Kad (Horizontal SaaS-Style Card Bars)
  Widget _buildHorizontalCardBars(List data) {
    if (data.isEmpty)
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("No closed complaints data tracks found.",
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted))));
    int maxVal = data
        .map((e) => (e['total'] ?? 0) as int)
        .reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1;
    return Column(
      children: data.map((item) {
        String name = item['name'] ?? 'General Track';
        int total = item['total'] ?? 0;
        double ratio = total / maxVal;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.5))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.assignment_outlined,
                          size: 14, color: Color(0xFF2E9E52))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary))),
                  Text("$total cases",
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2E9E52))),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF2E9E52)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  //  Membina Peti Skor Bintang Interaktif Khas
  Widget _buildAvgRatingSpecialSection() {
    if (_starsChartData.isEmpty)
      return const Center(child: Text("No rating records found."));

    //  array bintang  5 Star duduk di atas sekali
    List<dynamic> reversedStars = List.from(_starsChartData.reversed);

    int totalFeedbacks = _starsChartData
        .map<int>((e) => (e['value'] ?? 0) as int)
        .reduce((a, b) => a + b);
    int maxStarVal = _starsChartData
        .map<int>((e) => (e['value'] ?? 0) as int)
        .reduce((a, b) => a > b ? a : b);
    if (maxStarVal == 0) maxStarVal = 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 130,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_counters['rating']!,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB45309))),
              const SizedBox(height: 2),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      5,
                      (i) => const Icon(Icons.star_rounded,
                          color: Color(0xFFC9A227), size: 14))),
              const SizedBox(height: 8),
              Text("$totalFeedbacks ratings",
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 20),

        //  (1⭐ - 5⭐ Progress Track Rows)
        Expanded(
          child: Column(
            children: reversedStars.map<Widget>((item) {
              int count = item['value'] ?? 0;
              String label = item['label'] ?? '';
              double rowRatio =
                  totalFeedbacks == 0 ? 0.0 : (count / totalFeedbacks);

              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    SizedBox(
                        width: 45,
                        child: Text(label,
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: rowRatio,
                          backgroundColor: AppColors.pageBackground,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFC9A227)),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                        width: 24,
                        child: Text("$count",
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  //  WIDGET HELPER UNTUK NOTIFIKASI
  // =========================================================================
  Widget _buildMiniTab(
      int index, String label, int active, VoidCallback onTap) {
    bool isSelected = index == active;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEAF1FB) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF2F5FA3) : Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildNotifItem(dynamic tkt, bool isBreached) {
    String initials =
        (tkt['title'] ?? 'T').toString().substring(0, 2).toUpperCase();
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // route ke /tickets/workspace !
        Navigator.pushNamed(context, '/tickets/workspace', arguments: tkt);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isBreached ? const Color(0xFFFDF2F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isBreached
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFF1F5F9)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isBreached
                  ? const Color(0xFFD64545)
                  : const Color(0xFF3B82F6),
              child: isBreached
                  ? const Icon(Icons.warning_amber_rounded,
                      size: 16, color: Colors.white)
                  : Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tkt['title'] ?? '',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      if (isBreached)
                        const Text('BREACHED •',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD64545))),
                    ],
                  ),
                  Text(tkt['ticket_id'] ?? '',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    isBreached
                        ? 'SLA clock breached! Fix action required.'
                        : 'Ticket status — ${tkt['status']}',
                    style: TextStyle(
                        fontSize: 10,
                        color:
                            isBreached ? const Color(0xFFB91C1C) : Colors.grey,
                        fontWeight:
                            isBreached ? FontWeight.w500 : FontWeight.normal),
                  ),
                  if (!isBreached)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                          '${tkt['department'] ?? 'Dept'} · ${tkt['created_at'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 9, color: Colors.black26)),
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
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLink(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.navy),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary))),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
