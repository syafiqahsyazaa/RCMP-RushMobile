import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../main.dart';

const _adminNavItems = [
  AdminNavItem(Icons.dashboard_outlined, 'Dashboard', '/hod/dashboard'),
  AdminNavItem(Icons.bar_chart_outlined, 'Reports & Analytics', '/hod/reports'),
];

class HodDashboardScreen extends StatefulWidget {
  const HodDashboardScreen({super.key});

  @override
  State<HodDashboardScreen> createState() => _HodDashboardScreenState();
}

class _HodDashboardScreenState extends State<HodDashboardScreen> {
  int _selectedCardIndex = 0;
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

  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _sectionKeys = List.generate(4, (index) => GlobalKey());
  final List<String> _sectionTitles = const [
  ];

  void _scrollToSection(int index) {
    setState(() => _selectedCardIndex = index);
    final context = _sectionKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _ambilDataAdminDashboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Tempat menyimpan nama jabatan secara dinamik dari database
  String _namaJabatanLive = "IT Department · HOD";
  String _namaHodLive = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _namaHodLive.isEmpty) {
      setState(() {
        _namaHodLive =
            (args['full_name'] ?? args['name'] ?? "").toString().trim();
      });
    }
  }

  Future<void> _ambilDataAdminDashboard() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';

    // Kita heret 'currentLoggedInUserEmail' dari main.dart untuk dihantar ke Laragon!
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_admin_dashboard.php?email=$currentLoggedInUserEmail');

    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(respon.body);
        setState(() {
          // ambil nama jabatan & nama HOD yang dihantar dari database Laragon
          _namaJabatanLive = data['department_label'] ?? 'IT Department · HOD';
          _namaHodLive =
              (data['admin_name'] ?? data['hod_name'] ?? '').toString().trim();

          _counters = Map<String, String>.from(data['counters']);
          _statusChartData = data['charts']['status'] ?? [];
          _priorityChartData = data['charts']['priority'] ?? [];
          _closedFreqChartData = data['charts']['closed_frequency'] ?? [];
          _starsChartData = data['charts']['stars'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Ralat memuat data admin dashboard: $e");
      setState(() => _isLoading = false);
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
      bottomNavigationBar: PortalBottomNav(
        items: _adminNavItems,
        currentRoute: '/hod/dashboard',
      ),
      appBar: buildAdminAppBar(
        context: context,
        departmentLabel: _namaJabatanLive,
        screenTitle: 'HOD Dashboard Overview',
        adminName: _namaHodLive.isNotEmpty ? _namaHodLive : 'HOD',
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ==================== HERO GRADIENT HEADER CARD ====================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16233F), Color(0xFF0F1A30)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.gold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _namaJabatanLive.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Welcome back, ${_namaHodLive.isNotEmpty ? _namaHodLive : 'HOD'}!",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Here is your department performance overview.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "ACTIVE",
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _counters['all'] ?? '0',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==================== BARISAN 4 KAD INTERAKTIF  ====================
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

                  // ==================== HORIZONTAL TABS BAR ====================
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: List.generate(_sectionTitles.length, (i) {
                        final active = _selectedCardIndex == i;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_sectionTitles[i],
                                style: const TextStyle(fontSize: 11.5)),
                            selected: active,
                            selectedColor: AppColors.navy,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color:
                                  active ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            onSelected: (_) => _scrollToSection(i),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ==================== SECTION 0: STATUS OVERVIEW ====================
                  Container(
                    key: _sectionKeys[0],
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardHeader(
                          Icons.bar_chart_rounded,
                          const Color(0xFF2F5FA3),
                          const Color(0xFFEAF1FB),
                          'All Tickets Status Overview',
                          'Real-time volume overview segmented by complaint status tracks.',
                        ),
                        const Divider(height: 40, color: AppColors.border),
                        _buildVerticalBars(_statusChartData,
                            startColor: const Color(0xFF3B82F6),
                            endColor: const Color(0xFF1D4ED8)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==================== SECTION 1: PRIORITY BREAKDOWN ====================
                  Container(
                    key: _sectionKeys[1],
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardHeader(
                          Icons.notification_important_rounded,
                          const Color(0xFFD64545),
                          const Color(0xFFFDF2F2),
                          'Open Tickets Priority Breakdown',
                          'Urgency assessment metrics for active open complaints.',
                        ),
                        const Divider(height: 40, color: AppColors.border),
                        _buildVerticalBars(_priorityChartData,
                            startColor: const Color(0xFFF87171),
                            endColor: const Color(0xFFDC2626)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==================== SECTION 2: TOP CATEGORIES ====================
                  Container(
                    key: _sectionKeys[2],
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardHeader(
                          Icons.pie_chart_outline_rounded,
                          const Color(0xFF2E9E52),
                          const Color(0xFFEAF7EE),
                          'Top Closed Complaints Frequency',
                          'Category tracks with the highest number of fully resolved tickets.',
                        ),
                        const Divider(height: 40, color: AppColors.border),
                        _buildHorizontalCardBars(_closedFreqChartData),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==================== SECTION 3: FEEDBACK RATINGS ====================
                  Container(
                    key: _sectionKeys[3],
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardHeader(
                          Icons.star_rounded,
                          const Color(0xFFC9A227),
                          const Color(0xFFFFF8E6),
                          'Feedback Rating Breakdown',
                          'Total counts recorded for each feedback score star packet.',
                        ),
                        const Divider(height: 40, color: AppColors.border),
                        _buildAvgRatingSpecialSection(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGlowStatCard(
      int index, String value, String label, IconData icon, Color themeColor) {
    bool isSelected = _selectedCardIndex == index;

    return GestureDetector(
      onTap: () => _scrollToSection(index),
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
            Column(
              children: List.generate(
                  4,
                  (i) => Container(
                      margin: const EdgeInsets.only(bottom: 34),
                      width: double.infinity,
                      height: 1,
                      color: AppColors.border.withOpacity(0.5))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((item) {
                  int count = item['value'] ?? 0;
                  double barHeight = (count / maxVal) * 110;
                  String label = (item['label'] ?? '').toString();

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
                    ]; // Kuning/Oren
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

  Widget _buildAvgRatingSpecialSection() {
    if (_starsChartData.isEmpty)
      return const Center(child: Text("No rating records found."));

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

  // Pembantu tajuk kad carta
  Widget _buildCardHeader(IconData icon, Color iconColor, Color bgColor,
      String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
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
