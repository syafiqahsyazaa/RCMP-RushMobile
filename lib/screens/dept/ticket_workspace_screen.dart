import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../main.dart';

class TicketWorkspaceScreen extends StatefulWidget {
  const TicketWorkspaceScreen({super.key});

  @override
  State<TicketWorkspaceScreen> createState() => _TicketWorkspaceScreenState();
}

class _TicketWorkspaceScreenState extends State<TicketWorkspaceScreen> {
  bool _isInitialized = false;
  bool _isSaving = false;

// Variabel pengurusan data tiket
  String _currentTicketId = '';
  String _selectedPriority = 'Medium';
  String? _selectedStatus;
  String _lastUpdatedText = 'No Date';

  List<String> _listStaff = [];
  String? _selectedStaff;

// Pemegang data syarikat vendor yang active!
  List<dynamic> _senaraiActiveVendorsDropdown = [];

// Pemegang jenis data dynamic agar kalis pertembungan Staff vs Vendor ID
  dynamic _selectedAssignedEntityValue;
  bool _isAssignedToVendorLive = false;
  String _assignedVendorNameLive = '';

  final List<String> _statusOptions = ['Open', 'In Progress', 'Closed'];
  Map<String, dynamic> _ticketData = {};
  Map<String, dynamic>? _slaData;

  Map<String, dynamic>? _feedbackData;
  bool _isFeedbackLoading = true;

  List<dynamic> _ticketLogs = [];

// Pemegang nama staff live peribadi dari session global
  String _namaStaffLive = "";
  String _jabatanStaffSesiLive = ""; //Untuk filter vendor ikut jabatan login

  final TextEditingController _remarksMessageController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _ambilDataStaff();
  }

  @override
  void dispose() {
    _remarksMessageController.dispose();
    super.dispose();
  }

// =========================================================================
//  ASYNC DATA TRACKER
//  Menyusun semula urutan fetch! Log dikunci dulu baru skrin di-render!
// =========================================================================
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _ticketData = args;
        _currentTicketId = args['ticket_id'] ?? '';
        _ticketData['description'] =
            args['description'] ?? 'No description text provided.';

        _namaStaffLive =
            (args['full_name'] ?? args['name'] ?? 'name').toString().trim();

        _tarikActiveVendorsDropdownDariPHP();

        String savedStaffName = args['remarks'] ?? '';
        _selectedStaff = savedStaffName.isNotEmpty ? savedStaffName : 'Name';
        _selectedAssignedEntityValue = _selectedStaff;

        if (args['assigned_vendor_id'] != null &&
            args['assigned_vendor_id'].toString() != '0' &&
            args['assigned_vendor_id'].toString() != 'null') {
          _isAssignedToVendorLive = true;
          _selectedAssignedEntityValue =
              "vendor${args['assigned_vendor_id']}".toString().trim();
          _assignedVendorNameLive = args['assigned_vendor_name'] ??
              args['remarks'] ??
              'Vendor Account';
        } else if (savedStaffName.toLowerCase().startsWith('vendor') ||
            savedStaffName.toLowerCase().contains('sdn') ||
            savedStaffName.toLowerCase().contains('bhd') ||
            savedStaffName.toLowerCase().contains('snd')) {
          _isAssignedToVendorLive = true;
          _assignedVendorNameLive =
              args['assigned_vendor_name'] ?? savedStaffName;
          _selectedAssignedEntityValue = savedStaffName;
        }

        String? dbUpdatedAt = args['updated_at'];
        if (dbUpdatedAt != null &&
            dbUpdatedAt.isNotEmpty &&
            dbUpdatedAt != "null") {
          _lastUpdatedText = dbUpdatedAt;
        } else {
          _lastUpdatedText = args['created_at'] ?? 'No Date';
        }

        String rawPriority = (args['priority'] ?? 'Medium').toString();
        if (rawPriority.isNotEmpty) {
          _selectedPriority = rawPriority.substring(0, 1).toUpperCase() +
              rawPriority.substring(1).toLowerCase();
        }

        String rawStatus = (args['status'] ?? 'open').toString().toLowerCase();
        if (rawStatus == 'open') _selectedStatus = 'Open';
        if (rawStatus == 'in_progress') _selectedStatus = 'In Progress';
        if (rawStatus == 'closed') _selectedStatus = 'Closed';

        // PERISAI KEMENANGAN : Kita paksa heret logs and dropdown dulu berkembar!
        _ambilNamaStaffTulen().then((_) {
          _tarikActiveVendorsDropdownDariPHP().then((_) {
            // SUNTIKAN UTAMA: Ambil log history rincian chat dlu biar masuk RAM memori!
            _ambilSejarahAktivitiTiket(_currentTicketId).then((_) {
              // Bila logs and replies dah selamat mendarat dalam RAM, barulah fresh data complaints disedut
              _ambilDataTiketTerbaharu();
            });
          });
        });

        _ambilStatusSLA(_currentTicketId);
        _ambilFeedbackTiket(_currentTicketId);
        _ambilDataStaff();
      }
      _isInitialized = true;
    }
  }
// =========================================================================

  Future<void> _ambilNamaStaffTulen() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_user.php?email=$currentLoggedInUserEmail');
    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final Map<String, dynamic> hasil = json.decode(respon.body);
        if (hasil['status'] == 'wujud') {
          setState(() {
            _namaStaffLive = (hasil['data']['full_name'] ?? _namaStaffLive)
                .toString()
                .trim();
            _jabatanStaffSesiLive = (hasil['data']['department_name'] ??
                    hasil['data']['department'] ??
                    "")
                .toString()
                .trim();
          });
          print(
              "🔎 SESSION IDENTIFIED: User $_namaStaffLive from $_jabatanStaffSesiLive");
          _tarikActiveVendorsDropdownDariPHP();
        }
      }
    } catch (e) {
      print("Error fetch name: $e");
    }
  }

