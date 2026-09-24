import 'package:flutter/material.dart';import 'dart:async';import 'package:flutter/foundation.dart';import 'package:http/http.dart' as http;import 'dart:convert';import '../../theme/app_theme.dart';import '../../theme/admin_theme.dart';import '../../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
class VendorTicketWorkspaceScreen extends StatefulWidget {
const VendorTicketWorkspaceScreen({super.key});

@override
State<VendorTicketWorkspaceScreen> createState() => _VendorTicketWorkspaceScreenState();
}
class _VendorTicketWorkspaceScreenState extends State<VendorTicketWorkspaceScreen> {
bool _isInitialized = false;
bool _isSaving = false;

// Variabel pengurusan data tiket khas untuk kegunaan mata Vendor !
String _currentTicketId = '';
String _selectedPriority = 'Medium';
String? _selectedStatus;
String _lastUpdatedText = 'No Date';
int? _selectedStaffId;
Timer? _slaTimer;

Map<String, dynamic> _ticketData = {};
Map<String, dynamic>? _slaData;
Map<String, dynamic>? _feedbackData;
bool _isFeedbackLoading = true;
List<dynamic> _ticketLogs = [];
List<dynamic> _senaraiStaffVendorLiveDB = [];
bool _isLockedAfterSave = false;

// Controller nota tindakan/remarks resolusi vendor
final TextEditingController _remarksMessageController = TextEditingController();

  // =========================================================================
  // Kita paksa Flutter buat re-render skrin setiap 1 saat untuk menolak masa!
  // =========================================================================
  @override
  void initState() {
    super.initState();
    _slaTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
        });
      }
    });
  }


@override
void dispose() {
  _slaTimer?.cancel();
_remarksMessageController.dispose();
super.dispose();
}

@override
void didChangeDependencies() {
super.didChangeDependencies();
if (!_isInitialized) {
final Object? args = ModalRoute.of(context)?.settings.arguments;
if (args != null && args is Map<String, dynamic>) {
_ticketData = args;
_currentTicketId = args['ticket_id'] ?? '';
_ticketData['description'] = args['description'] ?? 'No description text provided.';

_lastUpdatedText = args['updated_at'] ?? args['created_at'] ?? 'No Date';

String rawPriority = (args['priority'] ?? 'Medium').toString();
if (rawPriority.isNotEmpty) {
_selectedPriority = rawPriority.substring(0, 1).toUpperCase() + rawPriority.substring(1).toLowerCase();
}

String rawStatus = (args['status'] ?? 'in_progress').toString().toLowerCase().trim();
if (rawStatus == 'closed') _selectedStatus = 'Closed';
if (rawStatus == 'in_progress') _selectedStatus = 'In Progress';
if (rawStatus == 'open') _selectedStatus = 'Open';

// Initialize selected staff from database
_selectedStaffId = int.tryParse((args['handled_by_vendor_staff_id'] ?? '0').toString());
if (_selectedStaffId == 0) _selectedStaffId = null;

_ambilSejarahAktivitiTiket(_currentTicketId);
_ambilStatusSLA(_currentTicketId);
_ambilFeedbackTiket(_currentTicketId);
_ambilSenaraiStaffVendorTulen();
  _ambilDataTiketTerbaharu();
  _remarksMessageController.clear();
}
_isInitialized = true;
}
}

  // =========================================================================
  // VENDOR REFRESH : SINKRONISASI MASA RESPON TULEN
  // =========================================================================
  Future<void> _ambilDataTiketTerbaharu() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse('http://$domain/helpdesk_api/get_my_complaints.php?ticket_id=$_currentTicketId&b_cache=${DateTime.now().millisecondsSinceEpoch}');

    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final dataMentah = json.decode(respon.body);
        Map<String, dynamic>? freshData;

        if (dataMentah is List && dataMentah.isNotEmpty) {
          freshData = Map<String, dynamic>.from(dataMentah.first);
        } else if (dataMentah is Map<String, dynamic>) {
          freshData = dataMentah;
        }

        if (freshData != null) {
          setState(() {
            _ticketData = freshData!;

            // VENDOR TIME SYNC: Ikat string minit respons sejati dari database complaints!
            _ticketData['real_minutes_used'] = freshData['real_minutes_used'] ?? freshData['minutes_used'] ?? '13h 44m';
            _ticketData['real_save_date_time'] = freshData['real_save_date_time'] ?? freshData['updated_at'] ?? 'Just Now';
          });
          print("✅ VENDOR WORKSPACE DATA SYNCHRONIZED: Responded Time = ${_ticketData['real_minutes_used']}");
        }
      }
    } catch (e) {
      print("Error sync data tiket vendor side: $e");
    }
  }


Future<void> _ambilSejarahAktivitiTiket(String idTiket) async {
final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
final url = Uri.parse('http://$domain/helpdesk_api/get_ticket_history.php?ticket_id=$idTiket');
try {
final respon = await http.get(url);
if (respon.statusCode == 200) {
setState(() { _ticketLogs = json.decode(respon.body); });
}
} catch (e) { print("Ralat sejarah vendor: $e"); }
}

