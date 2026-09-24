import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'remove_item_dialog.dart';
import 'add_another_item_dialog.dart'; // Fail dialog asal anda
import '../../main.dart';

/// Interface 7: "Confirm All Submissions" screen.
class ComplaintConfirmSubmissionsScreen extends StatefulWidget {
  const ComplaintConfirmSubmissionsScreen({super.key});

  @override
  State<ComplaintConfirmSubmissionsScreen> createState() =>
      _ComplaintConfirmSubmissionsScreenState();
}

class _ComplaintConfirmSubmissionsScreenState
    extends State<ComplaintConfirmSubmissionsScreen> {
  List<Map<String, dynamic>> _senaraiAduan = [];
  bool _isInitialized = false;
  bool _isSending = false;

// =========================================================================
// KUNCI DYNAMIC SESSION:
// Sistem  membaca emel dan nama dinamik session dari main.dart!
// =========================================================================
  String get _safeLiveEmail => currentLoggedInUserEmail ?? "user@gmail.com";

  String get _safeLiveName => _safeLiveEmail.contains('@')
      ? _safeLiveEmail
          .split('@')[0]
          .toUpperCase()
          .replaceAll('.', ' ')
          .replaceAll('_', ' ')
      : "USER COMPLAINANT";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
// Memastikan payload map argument juga auto-terpaut email session anda!
        Map<String, dynamic> dataAduan = Map<String, dynamic>.from(args);
        dataAduan['email'] = _safeLiveEmail;
        dataAduan['full_name'] = _safeLiveName;
        _senaraiAduan.add(dataAduan);
      }
      _isInitialized = true;
    }
  }

  void _tampilDialogPadam(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Item',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.navy)),
          content: const Text(
              'Are you sure you want to delete this complaint? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Keep Item', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _senaraiAduan.removeAt(index);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Complaint item removed successfully.')),
                );
              },
              child: const Text('Delete',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _bukaDialogAddAnother() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Another Complaint',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.navy)),
          content: const Text(
              'Would you like to add another complaint ticket to this submission?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.pushNamed(
                  context,
                  '/complaint/fill',
                  arguments: {
                    'isAddAnother': true,
                  },
                ).then((value) {
                  if (value != null && value is Map<String, dynamic>) {
                    setState(() {
                      Map<String, dynamic> aduanBaru =
                          Map<String, dynamic>.from(value);
                      aduanBaru['email'] = _safeLiveEmail;
                      aduanBaru['full_name'] = _safeLiveName;
                      _senaraiAduan.add(aduanBaru);
                    });
                  }
                });
              },
              child: const Text('Yes, Add',
                  style: TextStyle(
                      color: AppColors.navy, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // ENJIN PENGHANTARAN MULTIPART FILE UPLOADER
  // Menghantar file gambar fizikal masuk dalam folder uploads
  // =========================================================================
  Future<void> _simpanSemuaAduanKeDatabase() async {
    if (_senaraiAduan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Your submission list is empty. Please add a complaint.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse('http://$domain/helpdesk_api/save_tickets.php');

    try {
      // STEP 1: Kita bina litar http.MultipartRequest!
      var requestMultipart = http.MultipartRequest('POST', url);

      // apply data email and nama session live
      final listHantaranTulen = _senaraiAduan.map((aduan) {
        aduan['email'] = _safeLiveEmail;
        aduan['full_name'] = _safeLiveName;
        return aduan;
      }).toList();

      // Suap data text array list aduan dalam bentuk string field
      requestMultipart.fields['aduan_json_data'] =
          json.encode(listHantaranTulen);

      // STEP 2: apply FILE GAMBAR FIZIKAL KE SERVER
      //  semak jika pengguna ada attach gambar fizikal di skrin fill details !
      // Membaca object arguments dari skrin Fill Details yang dipindahkan senarai
      for (int i = 0; i < _senaraiAduan.length; i++) {
        var aduanSemasa = _senaraiAduan[i];

        // apply byte data fizikal yang dipilih lewat FilePicker
        if (aduanSemasa['attachment_file_bytes'] != null) {
          // running in Google Chrome Web browser
          requestMultipart.files.add(http.MultipartFile.fromBytes(
            'attachment_files[]', // Nama array parameter tangkapan $_FILES di PHP Laragon
            aduanSemasa['attachment_file_bytes'],
            filename: aduanSemasa['attachment_path'],
          ));
        } else if (aduanSemasa['attachment_file_path'] != null &&
            aduanSemasa['attachment_file_path'].toString().isNotEmpty) {
          // running di Android Emulator phone
          requestMultipart.files.add(await http.MultipartFile.fromPath(
            'attachment_files[]',
            aduanSemasa['attachment_file_path'],
            filename: aduanSemasa['attachment_path'],
          ));
        }
      }

      print(
          "📤 MULTIPART STEAM LAUNCHED: Sending ${_senaraiAduan.length} complaints along with physical images tracks...");

      //  hantar data streaming ke PHP Laragon server
      var responStream = await requestMultipart.send();
      var responHasil = await http.Response.fromStream(responStream);

      if (responHasil.statusCode == 200) {
        final Map<String, dynamic> hasil = json.decode(responHasil.body);

        if (hasil['status'] == 'berjaya') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(hasil['mesej'] ??
                      'Complaint successfully submitted along with image evidence!')),
            );

            List<String> ticketIds =
                List<String>.from(hasil['ticket_ids'] ?? []);

            setState(() {
              _senaraiAduan.clear();
            });

            Navigator.pushNamed(
              context,
              '/complaint/submitted',
              arguments: {'ticket_ids': ticketIds},
            );
          }
        } else {
          _tampilMesej(hasil['mesej'] ?? "Gagal menyimpan data.");
        }
      } else {
        _tampilMesej("Ralat Pelayan Stream: Status ${responHasil.statusCode}");
      }
    } catch (e) {
      _tampilMesej("Ralat Sambungan Multipart Laragon: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _tampilMesej(String mesej) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesej)),
    );
  }

  Widget buildSubmissionItemCard({
    required String fullName,
    required String email,
    required String category,
    required String department,
    required String description,
    required String phoneNumber,
    required String attachmentName,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusTag(label: 'Complaint'),
              const Spacer(),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text('Edit',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy)),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text('Cancel',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ReviewField(label: 'Full Name', value: fullName)),
              const SizedBox(width: 16),
              Expanded(child: ReviewField(label: 'Email', value: email)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child:
                      ReviewField(label: 'Phone Number', value: phoneNumber)),
              const SizedBox(width: 16),
              Expanded(
                  child: ReviewField(label: 'Department', value: department)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: ReviewField(
                      label: 'Complaint Category', value: category)),
              const SizedBox(width: 16),
              Expanded(
                  child: ReviewField(
                      label: 'Assigned To', value: '$category Team')),
            ],
          ),
          const SizedBox(height: 14),
          ReviewField(label: 'Description', value: description),
          const SizedBox(height: 14),
          ReviewField(label: 'Attachment', value: attachmentName),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: PortalTopBar(
        title: 'UNIKL RCMP',
        subtitle: 'Help Desk System',
        trailing: TextButton.icon(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          ),
          icon: const Icon(Icons.close, size: 14, color: AppColors.navy),
          label: const Text('Close',
              style: TextStyle(color: AppColors.navy, fontSize: 12)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: FlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Confirm All Submissions',
                    style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                const Text(
                  "Review everything before sending — once submitted, these cannot be edited.",
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 20),
                const StepTracker(currentStep: 3),
                const SizedBox(height: 22),
                Text(
                  'ALL ITEMS IN THIS SUBMISSION (${_senaraiAduan.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (_senaraiAduan.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: Text(
                            'No complaints to submit. Please add another item.')),
                  ),
                ..._senaraiAduan.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> aduan = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: buildSubmissionItemCard(
                      fullName:
                          _safeLiveName, // DINAMIK: Mengikut emel login semasa!
                      email:
                          _safeLiveEmail, // DINAMIK: Mengikut emel login semasa!
                      category: aduan['category'] ?? 'No Category',
                      department: aduan['department'] ?? 'No Department',
                      description: aduan['description'] ?? 'No Description',
                      phoneNumber: aduan['phone_number'] ?? 'No Phone Number',
                      attachmentName:
                          aduan['attachment_name'] ?? 'No attachment',
                      onEdit: () {
                        Navigator.pushNamed(context, '/complaint/fill',
                            arguments: aduan);
                      },
                      onCancel: () => _tampilDialogPadam(index),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                const InfoBanner(
                  tone: BannerTone.warning,
                  title:
                      'Once you click Submit All, all items above will be submitted and cannot be changed.',
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SecondaryButton(
                      label: 'Add Another',
                      icon: Icons.add,
                      onPressed: _bukaDialogAddAnother,
                    ),
                    _isSending
                        ? const CircularProgressIndicator()
                        : SuccessButton(
                            label: 'Submit All',
                            icon: Icons.send_outlined,
                            onPressed: () {
                              _simpanSemuaAduanKeDatabase();
                            },
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