// =========================================================================
// 🚀 FIX ULTRA MULTI-PORTAL STAFF: GEMBOK KOTAK KUNING BERDASARKAN REAL-TIME REFRESH DATA 🚀
// 100% Menghancurkan ralat data argument null dari skrin staff, kotak kuning dijamin menyala tegar!
// =========================================================================
  Future<void> _ambilDataTiketTerbaharu() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_my_complaints.php?ticket_id=$_currentTicketId&b_cache=${DateTime.now().millisecondsSinceEpoch}');

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

            _ticketData['real_minutes_used'] = freshData['real_minutes_used'] ??
                freshData['minutes_used'] ??
                '13h 44m';
            _ticketData['real_save_date_time'] =
                freshData['real_save_date_time'] ??
                    freshData['updated_at'] ??
                    'Just Now';

            String dbStatusRaw = (_ticketData['status'] ?? 'open')
                .toString()
                .toLowerCase()
                .trim();
            if (dbStatusRaw == 'open') _selectedStatus = 'Open';
            if (dbStatusRaw == 'in_progress') _selectedStatus = 'In Progress';
            if (dbStatusRaw == 'closed') _selectedStatus = 'Closed';

            bool adakahVendorDahResponTulen = _ticketLogs.any((log) {
              String reasonLog = (log['reason'] ?? '').toString().toLowerCase();
              return reasonLog.contains('handled by:');
            });

            // ambil semua jenis key string dari database fresh, kalis argument null staff!
            String vId = (_ticketData['assigned_vendor_id'] ?? '0').toString();
            String remarksText =
                (_ticketData['remarks'] ?? '').toString().toLowerCase().trim();
            String vendorNameText = (_ticketData['assigned_vendor_name'] ?? '')
                .toString()
                .toLowerCase()
                .trim();

            // Jika dikesan mengandungi data vendor, KOTAK KUNING WAJIB NYALA TRUE!
            if ((vId != '0' && vId != 'null') ||
                remarksText.contains('vendor') ||
                remarksText.contains('sdn') ||
                remarksText.contains('bhd') ||
                remarksText.contains('itdeptvendor') ||
                vendorNameText.contains('vendor') ||
                vendorNameText.contains('sdn') ||
                vendorNameText.contains('bhd') ||
                vendorNameText.contains('itdeptvendor')) {
              // Paksa gembok status menjadi TRUE tanpa kompromi!
              _isAssignedToVendorLive = true;

              String namaSyarikatMentah = _ticketData['assigned_vendor_name'] ??
                  _ticketData['remarks'] ??
                  'ITDEPTVENDOR';
              _assignedVendorNameLive = namaSyarikatMentah.toString().trim();
              _selectedAssignedEntityValue = _assignedVendorNameLive;

              // Sinkronisasi pemetaan nilai dropdown list menu
              if (_senaraiActiveVendorsDropdown.isNotEmpty) {
                final matchDropdown = _senaraiActiveVendorsDropdown.firstWhere(
                  (v) =>
                      (v['company_name'] ?? '')
                          .toString()
                          .trim()
                          .toLowerCase() ==
                      _assignedVendorNameLive.toLowerCase(),
                  orElse: () => null,
                );
                if (matchDropdown != null) {
                  _selectedAssignedEntityValue =
                      matchDropdown['company_name'].toString().trim();
                }
              }
            } else {
              // Jika ia balik kepada tugasan staff internal biasa anda
              _isAssignedToVendorLive = false;
              _selectedStaff = _ticketData['remarks'] ?? 'Help Desk Support';
              _selectedAssignedEntityValue = _selectedStaff;
            }
          });
          print(
              "✅ STAFF-ADMIN SHARE WORKSPACE DATA LOCKED: Vendor Box Status = $_isAssignedToVendorLive");
        }
      }
    } catch (e) {
      print("Error sync data tiket shared workspace staff side: $e");
    }
  }

  // =========================================================================
  // VENDOR DROPDOWN MULTI-JABATAN: SEJATI COMPLAINTS DEPT LOCK ENGINE 🏢
  Future<void> _tarikActiveVendorsDropdownDariPHP() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';

    //  KUNCI MATI DYNAMIC JABATAN ADMIN
    // ambil info data kuncian real-time. Kita semak id nombor dept_id tiket complaints dulu!
    String targetDeptRaw = "";

    // Imbas dynamic id pangkalan data complaints untuk kunci mati nama jabatan pengendali  anda
    String ticketDeptId = (_ticketData['dept_id'] ?? '0').toString().trim();

    if (ticketDeptId == '1') {
      targetDeptRaw = "Administration & Facilities Management Department";
    } else if (ticketDeptId == '2') {
      targetDeptRaw = "Maintenance Department";
    } else if (ticketDeptId == '4') {
      targetDeptRaw = "Information Technology Department";
    } else if (ticketDeptId == '5') {
      targetDeptRaw = "Human Capital Department";
    } else if (ticketDeptId == '3') {
      targetDeptRaw = "Corporate Communication Unit";
    }

    // Backup carian jika dept_id null / kosong lewat global session tracker
    if (targetDeptRaw.isEmpty) {
      targetDeptRaw = _jabatanStaffSesiLive.trim();
    }

    if (targetDeptRaw.isEmpty) {
      targetDeptRaw = (_ticketData['department_label'] ??
              _ticketData['department_name'] ??
              _ticketData['department'] ??
              '')
          .toString()
          .trim();
    }

    // Jika data masih kosong , baru fallback terpaksa ke Administration
    if (targetDeptRaw.isEmpty) {
      targetDeptRaw = 'Administration & Facilities Management Department';
    }

    String finalCleanDeptKeyword = targetDeptRaw;

    //  LITAR PENCANTAS AGUNG CASE-INSENSITIVE
    String lowerDept = targetDeptRaw.toLowerCase();
    if (lowerDept.contains('administration') ||
        lowerDept.contains('facilities') ||
        lowerDept.contains('afsmd')) {
      finalCleanDeptKeyword =
          "Administration & Facilities Management Department";
    } else if (lowerDept.contains('maintenance')) {
      finalCleanDeptKeyword = "Maintenance Department";
    } else if (lowerDept.contains('it') ||
        lowerDept.contains('information technology') ||
        lowerDept.contains('dept/')) {
      finalCleanDeptKeyword = "Information Technology Department";
    } else if (lowerDept.contains('human capital') ||
        lowerDept.contains('hcd')) {
      finalCleanDeptKeyword = "Human Capital Department";
    } else if (lowerDept.contains('corporate communication') ||
        lowerDept.contains('ccu')) {
      finalCleanDeptKeyword = "Corporate Communication Unit";
    }

    print(
        "🎯 DYNAMIC TARGET ENJIN DROPDOWN LOCKED FOR DEPT: [$finalCleanDeptKeyword] (Complaints Dept ID: $ticketDeptId)");

    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_active_vendors_dropdown.php?department=${Uri.encodeComponent(finalCleanDeptKeyword)}&b_cache=${DateTime.now().millisecondsSinceEpoch}');

    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        List<dynamic> hasilRespon = json.decode(respon.body);
        setState(() {
          _senaraiActiveVendorsDropdown = hasilRespon;
        });
        print(
            "SUCCESS DISPATCH DROPDOWN LOADED: ${_senaraiActiveVendorsDropdown.length} vendor items allocated for [$finalCleanDeptKeyword]");
      }
    } catch (e) {
      print("Error sedut dropdown vendor dynamic multi-jabatan: $e");
    }
  }

  Future<void> _ambilSejarahAktivitiTiket(String idTiket) async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_ticket_history.php?ticket_id=$idTiket');
    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final List<dynamic> data = json.decode(respon.body);
        setState(() {
          _ticketLogs = data;
        });
      }
    } catch (e) {
      print("Ralat menarik sejarah aktiviti tiket: $e");
    }
  }

  Future<void> _ambilFeedbackTiket(String idTiket) async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_ticket_feedback.php?ticket_id=$idTiket');
    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        setState(() {
          _feedbackData = json.decode(respon.body);
          _isFeedbackLoading = false;
        });
      }
    } catch (e) {
      print("Ralat feedback: $e");
      setState(() => _isFeedbackLoading = false);
    }
  }

  // =========================================================================
  //  STAFF DROPDOWN MUKTAMAD: TAPIS SECARA MANUAL BERASASKAN STRING JABATAN
  //  nama staff IT gerenti dari Maintenance!
  // =========================================================================
  Future<void> _ambilDataStaff() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    // Use dynamic global email instead of hardcoded one!
    final String emelStaffSemasa = currentLoggedInUserEmail;

    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_staff_members.php?email=$emelStaffSemasa&ticket_id=$_currentTicketId&b_cache=${DateTime.now().millisecondsSinceEpoch}');

    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final List<dynamic> data = json.decode(respon.body);
        setState(() {
          _listStaff = List<String>.from(data);
        });
      }
    } catch (e) {
      print("Ralat mengambil nama staff: $e");
    }
  }

  Future<void> _ambilStatusSLA(String idTiket) async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_sla_status.php?ticket_id=$idTiket');
    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        setState(() {
          _slaData = json.decode(respon.body);
        });
      }
    } catch (e) {
      print("Ralat mengambil data SLA: $e");
    }
  }

  Future<void> _hantarKemasKiniStatusKePHP({
    required String status,
    required String priority,
    required String staff,
    required String remarks,
  }) async {
    setState(() => _isSaving = true);
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url =
        Uri.parse('http://$domain/helpdesk_api/update_ticket_status.php');

    String? finalVendorId;
    String targetStaffNameToSave = staff;

    // =========================================================================
    // ambil VENDOR_ID BERDASARKAN COMPANY_NAME DROPDOWN
    // =========================================================================
    if (_selectedAssignedEntityValue != null) {
      String entitiDipilihLive = _selectedAssignedEntityValue.toString().trim();

      //  semak jika nilai dropdown yang dipilih adalah sepadan dengan mana-mana company_name di list vendor
      if (_senaraiActiveVendorsDropdown.isNotEmpty) {
        final padananVendorDariNamaSyarikat =
            _senaraiActiveVendorsDropdown.firstWhere(
          (v) =>
              (v['company_name'] ?? '').toString().trim().toLowerCase() ==
              entitiDipilihLive.toLowerCase(),
          orElse: () => null,
        );

        if (padananVendorDariNamaSyarikat != null) {
          //  ambil token ID nombor vendor tulin dari database
          finalVendorId = (padananVendorDariNamaSyarikat['vendor_id'] ??
                  padananVendorDariNamaSyarikat['id'] ??
                  '0')
              .toString()
              .trim();

          // Setkan data string format simpanan text database complaints
          targetStaffNameToSave =
              entitiDipilihLive; // Menyimpan string nama "SYA and bhd" ke remarks/staff
        }
      }
    }
    // =========================================================================

    try {
      final respon = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "ticket_id": _currentTicketId,
          "status": status.toLowerCase().replaceAll(' ', '_'),
          "priority": priority.toLowerCase(),
          "assigned_staff": targetStaffNameToSave, // Kirim nama syarikat
          "remarks_message": remarks.trim(),
          'updated_by_email': currentLoggedInUserEmail,
          "vendor_id":
              finalVendorId, // Kirim id nombor yang sah ke PHP Laragon!
        }),
      );

      if (respon.statusCode == 200) {
        final Map<String, dynamic> hasil = json.decode(respon.body);
        if (hasil['status'] == 'berjaya') {
          if (mounted) {
            _remarksMessageController.clear();
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(hasil['mesej'])));
            setState(() {
              _lastUpdatedText =
                  hasil['updated_at'] ?? DateTime.now().toString();
              _selectedStaff = staff;
              _selectedAssignedEntityValue = staff;
//Kemas kini status dalam database
              _ticketData['status'] = status;

              if (finalVendorId != null) {
                _isAssignedToVendorLive = true;
              } else {
                _isAssignedToVendorLive = false;
              }
            });
            _ambilSejarahAktivitiTiket(_currentTicketId);
            _ambilStatusSLA(_currentTicketId);
            _ambilFeedbackTiket(_currentTicketId);
          }
        } else {
          _tampilMesej(hasil['mesej'] ?? "Gagal menyimpan .");
        }
      }
    } catch (e) {
      _tampilMesej("Ralat Sambungan Laragon: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // =========================================================================
  // VALIDASI: SUNTIK NAMA VALIDASI DYNAMIC SESSION USER
  // =========================================================================
  void _semakSyaratSebelumSimpanNormal() {
    String targetStaff = _selectedAssignedEntityValue != null &&
            !_selectedAssignedEntityValue.toString().startsWith("vendor")
        ? _selectedAssignedEntityValue.toString()
        : (_namaStaffLive.isNotEmpty ? _namaStaffLive : 'Help Desk Support');

    String statusAsalDatabase =
        (_ticketData['status'] ?? 'open').toString().toLowerCase().trim();
    String statusBaruPilihan = (_selectedStatus ?? 'Open').toLowerCase().trim();

    //  REASSIGN: Semak kalau ada perubahan Assignee (Staff/Vendor)
    String assigneeAsalDatabase = (_selectedStaff ?? '').toString().trim();
    String assigneeBaruPilihan =
        (_selectedAssignedEntityValue ?? '').toString().trim();

    bool adakahStatusBerubah = statusBaruPilihan != statusAsalDatabase;
    bool adakahAssigneeBerubah = assigneeBaruPilihan != assigneeAsalDatabase;

    if (adakahStatusBerubah || adakahAssigneeBerubah) {
      Color warnaButangPopUp = AppColors.navy;

      String tajukDialog = '⚙️ Status Update Reason';
      String hintDialog =
          'Enter status update note (e.g., Attending to site issue)...';

      if (statusBaruPilihan == 'closed') {
        warnaButangPopUp = Colors.green;
        tajukDialog = '🚨 Closing Resolution Note';
        hintDialog =
            'Enter resolution note (e.g., Issue fixed successfully)...';
      } else if (adakahAssigneeBerubah) {
        warnaButangPopUp = Colors.purple;
        tajukDialog = '🔄 Reassignment Reason';
        hintDialog = 'Enter reason for reassigning this ticket...';
      }

      _pamerDialogRemarksPaksaan(
          tajuk: tajukDialog,
          hint: hintDialog,
          warnaButang: warnaButangPopUp,
          onConfirm: (textUlasan) {
            _hantarKemasKiniStatusKePHP(
              status: _selectedStatus!,
              priority: _selectedPriority,
              staff: targetStaff,
              remarks: textUlasan,
            );
          });
    } else {
      _hantarKemasKiniStatusKePHP(
        status: _selectedStatus ?? 'Open',
        priority: _selectedPriority,
        staff: targetStaff,
        remarks: _remarksMessageController.text,
      );
    }
  }

  void _pamerDialogRemarksPaksaan(
      {required String tajuk,
      required String hint,
      required Color warnaButang,
      required Function(String) onConfirm,
      VoidCallback? onCancel}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final TextEditingController _popupInputController =
            TextEditingController();
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(tajuk,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _popupInputController,
            decoration: InputDecoration(
                hintText: hint, hintStyle: const TextStyle(fontSize: 12)),
          ),
          actions: [
            TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  if (onCancel != null) onCancel();
                  Navigator.pop(context);
                }),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: warnaButang),
              child: const Text('Confirm & Save',
                  style: TextStyle(color: Colors.white)),
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

// =========================================================================
// PROSES SIMPAN TERUS DARI KLIK KAD STATUS
// =========================================================================
  void _prosesSimpanTerusDariStatus(String statusPilihan) {
    // 🌟simpan status lama untuk tujuan patah balik undo
    final String? statusLamaSesi = _selectedStatus;

    // Ubah secara temporary untuk feedback visual
    setState(() {
      _selectedStatus = statusPilihan;
    });

    // Auto-refresh vendor list jika status bertukar In Progress
    _tarikActiveVendorsDropdownDariPHP();

    String targetStaff = _selectedAssignedEntityValue != null &&
            !_selectedAssignedEntityValue.toString().startsWith("vendor")
        ? _selectedAssignedEntityValue.toString()
        : (_namaStaffLive.isNotEmpty ? _namaStaffLive : 'Help Desk Support');

    Color warnaButangPopUp = AppColors.navy;
    String tajukDialog = '⚙️ Status Update Reason';
    String hintDialog =
        'Enter status update note (e.g., Attending to site issue)...';

    if (statusPilihan.toLowerCase() == 'closed') {
      warnaButangPopUp = Colors.green;
      tajukDialog = '🚨 Closing Resolution Note';
      hintDialog = 'Enter resolution note (e.g., Issue fixed successfully)...';
    } else if (statusPilihan.toLowerCase() == 'in_progress') {
      warnaButangPopUp = const Color(0xFFC9A227);
    }

    _pamerDialogRemarksPaksaan(
        tajuk: tajukDialog,
        hint: hintDialog,
        warnaButang: warnaButangPopUp,
        onConfirm: (textUlasan) {
          _hantarKemasKiniStatusKePHP(
            status: statusPilihan,
            priority: _selectedPriority,
            staff: targetStaff,
            remarks: textUlasan,
          );
        },
        onCancel: () {
          // Jika batal, kita reset status ke nilai asal database !
          setState(() {
            _selectedStatus = statusLamaSesi;
          });
        });
  }

// =========================================================================
// PROSES SIMPAN TERUS DARI DROPDOWN REASSIGN
// Pilih nama terus keluar pop-up alasan and save !
// =========================================================================
  void _prosesSimpanTerusDariReassign(dynamic newValue) {
    if (newValue == null) return;

    //  REVERT: Simpan value lama untuk tujuan patah balik
    final dynamic valueLamaSesi = _selectedAssignedEntityValue;

    setState(() {
      _selectedAssignedEntityValue = newValue;
    });

    String targetStaff = newValue.toString().startsWith("vendor")
        ? newValue.toString()
        : newValue.toString();

    _pamerDialogRemarksPaksaan(
        tajuk: '🔄 Reassignment Reason',
        hint: 'Enter reason for reassigning this ticket...',
        warnaButang: Colors.purple,
        onConfirm: (textUlasan) {
          _hantarKemasKiniStatusKePHP(
            status: _selectedStatus ?? 'Open',
            priority: _selectedPriority,
            staff: targetStaff,
            remarks: textUlasan,
          );
        },
        onCancel: () {
          setState(() {
            _selectedAssignedEntityValue = valueLamaSesi;
          });
        });
  }

  void _tampilMesej(String mesej) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesej)));
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

  Widget _buildSlaInfoColumn(String title, String mainValue, String desc,
      {bool isHighlight = false}) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(mainValue,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isHighlight
                      ? const Color(0xFFD64545)
                      : AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(desc,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textMuted, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildSlaInfoSpacer() {
    return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
            height: 30,
            child: VerticalDivider(width: 1, color: AppColors.border)));
  }

  Widget _buildEmptyFeedbackState() {
    return _buildCentralizedFeedbackCard(
        title: "Customer Feedback",
        subtitle: "Awaiting feedback",
        icon: Icons.rate_review,
        iconColor: const Color(0xFFC9A227),
        iconBg: const Color(0xFFFFF8E6),
        bodyChild: _buildNoFeedbackPlaceholder(
            message:
                "The submitter hasn't submitted feedback for this ticket yet."));
  }

  Widget _buildLockedFeedbackState() {
    return _buildCentralizedFeedbackCard(
        title: "Customer Feedback",
        subtitle: "Section Locked",
        icon: Icons.lock_outline,
        iconColor: const Color(0xFFD64545),
        iconBg: const Color(0xFFFDF2F2),
        bodyChild: _buildNoFeedbackPlaceholder(
            message:
                "This section is locked. Feedback tracking will open automatically once the ticket status is marked as Closed."));
  }

  Widget _buildCentralizedFeedbackCard(
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color iconColor,
      required Color iconBg,
      required Widget bodyChild}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: iconBg, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, size: 18, color: iconColor)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 10.5,
                            color: iconColor,
                            fontWeight: FontWeight.w600))
                  ],
                )
              ])),
          const Divider(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(20.0), child: bodyChild),
        ],
      ),
    );
  }

  Widget _buildNoFeedbackPlaceholder({required String message}) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 10),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              5,
              (index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(Icons.star_border,
                      color: Color(0xFFE5E7EB), size: 28)))),
      const SizedBox(height: 16),
      Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 11.5, color: AppColors.textSecondary, height: 1.4)),
      const SizedBox(height: 10)
    ]);
  }

  Widget _buildActiveFeedbackCard() {
    int rating = _feedbackData?['rating'] ?? 5;
    bool isAuto = _feedbackData?['is_auto_submitted'] == 1;
    String dateStr = _feedbackData?['created_at'] ?? '—';
    String satisfactionLabel = "Satisfied";
    Color ratingColor = const Color(0xFF2E9E52);
    IconData satisfactionIcon = Icons.sentiment_satisfied;
    if (rating == 5) {
      satisfactionLabel = "Very Satisfied";
      satisfactionIcon = Icons.sentiment_very_satisfied;
    } else if (rating <= 2) {
      satisfactionLabel = "Dissatisfied";
      ratingColor = const Color(0xFFD64545);
      satisfactionIcon = Icons.sentiment_very_dissatisfied;
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        decoration: const BoxDecoration(
                            color: Color(0xFFEAF1FB), shape: BoxShape.circle),
                        child: const Icon(Icons.person_outline,
                            size: 16, color: Color(0xFF2F5FA3))),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer Feedback',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        Text('Submitted by complainant',
                            style: TextStyle(
                                fontSize: 10.5, color: AppColors.textMuted))
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.pageBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border)),
                  child: Text("$rating / 5",
                      style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
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
                    Text(satisfactionLabel,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ratingColor)),
                    const SizedBox(width: 8),
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    if (isAuto) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300)),
                        child: const Text("Auto",
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.fieldBackground,
                      border:
                          Border.all(color: AppColors.border.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                      _feedbackData?['comment'] ?? 'No comment written.',
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                          height: 1.4)),
                ),
                const Divider(height: 24, color: AppColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                        children: List.generate(
                            5,
                            (index) => Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: const Color(0xFFC9A227),
                                size: 22))),
                    if (isAuto)
                      const Text('Auto-submitted after 8 hrs',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic))
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
    String title = _ticketData['title'] ?? 'No Title Specified';
    String statusLabel =
        (_selectedStatus ?? _ticketData['status'] ?? 'OPEN').toUpperCase();
    String myDepartment = _ticketData['my_department'] ?? 'No Department';
    String emailUser = _ticketData['submitter_email'] ?? 'No Email';
    String description = _ticketData['description'] ?? 'No description text.';
    String dateCreated = _ticketData['created_at'] ?? 'No Date';
    bool isStatusInProgressLive =
        (_selectedStatus?.toLowerCase().replaceAll(' ', '') == 'in_progress');
    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (BuildContext context) {
          final TabController tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            String currentStatus =
                (_selectedStatus ?? _ticketData['status'] ?? 'open')
                    .toString()
                    .toLowerCase();
            if (tabController.index == 2 && currentStatus != 'closed') {
              tabController.index = tabController.previousIndex;
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.lock_outline, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                          'Feedback tab is LOCKED until the ticket is officially CLOSED!',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  backgroundColor: Color(0xFFD64545),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
          return Scaffold(
            backgroundColor: AppColors.pageBackground,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.navy, size: 18),
                onPressed: () => Navigator.pop(context, true),
              ),
              title: const Text(
                'Ticket Detail Workspace',
                style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
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
                            Expanded(
                                child: Text(title,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary))),
                            StatusTag(
                                label: statusLabel.replaceAll('', ' '),
                                background: _getStatusBg(statusLabel),
                                foreground: _getStatusColor(statusLabel)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(_currentTicketId,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 14),
                        TabBar(
                          labelColor: AppColors.navy,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.navy,
                          indicatorWeight: 2.5,
                          labelStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                          unselectedLabelStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                          tabs: [
                            const Tab(text: 'Detail'),
                            const Tab(text: 'History 🕒'),
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text((_selectedStatus ??
                                                  _ticketData['status'] ??
                                                  'open')
                                              .toString()
                                              .toLowerCase() ==
                                          'closed'
                                      ? 'Feedback 💬'
                                      : 'Feedback 🔒'),
                                ],
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
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ticket Information',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  const Divider(
                                      height: 20, color: AppColors.border),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                        color: AppColors.fieldBackground,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.border
                                                .withValues(alpha: 0.5))),
                                    child: Wrap(
                                      spacing: 20,
                                      runSpacing: 14,
                                      children: [
                                        ReviewField(
                                            label: 'From Department',
                                            value: myDepartment),
                                        ReviewField(
                                            label: 'Category', value: title),
                                        ReviewField(
                                            label: 'Priority',
                                            value: _selectedPriority),
                                        ReviewField(
                                            label: 'Status',
                                            value: statusLabel.replaceAll(
                                                '', ' ')),
                                        ReviewField(
                                            label: 'Submitted Date',
                                            value: dateCreated),
                                        ReviewField(
                                            label: 'Last Update',
                                            value: _lastUpdatedText),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Description',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                        color: AppColors.fieldBackground,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.border
                                                .withValues(alpha: 0.5))),
                                    child: Text(description,
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textPrimary,
                                            height: 1.4)),
                                  ),
                                  if (_ticketData['attachment_path'] != null &&
                                      _ticketData['attachment_path']
                                          .toString()
                                          .isNotEmpty &&
                                      _ticketData['attachment_path']
                                              .toString() !=
                                          'null') ...[
                                    const SizedBox(height: 16),
                                    const Text('Attachment Media',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary)),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () {
                                        final String domain = kIsWeb
                                            ? 'localhost'
                                            : '10.103.19.67';

                                        // Bersihkan and encode nama file gambar agar kalis whitespace!
                                        String namaFailMentahDariDb =
                                            _ticketData['attachment_path']
                                                .toString()
                                                .trim();
                                        String namaFailSiapEncode =
                                            Uri.encodeComponent(
                                                namaFailMentahDariDb);

                                        // Gabungkan url kacak yang dibilas suci bersih total 100%!
                                        String urlGambarTulen =
                                            "http://$domain/helpdesk_api/uploads/$namaFailSiapEncode";

                                        // Membuka dialog modal pop-up kacak untuk memaparkan gambar lampiran secara live !
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16)),
                                            title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text('📸 Evidence View',
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors.navy)),
                                                IconButton(
                                                    icon: const Icon(
                                                        Icons.close,
                                                        size: 18),
                                                    onPressed: () =>
                                                        Navigator.pop(context)),
                                              ],
                                            ),
                                            content: SizedBox(
                                              width: double.maxFinite,
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    ConstrainedBox(
                                                      constraints:
                                                          BoxConstraints(
                                                        maxHeight:
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                0.6,
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        child: Image.network(
                                                          urlGambarTulen,
                                                          fit: BoxFit.contain,
                                                          errorBuilder: (context,
                                                                  error,
                                                                  stackTrace) =>
                                                              const Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        20),
                                                            child: Text(
                                                                '❌ Image file not found inside Laragon uploads folder.',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .red)),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(namaFailMentahDariDb,
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color:
                                                                Colors.grey)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 14),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFEAF1FB),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: const Color(0xFF2F5FA3)
                                                    .withOpacity(0.3))),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.image_outlined,
                                                size: 18,
                                                color: AppColors.navy),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                "Click to view evidence: ${_ticketData['attachment_path']}",
                                                style: const TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.navy),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Icon(
                                                Icons.open_in_new_rounded,
                                                size: 14,
                                                color: AppColors.navy),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  const Text('Submitted By',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                        color: AppColors.fieldBackground,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.border
                                                .withValues(alpha: 0.5))),
                                    child: Row(children: [
                                      Expanded(
                                          child: Text(emailUser,
                                              style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppColors.textPrimary)))
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            // =========================================================================
                            // =========================================================================
                            _slaData == null || _slaData!['status'] == 'gagal'
                                ? const Center(
                                    child: Padding(
                                        padding: EdgeInsets.all(10),
                                        child: CircularProgressIndicator()))
                                : Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.border)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFEAF7EE),
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              child: const Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: Color(0xFF2E9E52)),
                                            ),
                                            const SizedBox(width: 10),
                                            const Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('SLA Status',
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors
                                                            .textPrimary)),
                                                Text(
                                                    '8 hrs · Mon–Fri 08:00–17:00',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: AppColors
                                                            .textMuted)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),

                                        // 🟢 PENANDA STATUS HIJAU LIVE: Membaca 'admin_sla_status' dari real-time PHP!
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                              color:
                                                  (_slaData?['is_breached'] ??
                                                          false)
                                                      ? const Color(0xFFFDF2F2)
                                                      : const Color(0xFFEAF7EE),
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: (_slaData?[
                                                                  'is_breached'] ??
                                                              false)
                                                          ? const Color(
                                                              0xFFD64545)
                                                          : const Color(
                                                              0xFF2E9E52))),
                                              const SizedBox(width: 6),
                                              Text(
                                                  _isAssignedToVendorLive
                                                      ? (_slaData?[
                                                                  'admin_sla_status']
                                                              ?.toString() ??
                                                          "SLA Stopped")
                                                      : (_slaData?['sla_status']
                                                              ?.toString() ??
                                                          "Active"),
                                                  style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: (_slaData?[
                                                                  'is_breached'] ??
                                                              false)
                                                          ? const Color(
                                                              0xFFD64545)
                                                          : const Color(
                                                              0xFF2E9E52))),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        LinearProgressIndicator(
                                          value: double.parse(
                                              (_isAssignedToVendorLive
                                                      ? (_slaData?[
                                                              'admin_progress'] ??
                                                          0.0)
                                                      : (_slaData?[
                                                              'progress'] ??
                                                          0.0))
                                                  .toString()),
                                          backgroundColor:
                                              AppColors.pageBackground,
                                          valueColor: AlwaysStoppedAnimation(
                                              (_slaData?['is_breached'] ??
                                                      false)
                                                  ? const Color(0xFFD64545)
                                                  : const Color(0xFF2E9E52)),
                                          minHeight: 6,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        const SizedBox(height: 4),
                                        const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('0h',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        AppColors.textMuted)),
                                            Text('4h',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        AppColors.textMuted)),
                                            Text('8h',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.textMuted))
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildSlaInfoColumn(
                                                  "SUBMITTED",
                                                  _slaData?['submitted_at']
                                                          ?.toString() ??
                                                      '—',
                                                  "Ticket submission\ndate & time"),
                                              _buildSlaInfoSpacer(),
                                              _buildSlaInfoColumn(
                                                  "DEADLINE",
                                                  "—",
                                                  "SLA clock stopped\nafter response"),
                                              _buildSlaInfoSpacer(),
                                              _buildSlaInfoColumn(
                                                  "TIME USED",
                                                  _isAssignedToVendorLive
                                                      ? (_slaData?[
                                                                  'admin_time_used']
                                                              ?.toString() ??
                                                          "0h m used")
                                                      : (_slaData?['time_used']
                                                              ?.toString() ??
                                                          "—"),
                                                  "Working hours from\nsubmission to close",
                                                  isHighlight: true),
                                              _buildSlaInfoSpacer(),
                                              _buildSlaInfoColumn(
                                                  "RESPONDED AT",
                                                  _slaData?['responded_at']
                                                          ?.toString() ??
                                                      '—',
                                                  "Staff first moved\nticket to In Progress"),
                                              _buildSlaInfoSpacer(),
                                              _buildSlaInfoColumn(
                                                  "CLOSED AT",
                                                  _slaData?['closed_at']
                                                          ?.toString() ??
                                                      '—',
                                                  "Ticket was marked as\nclosed"),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                            const SizedBox(height: 14),
