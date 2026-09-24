import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';

/// "Ticket Detail" — user-facing view of a single ticket, including a "Rate your experience" feedback panel.class TicketDetailUserScreen extends StatefulWidget {
class TicketDetailUserScreen extends StatefulWidget {
  const TicketDetailUserScreen({super.key});

  @override
  State<TicketDetailUserScreen> createState() => _TicketDetailUserScreenState();
}

class _TicketDetailUserScreenState extends State<TicketDetailUserScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  int _selectedRatingIndex = -1; // -1 bermaksud belum ada rating dipilih
  bool _isSaving = false;
  bool _hasSubmittedBefore = false; // Pengunci jika user sudah berjaya hantar

// 5 EMOJI:  tepat 5 item untuk match dengan struktur rating (1-5) dalam database
  final List<String> _emojis = ['🤬', '🙁', '😐', '🙂', '🥰'];
  final List<String> _ratingLabels = [
    'Very Dissatisfied',
    'Dissatisfied',
    'Average Support',
    'Satisfied',
    'Very Satisfied'
  ];

//  Senarai log activity rujukan penuaan mesej
  List<dynamic> _ticketLogs = [];
  Map<String, dynamic>? _feedbackDataLive; // Ambil feedback sedia ada

  Map<String, dynamic> _ticketData = {};
  bool _isDataLoadedLive = false;
// =========================================================================
//  AMBIL SEJARAH AKTIVITI TIKET SEWAKTU INITSTATE !
// =========================================================================
  @override
  void initState() {
    super.initState();

// Future.delayed memastikan data context arguments sedia dibaca
    Future.delayed(Duration.zero, () {
      if (mounted) {
        final Object? argsLive = ModalRoute.of(context)?.settings.arguments;
        if (argsLive != null && argsLive is Map<String, dynamic>) {
          String ticketIdTulen =
              (argsLive['ticket_id'] ?? '').toString().trim();
          if (ticketIdTulen.isNotEmpty) {
// KEJUTKAN TEMBAKAN API SEJARAH CHAT MESSAGES!
            _ambilSejarahAktivitiTiket(ticketIdTulen);
            _ambilDataAduanTerkini(ticketIdTulen);
            _cekFeedbackSediaAda(ticketIdTulen); // Semak jika dah ada feedback
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

// =========================================================================
// ambil DATA SEJARAH LOG ADUAN TIMELINE
// =========================================================================
  Future<void> _ambilSejarahAktivitiTiket(String idTiket) async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_ticket_history.php?ticket_id=$idTiket');
    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final List<dynamic> dataDiterima = json.decode(respon.body);
        setState(() {
          _ticketLogs = dataDiterima;
        });
        print(
            "🚀 SEJARAH TIMELINE USER BERJAYA DISEDUT: ${dataDiterima.length} logs untuk tiket $idTiket");
      }
    } catch (e) {
      print("Ralat menarik sejarah aktiviti tiket mata user: $e");
    }
  }

  Future<void> _ambilDataAduanTerkini(String idTiket) async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_my_complaints.php?ticket_id=$idTiket&b_cache=${DateTime.now().millisecondsSinceEpoch}');

    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final dataMentahLaragon = json.decode(respon.body);

        //  Semak jika data yang datang dari PHP ialah List [] atau Objek Map {}
        if (dataMentahLaragon is List && dataMentahLaragon.isNotEmpty) {
          setState(() {
            // get data aduan tiket tunggal tepat dari index pertama [0] list
            _ticketData = Map<String, dynamic>.from(dataMentahLaragon.first);
          });
        } else if (dataMentahLaragon is Map<String, dynamic>) {
          setState(() {
            _ticketData = dataMentahLaragon;
          });
        }

        print(
            " REKOD COMPLAINTS REFRESHED DARI LIST PHP: Handled By = ${_ticketData['remarks']}");
      }
    } catch (e) {
      print("Ralat fatal menarik data refresh complaints: $e");
    }
  }

  // FUNGSI SEMAK FEEDBACK: Pastikan section locked kalau user dah pernah hantar
  Future<void> _cekFeedbackSediaAda(String idTiket) async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_ticket_feedback.php?ticket_id=$idTiket');
    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final data = json.decode(respon.body);
        // Jika status bukan 'kosong' atau 'locked', bermakna data feedback wujud!
        if (data != null &&
            data['status'] != 'kosong' &&
            data['status'] != 'locked') {
          if (mounted) {
            setState(() {
              _hasSubmittedBefore = true;
              _feedbackDataLive = data;
            });
          }
        }
      }
    } catch (e) {
      print("Error semak feedback: $e");
    }
  }

  //  Bina Kad Feedback
  Widget _buildSubmittedFeedbackCard() {
    if (_feedbackDataLive == null) return const SizedBox.shrink();

    int rating = int.tryParse(_feedbackDataLive!['rating'].toString()) ?? 5;
    String dateStr = _feedbackDataLive!['created_at'] ?? 'Just Now';

    if (dateStr.length >= 19) {
      try {
        String thn = dateStr.substring(0, 4);
        String blnNum = dateStr.substring(5, 7);
        String tgl = dateStr.substring(8, 10);
        String jamMnt = dateStr.substring(11, 16);
        List<String> listBln = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        String blnTeks = listBln[int.parse(blnNum) - 1];
        dateStr = "$tgl $blnTeks $thn, $jamMnt";
      } catch (e) {}
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E9E52).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_emojis[rating - 1], style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ratingLabels[rating - 1],
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E9E52)),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                              5,
                              (index) => Icon(
                                    index < rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 14,
                                    color: const Color(0xFF2E9E52),
                                  )),
                        ),
                        const SizedBox(width: 8),
                        Text("$rating/5",
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black38)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Submitted $dateStr",
            style: const TextStyle(fontSize: 10.5, color: Colors.black26),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return const Color(0xFF2E9E52);
      case 'in_progress':
        return Colors.orange;
      default:
        return const Color(0xFF2F5FA3);
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return const Color(0xFFEAF7EE);
      case 'in_progress':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFEAF1FB);
    }
  }