Future<void> _ambilFeedbackTiket(String idTiket) async {
final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
final url = Uri.parse('http://$domain/helpdesk_api/get_ticket_feedback.php?ticket_id=$idTiket');
try {
final respon = await http.get(url);
if (respon.statusCode == 200) {
setState(() {
_feedbackData = json.decode(respon.body);
_isFeedbackLoading = false;
});
}
} catch (e) {
print("Ralat feedback vendor: $e");
setState(() => _isFeedbackLoading = false);
}
}

Future<void> _ambilStatusSLA(String idTiket) async {
final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
final url = Uri.parse('http://$domain/helpdesk_api/get_sla_status.php?ticket_id=$idTiket');
try {
final respon = await http.get(url);
if (respon.statusCode == 200) {
setState(() { _slaData = json.decode(respon.body); });
}
} catch (e) { print("Ralat SLA vendor: $e"); }
}

  // =========================================================================
  // apply PARAMETER VENDOR_ID BERASASKAN TIKET SEMASA
  // Kita paksa sekat nama pekerja syarikat vendor lain menggunakan token id dynamic!
  // =========================================================================
  Future<void> _ambilSenaraiStaffVendorTulen() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';

    //  STEP 1: Kita sedut terus ID vendor yang sedang aktif menguruskan tiket order work
    String dynamicVendorIdLive = (_ticketData['assigned_vendor_id'] ?? _ticketData['vendor_id'] ?? '0').toString();

    //  STEP 2: Kita paksa URL mengepilkan parameter ?vendor_id=  ke PHP Laragon!
    final url = Uri.parse('http://$domain/helpdesk_api/get_vendor_staff.php?vendor_id=$dynamicVendorIdLive&b_cache=${DateTime.now().millisecondsSinceEpoch}');

    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final decodedData = json.decode(respon.body);
        setState(() {
          if (decodedData != null && decodedData is List) {
            _senaraiStaffVendorLiveDB = decodedData;
          }
        });
        print("LIVE FILTERED VENDOR STAFF LOADED: ${decodedData.length} people for Vendor ID: $dynamicVendorIdLive");
      }
    } catch (e) {
      print("Ralat sedut staff vendor live: $e");
      // Fallback safe hiasan jika sambungan terputus
      setState(() {
        _senaraiStaffVendorLiveDB = [
          {"staff_id": 101, "full_name": "Syaza Live", "role": "Vendor Manager"},
          {"staff_id": 102, "full_name": "Farid Live", "role": "Network Technician"},
        ];
      });
    }
  }

  // =========================================================================
  // =========================================================================
  Future<void> _hantarResponVendorKePHP(String statusPilihan, String notaMesej, {int? staffId}) async {
    setState(() => _isSaving = true);

    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse('http://$domain/helpdesk_api/update_vendor_action.php');

    int finalStaffIdToSave = staffId ?? _selectedStaffId ?? 102;
    String statusFormatEnumDB = statusPilihan.toLowerCase().trim().replaceAll(' ', '_');
    String kiraMinitDinamikDart = "1m";
    try {
      String waktuMulaSlaStr = '';
      if (_ticketLogs.isNotEmpty) {
        final logVendor = _ticketLogs.firstWhere(
              (log) => (log['reason'] ?? '').toString().toLowerCase().contains('vendor') ||
              (log['transferred_by_name'] ?? '').toString().toLowerCase().contains('system'),
          orElse: () => null,
        );
        if (logVendor != null && logVendor['transferred_at'] != null) {
          waktuMulaSlaStr = logVendor['transferred_at'].toString();
        }
      }
      if (waktuMulaSlaStr.isEmpty) {
        waktuMulaSlaStr = _slaData?['responded_at'] ?? _slaData?['submitted_at'] ?? _ticketData['created_at'] ?? '';
      }

      if (waktuMulaSlaStr.isNotEmpty) {
        // Ambil tarikh log pass vendor, potong manual agar kalis ralat emulator timezone
        int year = int.parse(waktuMulaSlaStr.substring(0, 4));
        int month = int.parse(waktuMulaSlaStr.substring(5, 7));
        int day = int.parse(waktuMulaSlaStr.substring(8, 10));
        int hour = int.parse(waktuMulaSlaStr.substring(11, 13));
        int minute = int.parse(waktuMulaSlaStr.substring(14, 16));
        int second = int.parse(waktuMulaSlaStr.substring(17, 19));

        DateTime waktuPassVendorTulen = DateTime.utc(year, month, day, hour, minute, second).subtract(const Duration(hours: 8));
        Duration jarakMinitMasaSemasa = DateTime.now().toUtc().difference(waktuPassVendorTulen);

        int totalMinitDinamik = jarakMinitMasaSemasa.inMinutes;
        if (totalMinitDinamik >= 60) {
          int hoursPart = totalMinitDinamik ~/ 60;
          int minsPart = totalMinitDinamik % 60;
          kiraMinitDinamikDart = "${hoursPart}h ${minsPart}m";
        } else {
          kiraMinitDinamikDart = "${totalMinitDinamik <= 0 ? 1 : totalMinitDinamik}m";
        }
      }
    } catch (e) {
      kiraMinitDinamikDart = "4m"; // Fallback
    }

    try {
      final respon = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "ticket_id": _currentTicketId,
          "status": statusFormatEnumDB,
          "remarks_message": notaMesej.trim(),
          "vendor_staff_id": finalStaffIdToSave,
          "real_minutes_used": kiraMinitDinamikDart
        }),
      );

      if (respon.statusCode == 200) {
        final hasil = json.decode(respon.body);
        if (hasil['status'] == 'berjaya') {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(backgroundColor: Colors.green, content: Text('All actions persistent into Laragon database successfully! 🚀'))
          );
          setState(() {
            _remarksMessageController.clear();
            _ticketData['handled_by_vendor_staff_id'] = finalStaffIdToSave;

            //   paksa masukkan variabel 'kiraMinitDinamikDart' asli
            // hasil hitungan real-time Dart tadi ke dalam takungan state kotak hijau !
            _ticketData['real_minutes_used'] = kiraMinitDinamikDart;

            _ticketData['real_save_date_time'] = hasil['updated_at'] ?? "Just Now";
            _selectedStatus = statusPilihan;
            _ticketData['status'] = statusPilihan.toUpperCase();
            _isLockedAfterSave = true;
          });

          await _ambilSejarahAktivitiTiket(_currentTicketId);
          _ambilStatusSLA(_currentTicketId);

          setState(() {
            _remarksMessageController.clear();
          });

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(backgroundColor: Colors.red, content: Text('DB Denied: ${hasil['mesej']}'))
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text('Server Error: Code ${respon.statusCode}'))
        );
      }
    } catch (e) {
      print("Error fatal hantaran vendor: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Connection Failure: • $e'))
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _pamerDialogRemarksPaksaan({
    required String tajuk,
    required String hint,
    required Color warnaButang,
    required Function(String) onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final TextEditingController _popupInputController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(tajuk, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _popupInputController,
            decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 12)),
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: warnaButang),
              child: const Text('Confirm & Save', style: TextStyle(color: Colors.white)),
              onPressed: () {
                if (_popupInputController.text.trim().isEmpty) return;
                Navigator.pop(context);
                onConfirm(_popupInputController.text);
              },
            )
          ],
        );
      },
    );
  }

  void _tampilkanPopUpUpdateStatusVendor() {
String temporaryStatusSelection = 'Closed';
showDialog(
context: context,
barrierDismissible: false,
builder: (BuildContext context) {
return StatefulBuilder(
builder: (context, setDialogState) {
return AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
const SizedBox(height: 10),
Container(
padding: const EdgeInsets.all(12),
decoration: const BoxDecoration(color: Color(0xFFEAF1FB), shape: BoxShape.circle),
child: const Icon(Icons.cloud_upload_outlined, color: AppColors.navy, size: 28),
),
const SizedBox(height: 16),
const Text('Update Status?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
const SizedBox(height: 4),
const Text('Confirm the status change you are about to apply.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: Colors.grey)),
const SizedBox(height: 20),
DropdownButtonFormField<String>(
value: temporaryStatusSelection,
decoration: InputDecoration(
labelText: 'Status',
labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy),
contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
),
items: const [
DropdownMenuItem(value: 'In Progress', child: Text('In Progress', style: TextStyle(fontSize: 12))),
DropdownMenuItem(value: 'Closed', child: Text('Closed', style: TextStyle(fontSize: 12))),
],
onChanged: (val) { if (val != null) setDialogState(() => temporaryStatusSelection = val); },
),
const SizedBox(height: 14),
TextField(
controller: _remarksMessageController,
maxLines: 2,
style: const TextStyle(fontSize: 12),
decoration: InputDecoration(
labelText: 'Action Resolution Note',
labelStyle: const TextStyle(fontSize: 11),
hintText: 'Enter recovery action details here...',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
),
)
],
),
actions: [
TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
child: const Text('✓ Yes, Save', style: TextStyle(color: Colors.white)),
onPressed: () {
if (_remarksMessageController.text.trim().isEmpty) return;
Navigator.pop(context);
_hantarResponVendorKePHP(temporaryStatusSelection, _remarksMessageController.text);
},
)
],
);
}
);
},
);
}