// =========================================================================
// KOTAK ASSIGNED TO DROPDOWN
// =========================================================================
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
                                      Icon(Icons.person_outline_outlined,
                                          color: AppColors.navy, size: 16),
                                      SizedBox(width: 8),
                                      Text('Assigned To',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                      'Manage ticket assignment parameters',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                  const Divider(
                                      height: 20, color: AppColors.border),
// Kotak Paparan Penanda Status Atas Live
                                  _isAssignedToVendorLive
                                      ? Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFEAF1FB),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFFD2E3FC))),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor:
                                                      Colors.purple.shade50,
                                                  child: const Text('V',
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.purple))),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                        (_ticketData['assigned_vendor_name'] !=
                                                                    null &&
                                                                _ticketData[
                                                                        'assigned_vendor_name']
                                                                    .toString()
                                                                    .isNotEmpty &&
                                                                _ticketData['assigned_vendor_name']
                                                                        .toString() !=
                                                                    'null')
                                                            ? _ticketData[
                                                                    'assigned_vendor_name']
                                                                .toString()
                                                                .toUpperCase()
                                                            : (_ticketData['remarks'] !=
                                                                        null &&
                                                                    _ticketData[
                                                                            'remarks']
                                                                        .toString()
                                                                        .isNotEmpty)
                                                                ? _ticketData[
                                                                        'remarks']
                                                                    .toString()
                                                                    .toUpperCase()
                                                                : (_assignedVendorNameLive
                                                                        .isNotEmpty
                                                                    ? _assignedVendorNameLive
                                                                        .toUpperCase()
                                                                    : 'VENDOR COMPANY'),
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: AppColors
                                                                .navy)),
                                                    Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2),
                                                        decoration: BoxDecoration(
                                                            color: Colors
                                                                .blue.shade50,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4)),
                                                        child: const Text(
                                                            'Vendor',
                                                            style: TextStyle(
                                                                fontSize: 8,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .blue))),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        )
                                      : Row(
                                          children: [
                                            CircleAvatar(
                                                radius: 16,
                                                backgroundColor: AppColors.navy,
                                                child: Text(
                                                    _selectedStaff != null &&
                                                            _selectedStaff!
                                                                .isNotEmpty
                                                        ? _selectedStaff!
                                                            .substring(0, 1)
                                                            .toUpperCase()
                                                        : 'H',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700))),
                                            const SizedBox(width: 10),
                                            Expanded(
                                                child: Text(
                                                    (_selectedStaff ??
                                                            'Help Desk Support')
                                                        .toString()
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .textPrimary))),
                                          ],
                                        ),

                                  // =========================================================================
                                  //  CHAT MATCHING & INLINE LOG REMARKS
                                  // =========================================================================
                                  if (_isAssignedToVendorLive == true) ...[
                                    (() {
                                      String jamDanMinitSlaLiveDipapar =
                                          "5h 0m left";
                                      String dueTimeLiveTulenDipapar =
                                          "Pending Calculation...";

                                      try {
                                        String waktuMulaSlaStr = '';

                                        //  Cari rekod log penugasan vendor yang paling tepat !
                                        if (_ticketLogs.isNotEmpty) {
                                          final logVendor =
                                              _ticketLogs.firstWhere(
                                            (log) =>
                                                (log['reason'] ?? '')
                                                    .toString()
                                                    .toUpperCase()
                                                    .contains('ASSIGNED TO') ||
                                                (log['reason'] ?? '')
                                                    .toString()
                                                    .toUpperCase()
                                                    .contains('VENDOR'),
                                            orElse: () => null,
                                          );
                                          if (logVendor != null)
                                            waktuMulaSlaStr =
                                                (logVendor['transferred_at'] ??
                                                        '')
                                                    .toString();
                                        }

                                        if (waktuMulaSlaStr.isEmpty) {
                                          waktuMulaSlaStr = (_ticketData[
                                                      'updated_at'] ??
                                                  _ticketData['created_at'] ??
                                                  '')
                                              .toString();
                                        }

                                        // !
                                        DateTime? waktuMula;
                                        if (waktuMulaSlaStr.isNotEmpty) {
                                          waktuMula = DateTime.tryParse(
                                              waktuMulaSlaStr);
                                        }

                                        //
                                        waktuMula ??= DateTime.tryParse(
                                                _ticketData['created_at'] ??
                                                    '') ??
                                            DateTime.now();

                                        // PENGIRAAN DEADLINE 5 JAM KERJA VENDOR
                                        DateTime deadline = waktuMula
                                            .add(const Duration(hours: 5));

                                        // Format paparan Due Time
                                        List<String> months = [
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
                                        String amPm =
                                            deadline.hour >= 12 ? 'PM' : 'AM';
                                        int displayHour = deadline.hour > 12
                                            ? deadline.hour - 12
                                            : (deadline.hour == 0
                                                ? 12
                                                : deadline.hour);
                                        dueTimeLiveTulenDipapar =
                                            "${deadline.day} ${months[deadline.month - 1]}, $displayHour:${deadline.minute.toString().padLeft(2, '0')} $amPm";

                                        // Kira baki masa
                                        Duration diff =
                                            deadline.difference(DateTime.now());
                                        if (diff.isNegative) {
                                          jamDanMinitSlaLiveDipapar =
                                              "0h 0m left (BREACHED)";
                                        } else {
                                          jamDanMinitSlaLiveDipapar =
                                              "${diff.inHours}h ${diff.inMinutes % 60}m left";
                                        }
                                      } catch (e) {
                                        dueTimeLiveTulenDipapar =
                                            "03 Sep, 10:21 AM";
                                      }

                                      String statusTulinDbComplaints =
                                          (_ticketData['status'] ??
                                                  _selectedStatus ??
                                                  'open')
                                              .toString()
                                              .toLowerCase()
                                              .trim();

                                      // filter VENDOR: Hanya log yang mengandungi 'HANDLED BY: 👤' dikira sebagai respon vendor
                                      bool adakahVendorDahResponLive =
                                          _ticketLogs.any((log) {
                                        String reasonLog = (log['reason'] ?? '')
                                            .toString()
                                            .toUpperCase();
                                        // Kita cari ikon 👤 and perkataan HANDLED BY yang hanya dihasilkan oleh vendor
                                        return reasonLog
                                            .contains('HANDLED BY: 👤');
                                      });

                                      // Kotak HIJAU hanya boleh keluar sekiranya status dah CLOSED, atau vendor SAH dah hantar respon!
                                      if (statusTulinDbComplaints == 'closed' ||
                                          adakahVendorDahResponLive) {
                                        return Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(top: 12),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFEAF7EE),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: const Color(0xFF2E9E52)
                                                      .withOpacity(0.25))),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('VENDOR RESPONSE',
                                                  style: TextStyle(
                                                      fontSize: 9.5,
                                                      color: Colors.grey,
                                                      letterSpacing: 0.5)),
                                              const SizedBox(height: 8),
                                              Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFD1FAE5),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4)),
                                                  child: const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.check_circle,
                                                            size: 12,
                                                            color: Color(
                                                                0xFF2E9E52)),
                                                        SizedBox(width: 4),
                                                        Text('Vendor responded',
                                                            style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                    0xFF2E9E52)))
                                                      ])),
                                              const SizedBox(height: 10),

                                              //INLINE REMARKS EXTRACTOR ENGINE: Sedut teks minit sejati dari kolum remarks log!
                                              Text(
                                                  "Responded in ${(() {
                                                    String masaDitemui = '1m';
                                                    if (_ticketLogs
                                                        .isNotEmpty) {
                                                      try {
                                                        //  Cari log yang statusnya 'in_progress' sahaja !
                                                        final logProgress =
                                                            _ticketLogs
                                                                .firstWhere(
                                                          (log) =>
                                                              (log['remarks'] ??
                                                                      '')
                                                                  .toString()
                                                                  .toLowerCase()
                                                                  .contains(
                                                                      'responded in') &&
                                                              (log['new_status'] ??
                                                                          '')
                                                                      .toString()
                                                                      .toLowerCase()
                                                                      .trim() ==
                                                                  'in_progress',
                                                          orElse: () => null,
                                                        );
                                                        if (logProgress !=
                                                                null &&
                                                            logProgress[
                                                                    'remarks'] !=
                                                                null) {
                                                          // Kita buang teks 'Responded in' and ambil durasi  sahaja!
                                                          masaDitemui = logProgress[
                                                                  'remarks']
                                                              .toString()
                                                              .toLowerCase()
                                                              .replaceAll(
                                                                  'responded in',
                                                                  '')
                                                              .trim();
                                                        }
                                                      } catch (e) {}
                                                    }
                                                    return masaDitemui;
                                                  })()} · ${(_ticketData['real_save_date_time'] ?? _lastUpdatedText).toString().trim()}",
                                                  style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors
                                                          .textPrimary)),

                                              const SizedBox(height: 3),
                                              Text(
                                                  'Sent to vendor ${_slaData?['responded_at'] ?? _ticketData['updated_at'] ?? '02 Sep 2026, 2:20 PM'} · 5 working hours to respond',
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        );
                                      } else {
                                        // 🟡 KOTAK KUNING SEJATI: Keluar kacak and berdetik live sekiranya status In Progress tapi vendor belum taip ulasan!
                                        return Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(top: 12),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFFFF8E6),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: const Color(0xFFC9A227)
                                                      .withOpacity(0.25))),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('VENDOR RESPONSE',
                                                  style: TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey,
                                                      letterSpacing: 0.5)),
                                              const SizedBox(height: 8),
                                              Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration:
                                                      const BoxDecoration(
                                                          color:
                                                              Color(0xFFFFF1D2),
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          4))),
                                                  child: const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .hourglass_empty_rounded,
                                                            size: 12,
                                                            color: Color(
                                                                0xFFC9A227)),
                                                        SizedBox(width: 4),
                                                        Text(
                                                            'Awaiting vendor response',
                                                            style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                    0xFFC9A227)))
                                                      ])),
                                              const SizedBox(height: 10),
                                              Text(
                                                  "$jamDanMinitSlaLiveDipapar · due $dueTimeLiveTulenDipapar",
                                                  style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors
                                                          .textPrimary)),
                                              const SizedBox(height: 3),
                                              Text(
                                                  'Sent to vendor ${_slaData?['responded_at'] ?? _ticketData['updated_at'] ?? '02 Sep 2026, 2:20 PM'} · 5 working hours to respond',
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        );
                                      }
                                    })(),
                                  ],
                                  const SizedBox(height: 14),
                                  const Divider(
                                      height: 1, color: AppColors.border),

                                  const SizedBox(height: 12),
                                  const Text('REASSIGN TO',
                                      style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey)),
                                  const SizedBox(height: 6),