// post data feedback complainant secara live ke jadual ticket_feedback
  Future<void> _submitFeedback(String ticketId) async {
    if (_selectedRatingIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an emoji rating first!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    int dbRatingValue = _selectedRatingIndex + 1;
    String ulasanText = _feedbackController.text.trim();

    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url =
        Uri.parse('http://$domain/helpdesk_api/add_ticket_feedback.php');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "ticket_id": ticketId,
          "submitter_id": 1,
          "rating": dbRatingValue,
          "comment": ulasanText.isEmpty ? "No comment provided." : ulasanText,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> hasil = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(hasil['mesej'] ?? 'Thank you for your feedback!')));

          if (hasil['status'] == 'berjaya') {
            _cekFeedbackSediaAda(
                ticketId); // tarik semula data feedback dari server
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ralat penghantaran: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic> ticketData =
        (args != null && args is Map<String, dynamic>) ? args : {};

    String ticketId = ticketData['ticket_id'] ?? 'RCMP-00000000-0';
    String title = ticketData['title'] ?? 'No Title Specified';
    String status = ticketData['status'] ?? 'open';
    String priority = ticketData['priority'] ?? 'Medium';
    String myDepartment = ticketData['my_department'] ?? 'General';
    String description =
        ticketData['description'] ?? 'No description provided.';
    String dateSubmitted = ticketData['created_at'] ?? '18 Aug 2026, 11:35';

    String deptIdRaw = (ticketData['dept_id'] ?? '4').toString();
    String namaJabatanInCharge = 'Information Technology Department';

    if (deptIdRaw == '1') {
      namaJabatanInCharge = 'Administration & Facilities Management Department';
    } else if (deptIdRaw == '2') {
      namaJabatanInCharge = 'Maintenance Department';
    } else if (deptIdRaw == '3') {
      namaJabatanInCharge = 'Corporate Communication Unit';
    } else if (deptIdRaw == '4') {
      namaJabatanInCharge = 'Information Technology Department';
    } else if (deptIdRaw == '5') {
      namaJabatanInCharge = 'Human Capital Department';
    }

    String staffHandledBy = _ticketData['remarks'] ??
        ticketData['remarks'] ??
        _ticketData['staff_name'] ??
        'Unassigned';

    if (staffHandledBy.isEmpty ||
        staffHandledBy.trim().toLowerCase() == 'null') {
      staffHandledBy = 'Unassigned';
    }

// Kekalkan ejaan asal nama penuh tanpa menggunakan fungsi .split
    staffHandledBy = staffHandledBy.trim().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy),
        title: const Text('Ticket Detail',
            style: TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),