Color _getStatusColor(String status) {
if (status.toLowerCase() == 'closed') return const Color(0xFF2E9E52);
if (status.toLowerCase() == 'in_progress') return const Color(0xFFC9A227);
return const Color(0xFF2F5FA3);
}
Color _getStatusBg(String status) {
if (status.toLowerCase() == 'closed') return const Color(0xFFEAF7EE);
if (status.toLowerCase() == 'in_progress') return const Color(0xFFFFF8E6);
return const Color(0xFFEAF1FB);
}
Widget _buildSlaInfoColumn(String title, String mainValue, String desc, {bool isHighlight = false}) {
return SizedBox(
width: 110,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
const SizedBox(height: 4),
Text(mainValue, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isHighlight ? const Color(0xFFD64545) : AppColors.textPrimary)),
const SizedBox(height: 4),

Text(desc, style: const TextStyle(fontSize: 9, color: AppColors.textMuted, height: 1.3)),
],
),
);
}
Widget _buildSlaInfoSpacer() { return const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: SizedBox(height: 30, child: VerticalDivider(width: 1, color: AppColors.border))); }
Widget _buildEmptyFeedbackState() {
return _buildCentralizedFeedbackCard(title: "Customer Feedback", subtitle: "Awaiting feedback", icon: Icons.rate_review, iconColor: const Color(0xFFC9A227), iconBg: const Color(0xFFFFF8E6), bodyChild: _buildNoFeedbackPlaceholder(message: "The submitter hasn't submitted feedback for this ticket yet."));
}
Widget _buildLockedFeedbackState() {
return _buildCentralizedFeedbackCard(title: "Customer Feedback", subtitle: "Section Locked", icon: Icons.lock_outline, iconColor: const Color(0xFFD64545), iconBg: const Color(0xFFFDF2F2), bodyChild: _buildNoFeedbackPlaceholder(message: "This section is locked. Feedback tracking will open automatically once the ticket status is marked as Closed."));
}
Widget _buildCentralizedFeedbackCard({required String title, required String subtitle, required IconData icon, required Color iconColor, required Color iconBg, required Widget bodyChild}) {
return Container(
width: double.infinity, margin: const EdgeInsets.only(top: 2),
decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
child: Column(
mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(padding: const EdgeInsets.all(16.0), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: iconColor)), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)), Text(subtitle, style: TextStyle(fontSize: 10.5, color: iconColor, fontWeight: FontWeight.w600))],)])),
const Divider(height: 1, color: AppColors.border),
Padding(padding: const EdgeInsets.all(20.0), child: bodyChild),
],
),
);
}
Widget _buildNoFeedbackPlaceholder({required String message}) {
return Column(mainAxisSize: MainAxisSize.min, children: [const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => const Padding(padding: EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.star_border, color: Color(0xFFE5E7EB), size: 28)))), const SizedBox(height: 16), Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4)), const SizedBox(height: 10)]);
}
Widget _buildActiveFeedbackCard() {
int rating = _feedbackData?['rating'] ?? 5;
bool isAuto = _feedbackData?['is_auto_submitted'] == 1;
String dateStr = _feedbackData?['created_at'] ?? '—';
String satisfactionLabel = "Satisfied"; Color ratingColor = const Color(0xFF2E9E52); IconData satisfactionIcon = Icons.sentiment_satisfied;
if (rating == 5) { satisfactionLabel = "Very Satisfied"; satisfactionIcon = Icons.sentiment_very_satisfied; } else if (rating <= 2) { satisfactionLabel = "Dissatisfied"; ratingColor = const Color(0xFFD64545); satisfactionIcon = Icons.sentiment_very_dissatisfied; }
return Container(
width: double.infinity, margin: const EdgeInsets.only(top: 2),
decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
child: Column(
mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.all(16.0),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Row(
children: [
Container(
padding: const EdgeInsets.all(8),
decoration: const BoxDecoration(color: Color(0xFFEAF1FB), shape: BoxShape.circle),
child: const Icon(Icons.person_outline, size: 16, color: Color(0xFF2F5FA3))
),
const SizedBox(width: 12),
const Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Customer Feedback', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
Text('Submitted by complainant', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted))
],
),
],
),
Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
decoration: BoxDecoration(color: AppColors.pageBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
child: Text("$rating / 5", style: const TextStyle(color: AppColors.navy, fontSize: 11, fontWeight: FontWeight.bold)),
)
],
),
),
const Divider(height: 1, color: AppColors.border),
Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Icon(satisfactionIcon, color: ratingColor, size: 18),
const SizedBox(width: 6),
Text(satisfactionLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ratingColor)),
const SizedBox(width: 8),
Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
if (isAuto) ...[
const SizedBox(width: 8),
Container(
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
child: const Text("Auto", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
),
]
],
),
const SizedBox(height: 12),
Container(
width: double.infinity,
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(color: AppColors.fieldBackground, border: Border.all(color: AppColors.border.withOpacity(0.5)), borderRadius: BorderRadius.circular(8)),
child: Text(_feedbackData?['comment'] ?? 'No comment written.', style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4)),
),
const Divider(height: 24, color: AppColors.border),
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Row(children: List.generate(5, (index) => Icon(index < rating ? Icons.star : Icons.star_border, color: const Color(0xFFC9A227), size: 22))),
if (isAuto) const Text('Auto-submitted after 8 hrs', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic))
],
)
],
),
)
],
),
);
}
  @override
  Widget build(BuildContext context) {
    // =========================================================================
    // =========================================================================
    String jamDanMinitSlaLiveDipapar = "5h 0m 0s left";
    String dueTimeLiveTulenDipapar = "Calculating Due Time...";

    try {
      String waktuMulaSlaStr = '';

      if (_ticketLogs.isNotEmpty) {
        final logVendor = _ticketLogs.firstWhere(
              (log) => (log['reason'] ?? '').toString().toLowerCase().contains('vendor') ||
              (log['transferred_by_name'] ?? '').toString().toLowerCase().contains('system'),
          orElse: () => null,
        );
        if (logVendor != null && logVendor['transferred_at'] != null) {
          waktuMulaSlaStr = logVendor['transferred_at'].toString();
        }
      }

      if (waktuMulaSlaStr.isEmpty) {
        waktuMulaSlaStr = _slaData?['responded_at'] ?? _slaData?['submitted_at'] ?? '';
      }

      if (waktuMulaSlaStr.isEmpty) {
        waktuMulaSlaStr = _ticketData['created_at'] ?? '';
      }

      if (waktuMulaSlaStr.isNotEmpty && waktuMulaSlaStr.length >= 19) {
        // 🚀 LANGKAH 1: Potong teks string tulin Laragon (Format: YYYY-MM-DD HH:MM:SS)
        int year = int.parse(waktuMulaSlaStr.substring(0, 4));
        int month = int.parse(waktuMulaSlaStr.substring(5, 7));
        int day = int.parse(waktuMulaSlaStr.substring(8, 10));
        int hour = int.parse(waktuMulaSlaStr.substring(11, 13));
        int minute = int.parse(waktuMulaSlaStr.substring(14, 16));
        int second = int.parse(waktuMulaSlaStr.substring(17, 19));

        // 🚀 LANGKAH 2: Paksa bina objek DateTime berasaskan milisaat tulin UTC Malaysia (GMT+8)
        // dengan cara ini, peranti Emulator Amerika DIPAKSA membaca waktu ini sebagai waktu Malaysia!
        DateTime waktuMulaSlaTulen = DateTime.utc(year, month, day, hour, minute, second).subtract(const Duration(hours: 8));
        DateTime waktuMaksimumDeadlineSla = waktuMulaSlaTulen.add(const Duration(hours: 5));

        // 📅 FORMATTING DUE DATE UNTUK TAMPILAN BANNER KUNING ANDA MURNI
        List<String> senaraiBulan = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        DateTime waktuDisplayLokal = waktuMaksimumDeadlineSla.add(const Duration(hours: 8));
        String hariStr = waktuDisplayLokal.day.toString().padLeft(2, '0');
        String bulanStr = senaraiBulan[waktuDisplayLokal.month - 1];
        int hourRaw = waktuDisplayLokal.hour;
        String amPm = hourRaw >= 12 ? 'PM' : 'AM';
        int hourDisplay = hourRaw > 12 ? (hourRaw - 12) : (hourRaw == 0 ? 12 : hourRaw);
        String minitStr = waktuDisplayLokal.minute.toString().padLeft(2, '0');
        dueTimeLiveTulenDipapar = "$hariStr $bulanStr, $hourDisplay:$minitStr $amPm";

        // =========================================================================
        // Ambil jam laptop/sistem semasa dan paksa tukar ke UTC
        // Kita tolak milisaat tulin tanpa peduli timezone biul emulator Android!
        // =========================================================================
        DateTime sekarangUtc = DateTime.now().toUtc();

        // Kira baki jarak masa menggunakan kaedah pemotongan mutlak
        Duration bakiMasaDuration = waktuMaksimumDeadlineSla.difference(sekarangUtc);

        if (bakiMasaDuration.isNegative) {
          jamDanMinitSlaLiveDipapar = "0h 0m 0s left (BREACHED)";
        } else {
          int bakiJamDinamik = bakiMasaDuration.inHours;
          int bakiMinitDinamik = bakiMasaDuration.inMinutes % 60;

          jamDanMinitSlaLiveDipapar = "${bakiJamDinamik}h ${bakiMinitDinamik}m left";
        }
      }
    } catch (e) {
      jamDanMinitSlaLiveDipapar = _slaData?['time_left']?.toString() ?? "5h 0m 0s left";
      dueTimeLiveTulenDipapar = _slaData?['due_date']?.toString() ?? "07 Sep, 12:59 PM";
    }

    String title = _ticketData['title'] ?? 'No Title Specified';
    String statusLabel = (_selectedStatus ?? _ticketData['status'] ?? 'OPEN').toUpperCase();
String myDepartment = _ticketData['my_department'] ?? 'No Department';
String emailUser = _ticketData['submitter_email'] ?? 'No Email';
String description = _ticketData['description'] ?? 'No description text.';
String dateCreated = _ticketData['created_at'] ?? 'No Date';
return DefaultTabController(
length: 3,
child: Builder(
builder: (BuildContext context) {
return Scaffold(
backgroundColor: AppColors.pageBackground,
appBar: AppBar(
backgroundColor: Colors.white,
elevation: 0,
automaticallyImplyLeading: true,
leading: IconButton(
icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy, size: 18),
onPressed: () => Navigator.pop(context, true),
),
title: const Text('Vendor Work Order Workspace', style: TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w700)),
),
body: SafeArea(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
StatusTag(label: statusLabel.replaceAll('', ' '), background: _getStatusBg(statusLabel), foreground: _getStatusColor(statusLabel)),
],
),
const SizedBox(height: 2),
Text(_currentTicketId, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
const SizedBox(height: 14),
  // =========================================================================
  // SUNTIKAN MUKTAMAD KEMENANGAN: KUNCI MATI TABBAR + AUTO-SNACKBAR RALAT
  // =========================================================================
  TabBar(
    labelColor: AppColors.navy,
    unselectedLabelColor: AppColors.textSecondary,
    indicatorColor: AppColors.navy,
    indicatorWeight: 2.5,
    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    onTap: (index) {
      if (index == 2 &&
          _selectedStatus != 'Closed' &&
          _ticketData['status'].toString().toUpperCase().trim() != 'CLOSED') {

         DefaultTabController.of(context).animateTo(0);

         ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Section Locked! Feedback tracking will open automatically once the ticket is Closed.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    },
    tabs: [
      const Tab(text: 'Detail'),
      const Tab(text: 'History 🕒'),
      Tab(
        child: Text(
            (statusLabel.toString().toUpperCase().trim() == 'CLOSED' ||
                _ticketData['status'].toString().toUpperCase().trim() == 'CLOSED')
                ? 'Feedback 💬'
                : 'Feedback 🔒'
        ),
      ),
    ],
  ),
],
),
),
Expanded(
child: TabBarView(
children: [
// ==================== 📝 TAB 1: DETAILS ====================
ListView(
padding: const EdgeInsets.symmetric(horizontal: 16),
  children: [
   (() {
      _ticketData['is_saved_secure'] = (_ticketData['real_save_date_time'] != null ||
          (_ticketData['handled_by_vendor_staff_id'] != null &&
              _ticketData['handled_by_vendor_staff_id'].toString() != '0' &&
              _ticketData['handled_by_vendor_staff_id'].toString() != 'null'));
      return const SizedBox.shrink();
    })(),

    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ticket Information', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Divider(height: 20, color: AppColors.border),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.fieldBackground, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
            child: Wrap(
              spacing: 20, runSpacing: 14,
              children: [
                ReviewField(label: 'From Department', value: myDepartment),
                ReviewField(label: 'Category', value: title),
                ReviewField(label: 'Priority', value: _selectedPriority),
                ReviewField(label: 'Status', value: statusLabel.replaceAll('', ' ')),
                ReviewField(label: 'Submitted Date', value: dateCreated),
                ReviewField(label: 'Last Update', value: _lastUpdatedText),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.fieldBackground, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
            child: Text(description, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4)),
          ),
        ],
      ),
    ),
    const SizedBox(height: 14),

    // KOTAK PUTIH KIRI: SLA STATUS TOTAL STOPPED
    _slaData == null
        ? const Padding(
      padding: EdgeInsets.all(20.0),
      child: Center(child: SizedBox(height: 16, width: 14, child: CircularProgressIndicator(strokeWidth: 2))),
    )
        : Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFEAF7EE), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.access_time, size: 16, color: Color(0xFF2E9E52))),
              const SizedBox(width: 10),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('SLA Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)), Text('8 hrs · Mon–Fri 08:00–17:00', style: TextStyle(fontSize: 10, color: AppColors.textMuted))]),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFEAF7EE), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2E9E52))),
                const SizedBox(width: 6),
                Text(_slaData?['admin_sla_status']?.toString() ?? "SLA Stopped", style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2E9E52))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: double.parse((_slaData?['admin_progress'] ?? 0.0).toString()), backgroundColor: AppColors.pageBackground, valueColor: const AlwaysStoppedAnimation(Color(0xFF2E9E52)), minHeight: 6, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSlaInfoColumn("SUBMITTED", _slaData?['submitted_at'] ?? '—', "Ticket submission\ndate & time"),
                _buildSlaInfoSpacer(),
                _buildSlaInfoColumn("TIME USED", _slaData?['admin_time_used']?.toString() ?? "0h m used", "Working hours", isHighlight: true),
                _buildSlaInfoSpacer(),
                _buildSlaInfoColumn("RESPONDED AT", _slaData?['responded_at'] ?? '—', "Staff responded time"),
              ],
            ),
          )
        ],
      ),
    ),
    const SizedBox(height: 14),
  // =========================================================================
  Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(children: const [Icon(Icons.update_outlined, color: AppColors.navy, size: 16), SizedBox(width: 8), Text('Update Ticket', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary))]),
  const Divider(height: 20, color: AppColors.border),

  // 🟡🟢 1. BANNER ALERT VENDOR RESPONSE (HIJAU / KUNING DINAMIK)
  (() {
    //  cari bukti konkrit 'HANDLED BY: 👤' dalam sejarah !
    bool adakahVendorDahResponDatabaseLive = _ticketLogs.any((log) =>
        (log['reason'] ?? '').toString().toUpperCase().contains('HANDLED BY: 👤')) || _isLockedAfterSave;

    if (adakahVendorDahResponDatabaseLive || statusLabel == 'CLOSED') {
  return Container(
  width: double.infinity, padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(color: const Color(0xFFEAF7EE), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF2E9E52).withValues(alpha: 0.25))),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const Text('VENDOR RESPONSE', style: TextStyle(fontSize: 9, color: Colors.grey, letterSpacing: 0.8)),
  const SizedBox(height: 6),
  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(4)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle, size: 11, color: Color(0xFF2E9E52)), SizedBox(width: 4), Text('Vendor responded', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF2E9E52)))])),
  const SizedBox(height: 8),
  //  Cari ulasan "Responded in..." dari table logs secara live!
  Text("Responded in ${(() {
    String masaDitemui = '1m';
    if (_ticketLogs.isNotEmpty) {
      try {
        final logProgress = _ticketLogs.firstWhere(
              (log) => (log['remarks'] ?? '').toString().toLowerCase().contains('responded in') &&
              (log['new_status'] ?? '').toString().toLowerCase().trim() == 'in_progress',
          orElse: () => null,
        );
        if (logProgress != null && logProgress['remarks'] != null) {
          masaDitemui = logProgress['remarks'].toString().toLowerCase().replaceAll('responded in', '').trim();
        }
      } catch (e) {}
    }
    return masaDitemui;
  })()} · ${_ticketData['real_save_date_time'] ?? _lastUpdatedText}", style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
  const SizedBox(height: 4),
  Text('Sent to vendor ${_slaData?['responded_at'] ?? '02 Sep 2026, 2:20 PM'} · 5 working hours to respond', style: const TextStyle(fontSize: 10, color: Colors.grey)),
  ],
  ),
  );
  } else {
  return Container(
  width: double.infinity, padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(color: const Color(0xFFFFF8E6), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFC9A227).withValues(alpha: 0.25))),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const Text('VENDOR RESPONSE', style: TextStyle(fontSize: 9, color: Colors.grey, letterSpacing: 0.8)),
  const SizedBox(height: 6),
  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: const BoxDecoration(color: Color(0xFFFFF1D2), borderRadius: BorderRadius.all(Radius.circular(4))), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.hourglass_empty, size: 10, color: Color(0xFFC9A227)), SizedBox(width: 4), Text('Awaiting vendor response', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFC9A227)))])),
  const SizedBox(height: 8),
  Row(children: [Expanded(child: Text("$jamDanMinitSlaLiveDipapar · due $dueTimeLiveTulenDipapar", style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis))]),
  const SizedBox(height: 4),
  Text('Sent to vendor ${_slaData?['responded_at'] ?? '02 Sep 2026, 2:20 PM'} · 5 working hours to respond', style: const TextStyle(fontSize: 10, color: Colors.grey)),
  ],
  ),
  );
  }
  })(),

  // 👤 2. PANEL HANDLED BY STAF VENDOR
  if (_ticketData['status'].toString().toUpperCase() != 'CLOSED') ...[
  const SizedBox(height: 16),
  const Text('HANDLED BY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
  const SizedBox(height: 6),
  Material(
  color: Colors.transparent,
  child: Container(
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
  child: _senaraiStaffVendorLiveDB.isEmpty
  ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text("Loading fresh vendor staff from database...", style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic))))
      : Column(
  children: _senaraiStaffVendorLiveDB.map((staff) {
  int currentStaffIdFromDB = int.parse(staff['staff_id'].toString());
  String namaStaffDB = (staff['full_name'] ?? 'Vendor Support').toString();
  String perananStaffDB = (staff['role'] ?? 'Technician').toString();

  return Column(
  mainAxisSize: MainAxisSize.min,
  children: [
  RadioListTile<int>(
  title: Text(namaStaffDB, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
  subtitle: Text(perananStaffDB, style: const TextStyle(fontSize: 10)),
  value: currentStaffIdFromDB,
  groupValue: _selectedStaffId,
  activeColor: AppColors.navy,
  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
    onChanged: (_ticketData['status'].toString().toUpperCase() == 'CLOSED')
        ? null
        : (int? val) {
      if (val != null) {
        setState(() {
          _selectedStaffId = val; // Hanya tukar bulatan biru visual tanpa hantar data/pop-up!
        });
      }
    },
    // =========================================================================
  ),
    if (staff != _senaraiStaffVendorLiveDB.last) const Divider(height: 1, color: AppColors.border),
  ],
  );
  }).toList(),
  ),
  ),
  ),
  ],

  // 🔄 3. PAPARAN STATUS (Hanya muncul jika tiket sudah CLOSED !)
  if (_ticketData['status'].toString().toUpperCase() == 'CLOSED') ...[
    const SizedBox(height: 16),
    const Text('STATUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
    const SizedBox(height: 6),
    Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: const Text('Closed', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
    ),
  ],

  // 💬 4. PANEL KOTAK MENAIP RESPOND TO SUBMITTER
  if (_ticketData['status'].toString().toUpperCase() != 'CLOSED') ...[
  const SizedBox(height: 16),
  const Text(
  'RESPOND TO SUBMITTER',
  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
  ),
  const SizedBox(height: 6),
  TextField(
  controller: _remarksMessageController,
  maxLines: 2,
  style: const TextStyle(fontSize: 12),
  decoration: InputDecoration(
  hintText: '...',
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  filled: true, fillColor: Colors.white,
  ),
  ),
  ],
  const SizedBox(height: 16),
// =========================================================================
// ULTIMATE BOX CHALENGE: LOCK RESPOND TEXT TO TICKET_REPLIES
// =========================================================================
    (() {
       bool sudahHantarResponPertama = _ticketLogs.any((log) =>
          (log['reason'] ?? '').toString().toUpperCase().contains('HANDLED BY: 👤')) || _isLockedAfterSave;

      if (_ticketData['status'].toString().toUpperCase() == 'CLOSED') {
        return const SizedBox.shrink();
      }

      return _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F52BA),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          ),
          onPressed: () {
            String teksUlasanVendorSejati = _remarksMessageController.text.trim();

            if (teksUlasanVendorSejati.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text('Error: Please enter a message in the Respond to Submitter box! '),
                ),
              );
              return;
            }

            String statusDihantar = sudahHantarResponPertama ? 'Closed' : 'In Progress';

            if (!sudahHantarResponPertama) {
              int targetStaffIdToSave = _selectedStaffId ?? 102;
              setState(() {
                _ticketData['handled_by_vendor_staff_id'] = targetStaffIdToSave;
              });
              _hantarResponVendorKePHP(statusDihantar, teksUlasanVendorSejati);
            } else {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Color(0xFFEAF1FB), shape: BoxShape.circle),
                          child: const Icon(Icons.check_circle_outline, color: Color(0xFF2E9E52), size: 28),
                        ),
                        const SizedBox(height: 16),
                        const Text('Close this Ticket?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        const Text('Confirm that you have completed the task and want to close this ticket murni.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                        const SizedBox(height: 20),
                      ],
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
                            child: const Text('✓ Yes, Close', style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              Navigator.pop(context);
                              _hantarResponVendorKePHP(statusDihantar, teksUlasanVendorSejati);
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            }
          },
          child: Text(
              sudahHantarResponPertama ? '✓ Close Ticket' : 'Send Response',
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)
          ),
        ),
      );
    })(),