// =========================================================================
//DROPDOWN EXCEPTION MATCHING: PENYELARAS DYNAMIC SEACUAN COMPANY NAME
// =========================================================================
                                  DropdownButtonFormField(
                                    isExpanded: true,
                                    value: (() {
                                      if (_selectedAssignedEntityValue !=
                                          null) {
                                        String strValueLive =
                                            _selectedAssignedEntityValue
                                                .toString()
                                                .trim();

                                        //  Jika awal-awal masuk, takungan entiti memegang id hantu 'vendor18' atau 'vendorXX'
                                        if (strValueLive.startsWith('vendor') ||
                                            strValueLive
                                                .startsWith('vendors')) {
                                          // ambil nombor id sahaja
                                          String bersihkanIdAngka = strValueLive
                                              .replaceAll(RegExp(r'[^0-9]'), '')
                                              .trim();

                                          if (_senaraiActiveVendorsDropdown
                                                  .isNotEmpty &&
                                              bersihkanIdAngka.isNotEmpty) {
                                            // Cari mana-mana vendor di dalam list dropdown
                                            final padananVendor =
                                                _senaraiActiveVendorsDropdown
                                                    .firstWhere(
                                              (v) =>
                                                  (v['vendor_id'] ??
                                                          v['id'] ??
                                                          '')
                                                      .toString()
                                                      .trim() ==
                                                  bersihkanIdAngka,
                                              orElse: () => null,
                                            );
                                            if (padananVendor != null) {
                                              // return nama syarikat
                                              return (padananVendor[
                                                          'company_name'] ??
                                                      '')
                                                  .toString()
                                                  .trim();
                                            }
                                          }
                                        }

                                        //  STEP 2: Jika nama staff internal, kita semak and pulangkan nama staff macam biasa
                                        if (_listStaff.contains(strValueLive)) {
                                          return strValueLive;
                                        }

                                        // STEP 3: Jika list dropdown dah sedia memegang company_name yang sepadan tulin
                                        final bool
                                            adakahNamaCompanyWujudDalamDropdown =
                                            _senaraiActiveVendorsDropdown.any(
                                                (v) =>
                                                    (v['company_name'] ?? '')
                                                        .toString()
                                                        .trim()
                                                        .toLowerCase() ==
                                                    strValueLive.toLowerCase());
                                        if (adakahNamaCompanyWujudDalamDropdown) {
                                          // Cari ejaan case-sensitive yang tepat di dalam dropdown list  anda
                                          final exactVendor =
                                              _senaraiActiveVendorsDropdown
                                                  .firstWhere((v) =>
                                                      (v['company_name'] ?? '')
                                                          .toString()
                                                          .trim()
                                                          .toLowerCase() ==
                                                      strValueLive
                                                          .toLowerCase());
                                          return (exactVendor['company_name'] ??
                                                  strValueLive)
                                              .toString()
                                              .trim();
                                        }
                                      }

                                      // Fallback default jika masih unassigned  anda
                                      return null;
                                    })(),
                                    hint: const Text(
                                        '— Select staff or vendor —',
                                        style: TextStyle(fontSize: 12)),
                                    decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(6))),
                                    items: <DropdownMenuItem>[
                                      ..._listStaff.map<DropdownMenuItem>(
                                          (String staffName) {
                                        return DropdownMenuItem(
                                          value: staffName,
                                          child: Text("🧑‍💻 Staff: $staffName",
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textPrimary)),
                                        );
                                      }),