// KAD 1: BUTIRAN MAKLUMAT UTAMA ADUAN TIKET
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary))),
                      const SizedBox(width: 8),
                      StatusTag(
                          label: status.toUpperCase(),
                          background: _getStatusBg(status),
                          foreground: _getStatusColor(status)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(ticketId,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 20,
                    runSpacing: 14,
                    children: [
                      ReviewField(
                          label: 'Department In Charge',
                          value: namaJabatanInCharge),
                      ReviewField(
                          label: 'From Department', value: myDepartment),
                      ReviewField(label: 'Priority', value: priority),
                      ReviewField(
                          label: 'Submitted Date', value: dateSubmitted),
                      ReviewField(
                        label: 'Last Updated',
                        value: (_ticketData['updated_at'] ??
                                ticketData['updated_at'] ??
                                dateSubmitted ??
                                'Just Now')
                            .toString()
                            .trim(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 8),
                  ReviewField(label: 'Description', value: description),
                ],
              ),
            ),

            const SizedBox(height: 14),

// KAD 2: BAHAGIAN KAKITANGAN BERTUGAS & BORANG MAKLUM BALAS PENGADU
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.engineering_outlined,
                          size: 16, color: AppColors.textMuted),
                      SizedBox(width: 6),
                      Text('Handled By', style: AppTextStyles.fieldLabel),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.fieldBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.5))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.navy,
                          child: Text(
                            staffHandledBy.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(staffHandledBy,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (status.toLowerCase() == 'closed') ...[
                    const Divider(height: 24),
                    Row(
                      children: const [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 15, color: Colors.blueGrey),
                        SizedBox(width: 8),
                        Text('YOUR FEEDBACK',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                                letterSpacing: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _hasSubmittedBefore
                        ? _buildSubmittedFeedbackCard()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                  'Rate your experience with this ticket resolution process',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children:
                                    List.generate(_emojis.length, (index) {
                                  bool isSelected =
                                      _selectedRatingIndex == index;
                                  return _FaceButton(
                                    emoji: _emojis[index],
                                    isSelected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        _selectedRatingIndex = index;
                                      });
                                    },
                                  );
                                }),
                              ),
                              const SizedBox(height: 14),
                              if (_selectedRatingIndex != -1)
                                Center(
                                    child: Text(
                                        _ratingLabels[_selectedRatingIndex],
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.navy))),
                              const SizedBox(height: 14),
                              const Text('Share your thoughts (Optional)',
                                  style: AppTextStyles.fieldLabel),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _feedbackController,
                                minLines: 2,
                                maxLines: 4,
                                style: const TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText:
                                      'Share your thoughts about response time, staff helpfulness, or equipment restoration accuracy...',
                                  hintStyle: const TextStyle(
                                      fontSize: 11, color: AppColors.textMuted),
                                  filled: true,
                                  fillColor: AppColors.fieldBackground,
                                  contentPadding: const EdgeInsets.all(10),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppColors.border)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppColors.border)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppColors.navy)),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _isSaving
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : SuccessButton(
                                      label: 'Submit Official Feedback',
                                      icon: Icons.send_outlined,
                                      onPressed: () =>
                                          _submitFeedback(ticketId),
                                    ),
                            ],
                          )
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100)),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Feedback tracking and rating buttons will automatically activate once this ticket is fully resolved and CLOSED by the staff member.',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
// PANGGIL WIDGET CHAT TIMELINE
            _buildMessagesTimelinePanelLive(ticketData, staffHandledBy),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