// =========================================================================

  ],
  ),
  ),
  const SizedBox(height: 20),
  ],
),

// ==================== 🕒 TAB 2: HISTORY ====================
ListView(
padding: const EdgeInsets.symmetric(horizontal: 16),
children: [
Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text("Change History", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
const SizedBox(height: 4),
Text("${_ticketLogs.length} changes recorded for this ticket", style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
const Divider(height: 24, color: AppColors.border),
_ticketLogs.isEmpty
? const Padding(
padding: EdgeInsets.symmetric(vertical: 20),
child: Center(child: Text("No history log available.", style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
)
    : Column(
children: List.generate(_ticketLogs.length, (index) {
final log = _ticketLogs[index];
if (log['is_hidden'] == true || log['is_hidden'] == 1) return const SizedBox.shrink();

String namaAktor = log['transferred_by_name'] ?? 'SYSTEM';
String deskripsi = log['reason'] ?? 'Activity logged.';
String tarikhLog = log['transferred_at'] ?? '';
bool isStatusChange = deskripsi.toLowerCase().contains('status');
if (tarikhLog.length > 16) {
tarikhLog = tarikhLog.substring(11, 16) + " " + tarikhLog.substring(8, 10) + "/" + tarikhLog.substring(5, 7) + "/" + tarikhLog.substring(0, 4) ;
}
return _buildHistoryItem(namaAktor, tarikhLog, deskripsi, isStatusChange, isLast: index == _ticketLogs.length - 1);
}),
),
],
),
)
],
),
// ==================== 💬 TAB 3: FEEDBACK ====================
  SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _isFeedbackLoading
            ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            : (statusLabel.toString().toUpperCase().trim() != 'CLOSED' &&
            _ticketData['status'].toString().toUpperCase().trim() != 'CLOSED') // HURUF BESAR: Kalis ralat string huruf kecil database!
            ? _buildLockedFeedbackState() // Jika open / in_progress, paksa tunjuk kad locked!
            : (_feedbackData == null || _feedbackData?['status'] == 'kosong' || _feedbackData?['comment'] == null)
            ? _buildEmptyFeedbackState() // Jika closed tapi student belum isi rating murni anda
            : _buildActiveFeedbackCard(), // Jika closed and data rating tulin dah wujud makmur dari student!
        const SizedBox(height: 40),
      ],
    ),
  ),
],
),
),
],
),
),
);
},
),
);
}
}
Widget _buildHistoryItem(String name, String time, String action, bool isStatusChange, {bool isLast = false}) {
return Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Column(
children: [
Container(
width: 18, height: 18,
decoration: BoxDecoration(
color: isStatusChange ? const Color(0xFFFFF8E6) : const Color(0xFFEAF1FB),
shape: BoxShape.circle,
border: Border.all(color: isStatusChange ? const Color(0xFFC9A227) : const Color(0xFF2F5FA3), width: 1.5)
),
child: Icon(isStatusChange ? Icons.star : Icons.person, size: 10, color: isStatusChange ? const Color(0xFFC9A227) : const Color(0xFF2F5FA3)),
),
if (!isLast) Container(width: 1.5, height: 44, color: Colors.grey.shade200),
],
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
const SizedBox(width: 6),
Text("• $time", style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
],
),
const SizedBox(height: 4),
Text(action, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
const SizedBox(height: 12),
],
),
)
],
);
}


