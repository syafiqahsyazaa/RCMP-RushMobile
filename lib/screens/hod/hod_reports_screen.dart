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

class HodReportsScreen extends StatefulWidget {
  const HodReportsScreen({super.key});

  @override
  State<HodReportsScreen> createState() => _HodReportsScreenState();
}

class _HodReportsScreenState extends State<HodReportsScreen> {
  int _tab = 0;
  bool _isLoading = true;
  final _tabs = const ['Tickets', 'Staff Activity', 'Feedback', 'Category'];

  String _namaJabatanLive = "Loading Department...";

  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _cardKeys = List.generate(5, (index) => GlobalKey());

  // Pemegang data live pangkalan data unicomplaint
  Map<String, dynamic> _ticketData = {};
  Map<String, dynamic> _staffData = {};
  Map<String, dynamic> _feedbackData = {};
  Map<String, dynamic> _categoryData = {};

  @override
  void initState() {
    super.initState();
    _ambilSemuaLaporanMurni();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ambilSemuaLaporanMurni() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_all_reports.php?email=$currentLoggedInUserEmail');
    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final data = json.decode(respon.body);
        setState(() {
          _namaJabatanLive =
              data['department_label'] ?? 'IT Department · Admin';
          _ticketData = data['tickets'] ?? {};
          _staffData = data['staff'] ?? {};
          _feedbackData = data['feedback'] ?? {};
          _categoryData = data['category'] ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Ralat memuat data laporan berpusat: $e");
      setState(() => _isLoading = false);
    }
  }

  void _scrollToReportCard(int index) {
    setState(() => _tab = index);
    final context = _cardKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      drawer: PortalNavDrawer(
        departmentLabel: '$_namaJabatanLive · HOD',
        currentRoute: '/admin/reports',
        items: _adminNavItems,
        staffName: (ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?)?['full_name'] ??
            "Admin UniKL",
        role: (ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?)?['role'] ??
            "HOD",
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy),
        title: const Text('Reports & Analytics',
            style: TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // ==================== BAR MENU HORIZONTAL TOP ANCHORS ====================
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    height: 58,
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
                            backgroundColor: AppColors.pageBackground,
                            labelStyle: TextStyle(
                                color: active
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side:
                                    const BorderSide(color: AppColors.border)),
                            onSelected: (_) => _scrollToReportCard(i),
                          ),
                        );
                      }),
                    ),
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // ==================== CARD 1: TICKETS REPORT PANEL ( LIVE DATABASE) ====================
                        _buildReportCardContainer(
                          key: _cardKeys[0],
                          title: "Tickets Analytics Summary",
                          statsRow: Row(
                            children: [
                              _buildStatBox(
                                  (_ticketData['total'] ?? '0').toString(),
                                  "TOTAL"),
                              _buildVerticalDivider(),
                              _buildStatBox(
                                  (_ticketData['open'] ?? '0').toString(),
                                  "OPEN",
                                  color: const Color(0xFFD64545)),
                              _buildVerticalDivider(),
                              _buildStatBox(
                                  (_ticketData['in_progress'] ?? '0')
                                      .toString(),
                                  "IN PROGRESS",
                                  color: const Color(0xFFC9A227)),
                              _buildVerticalDivider(),
                              _buildStatBox(
                                  (_ticketData['closed'] ?? '0').toString(),
                                  "CLOSED",
                                  color: const Color(0xFF2E9E52)),
                              _buildVerticalDivider(),
                              _buildStatBox(
                                  (_ticketData['high'] ?? '0').toString(),
                                  "HIGH PRIORITY",
                                  color: const Color(0xFFD64545)),
                              _buildVerticalDivider(),
                              _buildStatBox(
                                  (_ticketData['sla_breach'] ?? '0').toString(),
                                  "SLA BREACH"),
                            ],
                          ),
                          chartChild: _buildVerticalBars([
                            {
                              "label": "Open",
                              "value": _ticketData['open'] ?? 0
                            },
                            {
                              "label": "Closed",
                              "value": _ticketData['closed'] ?? 0
                            },
                            {
                              "label": "In Progress",
                              "value": _ticketData['in_progress'] ?? 0
                            },
                            {
                              "label": "High",
                              "value": _ticketData['high'] ?? 0
                            },
                            {
                              "label": "Medium",
                              "value": _ticketData['medium'] ?? 0
                            },
                            {"label": "Low", "value": _ticketData['low'] ?? 0}
                          ]),
                        ),

                        const SizedBox(height: 18),

                        // CARD 2: STAFF ACTIVITY REPORT PANEL
                        _buildReportCardContainer(
                          key: _cardKeys[1],
                          title: "Staff Performance Overview",
                          statsRow: Row(
                            children: [
                              _buildStatBox(
                                  _staffData['total_staff']?.toString() ?? '11',
                                  "TOTAL STAFF"),
                              _buildVerticalDivider(),
                              _buildStatBox(
                                  _staffData['total_resolved']?.toString() ??
                                      '21',
                                  "TOTAL RESOLVED",
                                  color: const Color(0xFF2E9E52)),
                              _buildVerticalDivider(),
                              _buildStatBox(
                                  _staffData['tickets_assigned']?.toString() ??
                                      '21',
                                  "TICKETS ASSIGNED"),
                            ],
                          ),
                          chartChild: _buildVerticalBars(
                              List.from(_staffData['performance'] ??
                                  [
                                    {"label": "ABU", "value": 7},
                                    {"label": "SITI", "value": 5},
                                    {"label": "MOHD", "value": 4},
                                    {"label": "TUN", "value": 3}
                                  ]),
                              barColor: const Color(0xFF2F5FA3)),
                        ),
                        const SizedBox(height: 18),

                        // CARD 4: FEEDBACK REPORT PANEL (PETI SKOR BINTANG GERGASI)
                        _buildReportCardContainer(
                          key: _cardKeys[3],
                          title: "Rating Distribution Overview",
                          statsRow: Row(
                            children: [
                              _buildStatBox(
                                  _feedbackData['total_feedbacks']
                                          ?.toString() ??
                                      '24',
                                  "TOTAL FEEDBACKS"),
                              _buildVerticalDivider(),
                              _buildStatBox(
                                  _feedbackData['closed_tickets']?.toString() ??
                                      '23',
                                  "GLOBAL TICKETS"),
                              _buildVerticalDivider(),
                              _buildStatBox("0", "GLOBAL PENALTY",
                                  color: const Color(0xFFD64545)),
                            ],
                          ),
                          chartChild: _buildAvgRatingSpecialSection(
                              _feedbackData['avg_rating']?.toString() ?? '4.8',
                              _feedbackData['stars'] ?? []),
                        ),
                        const SizedBox(height: 18),

                        // CARD 5: CATEGORY REPORT PANEL (CARTA MELINTANG)
                        _buildReportCardContainer(
                          key: _cardKeys[4],
                          title: "Tickets Category Frequency Breakdown",
                          statsRow: Row(
                            children: [
                              _buildStatBox(
                                  _categoryData['active_categories']
                                          ?.toString() ??
                                      '2',
                                  "ACTIVE CATEGORIES"),
                              _buildVerticalDivider(),
                              _buildStatBox(
                                  _ticketData['total']?.toString() ?? '23',
                                  "TOTAL TICKETS"),
                              _buildVerticalDivider(),
                              _buildStatBox("100%", "RESOLUTION RATE",
                                  color: const Color(0xFF2E9E52)),
                            ],
                          ),
                          chartChild: _buildHorizontalCardBars(
                              _categoryData['frequency'] ??
                                  [
                                    {
                                      "name": "System Application & Website",
                                      "total": 14
                                    },
                                    {
                                      "name": "Operator AV & Network",
                                      "total": 9
                                    }
                                  ]),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

// ====================  ELEMEN GRAFIK KOMPONEN CARTA & LAPORAN TERSUAI ====
  Widget _buildReportCardContainer(
      {required GlobalKey key,
      required String title,
      required Widget statsRow,
      required Widget chartChild}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy)),
          const Divider(height: 24, color: AppColors.border),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal, child: statsRow),
          const Divider(height: 30, color: AppColors.border),
          chartChild,
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label,
      {Color color = AppColors.textPrimary}) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
            height: 24,
            child: VerticalDivider(width: 1, color: AppColors.border)));
  }

  Widget _buildVerticalBars(List<dynamic> data,
      {Color barColor = const Color(0xFF2E9E52)}) {
    if (data.isEmpty)
      return const SizedBox(
          height: 40,
          child: Center(
              child: Text("No charts metric available.",
                  style: TextStyle(fontSize: 11))));
    int maxVal = data
        .map<int>((e) => int.parse((e['value'] ?? 0).toString()))
        .reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        int count = int.parse((item['value'] ?? 0).toString());
        double calculatedHeight = (count / maxVal) * 90;
        String lbl = item['label'] ?? '';
        if (lbl.length > 8) lbl = "${lbl.substring(0, 7)}..";

        List<Color> gradColors = [barColor.withOpacity(0.7), barColor];

        if (item['label'] == 'Open')
          gradColors = [const Color(0xFF60A5FA), const Color(0xFF1D4ED8)];
        if (item['label'] == 'In Progress')
          gradColors = [const Color(0xFFFBBF24), const Color(0xFFD97706)];
        if (item['label'] == 'Closed')
          gradColors = [const Color(0xFF34D399), const Color(0xFF047857)];
        if (item['label'] == 'High')
          gradColors = [const Color(0xFFF87171), const Color(0xFFDC2626)];
        if (item['label'] == 'Medium')
          gradColors = [const Color(0xFFFB923C), const Color(0xFFEA580C)];
        if (item['label'] == 'Low')
          gradColors = [const Color(0xFF93C5FD), const Color(0xFF2563EB)];

        return Column(
          children: [
            Text("$count",
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: calculatedHeight < 6 ? 6 : calculatedHeight,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: gradColors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6))),
            ),
            const SizedBox(height: 6),
            Text(lbl,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHorizontalCardBars(List data) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
              "No reporting or analytical department cases recorded yet.",
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
        ),
      );
    }

    int maxVal = 0;
    for (var e in data) {
      int totalAduan = (e['total'] ?? 0) as int;
      if (totalAduan > maxVal) {
        maxVal = totalAduan;
      }
    }
    if (maxVal == 0) maxVal = 1;

    return Column(
      children: data.map((item) {
        String name = item['name'] ?? 'General';
        int total = item['total'] ?? 0;
        double ratio = total / maxVal;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text("$total cases",
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E9E52)))
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppColors.pageBackground,
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF2E9E52)),
                      minHeight: 7)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvgRatingSpecialSection(String score, List stars) {
    List localStars = stars.isEmpty
        ? [
            {"label": "5 Stars", "value": 20},
            {"label": "4 Stars", "value": 3},
            {"label": "3 Stars", "value": 1},
            {"label": "2 Stars", "value": 0},
            {"label": "1 Star", "value": 0}
          ]
        : List.from(stars.reversed);
    int total =
        localStars.map((e) => (e['value'] ?? 0) as int).reduce((a, b) => a + b);
    return Row(
      children: [
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A))),
          child: Column(children: [
            Text(score,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB45309))),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    5,
                    (i) => const Icon(Icons.star_rounded,
                        color: Color(0xFFC9A227), size: 12))),
            const SizedBox(height: 6),
            Text("$total reviews",
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary))
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: localStars.map((item) {
              int count = item['value'] ?? 0;
              double rowRatio = total == 0 ? 0.0 : (count / total);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(children: [
                  SizedBox(
                      width: 45,
                      child: Text(item['label'] ?? '',
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                              value: rowRatio,
                              backgroundColor: AppColors.pageBackground,
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFFC9A227)),
                              minHeight: 5))),
                  const SizedBox(width: 8),
                  SizedBox(
                      width: 20,
                      child: Text("$count",
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)))
                ]),
              );
            }).toList(),
          ),
        )
      ],
    );
  }
}