// =========================================================================
// PANEL GRAFIK MESSAGES TIMELINE CHAT
// =========================================================================
  Widget _buildMessagesTimelinePanelLive(
      Map<String, dynamic> ticketData, String staffName) {
    String statusLive =
        (ticketData['status'] ?? 'open').toString().toLowerCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 16, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text(
                    'MESSAGES & UPDATES',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFF0F52BA),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${_ticketLogs.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
          ),
          const SizedBox(height: 14),
          _ticketLogs.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No activity log recorded for this ticket yet.",
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(_ticketLogs.length, (index) {
                    final log = _ticketLogs[index];
                    String namaAktor = (log['transferred_by_name'] ?? 'SYSTEM')
                        .toString()
                        .trim();
                    String ulasanLogText =
                        (log['reason'] ?? 'Activity logged.').toString().trim();
                    String tarikhLog = (log['transferred_at'] ?? '').toString();
                    String masaDipapar = tarikhLog.length > 16
                        ? tarikhLog.substring(11, 16)
                        : 'Just Now';
                    String tarikhDipapar = tarikhLog.length > 10
                        ? tarikhLog.substring(8, 10) +
                            "/" +
                            tarikhLog.substring(5, 7)
                        : '';
                    if (ulasanLogText.contains('|')) {
                      ulasanLogText = ulasanLogText.split('|').last.trim();
                    }
                    bool adakahIniPelajarComplainant =
                        namaAktor.toLowerCase().contains('student') ||
                            namaAktor.toLowerCase().contains('you') ||
                            namaAktor.toLowerCase() ==
                                (ticketData['submitter_email'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .trim();
                    if (adakahIniPelajarComplainant) {
                      return _buildUserChatBubbleRight(
                          ulasanLogText, "$masaDipapar ($tarikhDipapar)");
                    } else {
                      return _buildAdminChatBubbleLeft(namaAktor, ulasanLogText,
                          "$masaDipapar ($tarikhDipapar)");
                    }
                  }),
                ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'This conversation is read-only.',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.black38,
                  fontStyle: FontStyle.italic),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSystemStatusBubbleLine(String text, String time, bool isClosed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isClosed ? const Color(0xFFEAF7EE) : const Color(0xFFEAF1FB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isClosed
                      ? const Color(0xFF2E9E52).withOpacity(0.2)
                      : const Color(0xFF2F5FA3).withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isClosed
                            ? const Color(0xFF2E9E52)
                            : const Color(0xFF0F52BA))),
                const SizedBox(width: 8),
                Text(text,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildUserChatBubbleRight(String message, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('You',
                  style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxWidth: 260),
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: const Color(0xFF0F52BA),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12)),
                ),
                child: Text(message,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, height: 1.3)),
              ),
            ],
          ),
          const SizedBox(width: 6),
          CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blue.shade100,
              child: const Text('Y',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F52BA)))),
        ],
      ),
    );
  }

  Widget _buildAdminChatBubbleLeft(String actor, String message, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFF3E8FF),
              child: const Icon(
                Icons.engineering_outlined,
                size: 10,
              )),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(actor,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.purple,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text('• $time',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12)),
                    border: Border.all(
                        color: Colors.black12.withValues(alpha: 0.05)),
                  ),
                  child: Text(message,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          height: 1.3)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceButton extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;
  const _FaceButton(
      {required this.emoji, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : AppColors.fieldBackground,
          shape: BoxShape.circle,
          border: Border.all(
              color: isSelected ? AppColors.navy : AppColors.border,
              width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: TextStyle(fontSize: isSelected ? 22 : 18)),
      ),
    );
  }
}