//  UNLOCK VENDOR (Point 2): Hanya boleh pilih vendor jika status dalam DATABASE sudah IN PROGRESS!
                                      ..._senaraiActiveVendorsDropdown
                                          .map<DropdownMenuItem>(
                                              (dynamic vendor) {
                                        String currentDbStatus =
                                            (_ticketData['status'] ?? '')
                                                .toString()
                                                .toLowerCase()
                                                .trim();
                                        bool adakahStatusSudahProgressInDB =
                                            currentDbStatus == 'in_progress';

                                        return DropdownMenuItem(
                                          value: "${vendor['company_name']}"
                                              .toString()
                                              .trim(),
                                          enabled:
                                              adakahStatusSudahProgressInDB, // Hanya enabled jika dah confirm & save status In Progress
                                          child: Text(
                                            "🏢 Vendor: ${vendor['company_name']}",
                                            style: TextStyle(
                                                fontSize: 11.5,
                                                color:
                                                    adakahStatusSudahProgressInDB
                                                        ? Colors.purple
                                                        : Colors.grey.shade400,
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged:
                                        (_selectedStatus?.toLowerCase() !=
                                                'closed')
                                            ? (dynamic newValue) =>
                                                _prosesSimpanTerusDariReassign(
                                                    newValue)
                                            : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
// Kotak Suis Utama Tukar Status Tiket
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border)),
                              child: Builder(builder: (context) {
                                String staffOwnerDatabase =
                                    (_selectedStaff ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .trim();
                                String staffLoginSesiTulen = (_namaStaffLive)
                                    .toString()
                                    .toLowerCase()
                                    .trim();

                                bool isTicketMineLive = (staffOwnerDatabase ==
                                        staffLoginSesiTulen) ||
                                    (staffOwnerDatabase ==
                                        'help desk support') ||
                                    (staffOwnerDatabase == 'unassigned');

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                        'Update Ticket Status & Priority',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary)),
                                    const SizedBox(height: 14),
                                    const Text('PRIORITY',
                                        style: AppTextStyles.fieldLabel),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _PriorityButton(
                                            label: 'Low',
                                            color: const Color(0xFF2E9E52),
                                            active: _selectedPriority == 'Low',
                                            isTicketMine: _selectedStatus
                                                    ?.toLowerCase() !=
                                                'closed', // 💥 Locked interaction if closed!
                                            onTap: () => setState(() =>
                                                _selectedPriority = 'Low')),
                                        const SizedBox(width: 8),
                                        _PriorityButton(
                                            label: 'Medium',
                                            color: const Color(0xFFC9A227),
                                            active:
                                                _selectedPriority == 'Medium',
                                            isTicketMine: _selectedStatus
                                                    ?.toLowerCase() !=
                                                'closed', // 💥 Locked interaction if closed!
                                            onTap: () => setState(() =>
                                                _selectedPriority = 'Medium')),
                                        const SizedBox(width: 8),
                                        _PriorityButton(
                                            label: 'High',
                                            color: const Color(0xFFD64545),
                                            active: _selectedPriority == 'High',
                                            isTicketMine: _selectedStatus
                                                    ?.toLowerCase() !=
                                                'closed', // 💥 Locked interaction if closed!
                                            onTap: () => setState(() =>
                                                _selectedPriority = 'High')),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    const Text('STATUS',
                                        style: AppTextStyles.fieldLabel),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _StatusButton(
                                          label: 'Open',
                                          color: const Color(0xFF2F5FA3),
                                          active: _selectedStatus == 'Open',
                                          isTicketMine: isTicketMineLive &&
                                              (_ticketData['status']
                                                      ?.toString()
                                                      .toLowerCase() !=
                                                  'closed') &&
                                              (_selectedStatus != 'Closed'),
                                          onTap: () =>
                                              _prosesSimpanTerusDariStatus(
                                                  'Open'),
                                        ),
                                        const SizedBox(width: 8),
                                        _StatusButton(
                                          label: 'In Progress',
                                          color: const Color(0xFFC9A227),
                                          active:
                                              _selectedStatus == 'In Progress',
                                          //  Jika tiket dah CLOSED, button In Progress terus locked !
                                          isTicketMine: isTicketMineLive &&
                                              (_ticketData['status']
                                                      ?.toString()
                                                      .toLowerCase() !=
                                                  'closed') &&
                                              (_selectedStatus != 'Closed'),
                                          onTap: () =>
                                              _prosesSimpanTerusDariStatus(
                                                  'In Progress'),
                                        ),
                                        const SizedBox(width: 8),
                                        _StatusButton(
                                          label: 'Closed',
                                          color: const Color(0xFF2E9E52),
                                          active: _selectedStatus == 'Closed',
                                          // Button Closed sentiasa boleh diklik jika pemilik, tapi logic _prosesSimpan akan halang jika dah closed.
                                          isTicketMine: isTicketMineLive &&
                                              (_ticketData['status']
                                                      ?.toString()
                                                      .toLowerCase() !=
                                                  'closed'),
                                          onTap: () =>
                                              _prosesSimpanTerusDariStatus(
                                                  'Closed'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    if (_isSaving)
                                      const Center(
                                          child: CircularProgressIndicator())
                                    else if (_ticketData['status']
                                            ?.toString()
                                            .toLowerCase() ==
                                        'closed') ...[
                                      // 💥 KUNCI LOCKED: Sekiranya tiket closed, kita paparkan lencana hijau!
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFEAF7EE),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: const Color(0xFF2E9E52)
                                                    .withOpacity(0.3))),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.verified_user_rounded,
                                                color: Color(0xFF2E9E52),
                                                size: 16),
                                            SizedBox(width: 8),
                                            Text(
                                              'This ticket has been officially resolved and CLOSED.',
                                              style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2E9E52)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              }),
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
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Change History",
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(
                                      "${_ticketLogs.length} changes recorded for this ticket",
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted)),
                                  const Divider(
                                      height: 24, color: AppColors.border),
// =========================================================================
// =========================================================================
                                  _ticketLogs.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 20),
                                          child: Center(
                                              child: Text(
                                                  "No history log available.",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textMuted))),
                                        )
                                      : Column(
                                          children: List.generate(
                                              _ticketLogs.length, (index) {
                                            final log = _ticketLogs[index];
                                            if (log['is_hidden'] == true ||
                                                log['is_hidden'] == 1)
                                              return const SizedBox.shrink();

                                            String namaAktor =
                                                log['transferred_by_name'] ??
                                                    'SYSTEM';
                                            String deskripsiMentah =
                                                (log['reason'] ??
                                                        'Activity logged.')
                                                    .toString();
                                            String tarikhLogMentah =
                                                (log['transferred_at'] ?? '')
                                                    .toString();
                                            bool isStatusChange =
                                                deskripsiMentah
                                                    .toLowerCase()
                                                    .contains('status');

                                            // STEP 1: FORMAT TARIKH PROFESIONAL (Cth: 11:21 | 18 Sep 2026)
                                            String tarikhMasaSiapDipapar =
                                                tarikhLogMentah;
                                            if (tarikhLogMentah.length >= 19) {
                                              try {
                                                String jamMinit =
                                                    tarikhLogMentah.substring(
                                                        11, 16);
                                                String hari = tarikhLogMentah
                                                    .substring(8, 10);
                                                String bulanNum =
                                                    tarikhLogMentah.substring(
                                                        5, 7);
                                                String tahun = tarikhLogMentah
                                                    .substring(0, 4);

                                                if (hari.startsWith('0'))
                                                  hari = hari.substring(1);

                                                List<String> senaraiBulanTulin =
                                                    [
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

                                                int indeksBulan =
                                                    int.parse(bulanNum) - 1;
                                                String namaBulanTeks =
                                                    (indeksBulan >= 0 &&
                                                            indeksBulan < 12)
                                                        ? senaraiBulanTulin[
                                                            indeksBulan]
                                                        : 'Sep';

                                                tarikhMasaSiapDipapar =
                                                    "$jamMinit | $hari $namaBulanTeks $tahun";
                                              } catch (e) {
                                                tarikhMasaSiapDipapar =
                                                    tarikhLogMentah;
                                              }
                                            }

                                            // STEP 2: LITAR PENYELARAS DESKRIPSI
                                            String deskripsiBersihDipapar =
                                                deskripsiMentah;

                                            if (deskripsiBersihDipapar
                                                    .contains('->') ||
                                                deskripsiBersihDipapar
                                                    .contains('→')) {
                                              try {
                                                if (deskripsiBersihDipapar
                                                    .toLowerCase()
                                                    .contains('vendor')) {
                                                  String
                                                      namaSyarikatVendorTulen =
                                                      (_ticketData[
                                                                  'assigned_vendor_name'] ??
                                                              _ticketData[
                                                                  'remarks'] ??
                                                              'itdeptvendor sdn bhd')
                                                          .toString()
                                                          .trim();

                                                  if (namaSyarikatVendorTulen
                                                          .isEmpty ||
                                                      namaSyarikatVendorTulen
                                                              .toLowerCase() ==
                                                          'null') {
                                                    namaSyarikatVendorTulen =
                                                        "itdeptvendor sdn bhd";
                                                  }

                                                  if (deskripsiBersihDipapar
                                                      .contains('→')) {
                                                    String bahagianDepan =
                                                        deskripsiBersihDipapar
                                                            .split('→')
                                                            .first;
                                                    if (deskripsiMentah
                                                        .contains('MESSAGE:')) {
                                                      deskripsiBersihDipapar =
                                                          deskripsiMentah; // Kekalkan isi penuh Handled By & Message tulen!
                                                    } else {
                                                      deskripsiBersihDipapar =
                                                          "$bahagianDepan→ ${namaSyarikatVendorTulen.toUpperCase()}";
                                                    }
                                                  } else if (deskripsiBersihDipapar
                                                      .contains('->')) {
                                                    String bahagianDepan =
                                                        deskripsiBersihDipapar
                                                            .split('->')
                                                            .first;
                                                    if (deskripsiMentah
                                                        .contains('MESSAGE:')) {
                                                      deskripsiBersihDipapar =
                                                          deskripsiMentah;
                                                    } else {
                                                      deskripsiBersihDipapar =
                                                          "$bahagianDepan-> ${namaSyarikatVendorTulen.toUpperCase()}";
                                                    }
                                                  }
                                                }
                                              } catch (e) {
                                                print(
                                                    "Ralat saringan dynamic vendor matching: $e");
                                              }
                                            }

                                            return _buildHistoryItem(
                                                namaAktor,
                                                tarikhMasaSiapDipapar,
                                                deskripsiBersihDipapar,
                                                isStatusChange,
                                                isLast: index ==
                                                    _ticketLogs.length - 1);
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
                                  ? const Center(
                                      child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: CircularProgressIndicator()))
                                  : _feedbackData?['status'] == 'locked'
                                      ? _buildLockedFeedbackState()
                                      : _feedbackData?['status'] == 'kosong'
                                          ? _buildEmptyFeedbackState()
                                          : _buildActiveFeedbackCard(),
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

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  final bool isTicketMine;

  const _StatusButton({
    required this.label,
    required this.color,
    required this.onTap,
    required this.isTicketMine,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: isTicketMine ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: active
                  ? color.withValues(alpha: 0.12)
                  : AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: active ? color : AppColors.border,
                  width: active ? 1.4 : 1)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? color : Colors.grey.shade300),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? color : AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildHistoryItem(
    String name, String time, String action, bool isStatusChange,
    {bool isLast = false}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
                color: isStatusChange
                    ? const Color(0xFFFFF8E6)
                    : const Color(0xFFEAF1FB),
                shape: BoxShape.circle,
                border: Border.all(
                    color: isStatusChange
                        ? const Color(0xFFC9A227)
                        : const Color(0xFF2F5FA3),
                    width: 1.5)),
            child: Icon(isStatusChange ? Icons.star : Icons.person,
                size: 10,
                color: isStatusChange
                    ? const Color(0xFFC9A227)
                    : const Color(0xFF2F5FA3)),
          ),
          if (!isLast)
            Container(width: 1.5, height: 44, color: Colors.grey.shade200),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Theme(
              data:
                  ThemeData(iconTheme: const IconThemeData(color: Colors.grey)),
              child: Row(
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 6),
                  Text("• $time",
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(action,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
            const SizedBox(height: 12),
          ],
        ),
      )
    ],
  );
}

class _PriorityButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  final bool isTicketMine;
  const _PriorityButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isTicketMine,
    bool active = false,
  })  : label = label,
        color = color,
        onTap = onTap,
        isTicketMine = isTicketMine,
        active = active;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: isTicketMine ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: active
                  ? color.withValues(alpha: 0.12)
                  : AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: active ? color : AppColors.border,
                  width: active ? 1.4 : 1)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? color : Colors.grey.shade300),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? color : AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
