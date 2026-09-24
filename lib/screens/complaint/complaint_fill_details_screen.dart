import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart'; // Untuk fungsi attach gambar fizikal
import '../../theme/app_theme.dart';
import '../../main.dart';

/// Interface 5: "Submit a Complaint" — Step 1: Fill Details.
class ComplaintFillDetailsScreen extends StatefulWidget {
  const ComplaintFillDetailsScreen({super.key});

  @override
  State<ComplaintFillDetailsScreen> createState() => _ComplaintFillDetailsScreenState();
}

class _ComplaintFillDetailsScreenState extends State<ComplaintFillDetailsScreen> {
// Pengurus data input dari kotak teks
final TextEditingController _descriptionController = TextEditingController();
final TextEditingController _phoneNumberController = TextEditingController();

// Status Tab Jabatan Terpilih (0 = IT, 1 = Maintenance, 2 = Admin)
int _activeTab = 0;
final List<String> _departmentsTabs = [
'Information Technology',
'Maintenance',
'Admin & Facilities Mgmt'
];

// Senarai dinamik yang ditarik dari database Laragon
List<String> _listCategories = [];
List<String> _listDepartments = [];

// Menyimpan nilai pilihan dropdown pengguna
String? _selectedCategory;
String? _selectedDepartment;

// Mengurus fail lampiran gambar
String _namaGambarSelected = 'No file attached';
PlatformFile? _attachedFile;

bool _isLoading = true;

  // function: get data hantaran login dan auto-rolling tab live
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      // get wrap arguments 'selected_dept' yang dihantar dari skrin login
      final Object? args = ModalRoute.of(context)?.settings.arguments;

      if (args != null && args is Map<String, dynamic>) {
        String chosenDept = (args['selected_dept'] ?? 'it').toString().toLowerCase().trim();

        // 2. AUTO-SET NILAI JABATAN IKUT KETUKAN USER DARI SKRIN DEPAN!
        if (chosenDept == 'maintenance') {
          _activeTab = 1; // Auto-pusing tukar skrin ke tab Maintenance!
        } else if (chosenDept == 'administration & facilities' || chosenDept == 'admin') {
          _activeTab = 2; // Auto-pusing tukar skrin ke tab Admin!
        } else {
          _activeTab = 0; // Kekal di tab IT
        }

        // 3. SELEPAS TUKAR TAB, WAJIB PAKSA ENJIN TARIK DATA DROPDOWN BARU DARI LARAGON!
        _ambilDataDropdown(_departmentsTabs[_activeTab]);

        print("INDEKS TAB BORONG AUTO-DIKUNCI PADA: $_activeTab UNTUK JABATAN: $chosenDept");
      }
      _isInitialized = true;
    }
  }


@override
void initState() {
super.initState();
}

@override
void dispose() {
_descriptionController.dispose();
_phoneNumberController.dispose();
super.dispose();
}

// Fungsi memanggil API Laragon mengikut jabatan terpilih menggunakan kIsWeb IP dinamik
Future<void> _ambilDataDropdown(String namaJabatan) async {
setState(() => _isLoading = true);

final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
final url = Uri.parse('http://$domain/helpdesk_api/get_dropdowns.php?department=$namaJabatan');

try {
final respon = await http.get(url);

if (respon.statusCode == 200) {
final Map<String, dynamic> data = json.decode(respon.body);

setState(() {
_listCategories = List<String>.from(data['categories']);
_listDepartments = List<String>.from(data['departments']);
_selectedCategory = null; // Reset pilihan kategori lama setiap kali tab berubah
_isLoading = false;
});
} else {
print("Gagal muat data dropdown. Status: ${respon.statusCode}");
setState(() => _isLoading = false);
}
} catch (e) {
print("Ralat sambungan ke Laragon: $e");
setState(() => _isLoading = false);
}
}

  // ===  SATU FUNGSI UNTUK SEMUA PLATFORM (WEB + MOBILE) ===
  Future<void> _pilihGambarFizikal() async {
    try {
      // FilePicker automatic bukak explorer Chrome kalau Web
      // bukak file picker Android kalau running kat Emulator
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          // Sistem auto-get: kalau web dia ambil bytes, kalau mobile dia ambil path fizikal
          _attachedFile = result.files.first;
          _namaGambarSelected = result.files.first.name;
        });
        print("Fail Berjaya Dipilih Secara Live: $_namaGambarSelected");
      }
    } catch (e) {
      print("Ralat Pengecam Fail Universal: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka pemilih fail: $e')),
        );
      }
    }
  }




// kumpul data dan menghantar pengguna ke skrin Preview & Review
  void _hantarKePreview() {
    String description = _descriptionController.text.trim();
    String phoneNumber = _phoneNumberController.text.trim();
    String category = _selectedCategory ?? '';
    String department = _selectedDepartment ?? '';

    if (category.isEmpty || description.isEmpty || department.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SLA & policy — Sila isi semua ruangan yang wajib (*)!')),
      );
      return;
    }

    final Object? args = ModalRoute.of(context)?.settings.arguments;
    bool isAddAnother = false;
    if (args != null && args is Map<String, dynamic>) {
      isAddAnother = args['isAddAnother'] ?? false;
    }

    // KUNCI KESELAMATAN SESSION VIVA: Ambil email dari global variable main.dart
    String safeLiveEmail = currentLoggedInUserEmail ?? 'user@gmail.com';

    // Auto-jana nama depan yang kacak berasaskan text email sebelum abjad
    String safeLiveName = safeLiveEmail.contains('@')
        ? safeLiveEmail.split('@')[0].toUpperCase().replaceAll('.', ' ').replaceAll('_', ' ')
        : 'USER COMPLAINANT';

    String? pathFizikalSelamat = kIsWeb ? null : _attachedFile?.path;


    Map<String, dynamic> dataBorangBaru = {
      'category': category,
      'description': description,
      'phone_number': phoneNumber,
      'department': department,

      //apply DINAMIK:  kalis data statik!
      'full_name': safeLiveName,
      'email': safeLiveEmail,

      'isAddAnother': isAddAnother,
      'attachment_path': _namaGambarSelected,

      'attachment_file_bytes': _attachedFile?.bytes, // Untuk capture di Chrome Web
      'attachment_file_path': kIsWeb ? null : _attachedFile?.path,
    };

    Navigator.pushNamed(
      context,
      '/complaint/preview',
      arguments: dataBorangBaru,
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
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false),
          icon: const Icon(Icons.close, size: 14, color: AppColors.navy),
          label: const Text('Close', style: TextStyle(color: AppColors.navy, fontSize: 12)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: FlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === 3 BUTANG JABATAN DI BAHAGIAN ATAS CARD ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton(0, 'IT', Icons.computer),
                    _buildTabButton(1, 'Maintenance', Icons.build_outlined),
                    _buildTabButton(2, 'Admin', Icons.apartment),
                  ],
                ),
                const SizedBox(height: 18),

                const Text('Submit a Complaint', style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(
                  'Fill the details and your assigned ${_departmentsTabs[_activeTab]} department will attend to your request.',
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 20),
                const StepTracker(currentStep: 1),
                const SizedBox(height: 22),
                const InfoBanner(
                  tone: BannerTone.success,
                  title: 'SLA & policy — your complaint will be acknowledged shortly',
                  subtitle: 'Open Mon–Fri, 8am–5pm  ·  Current average response: 24 hours',
                ),
                const SizedBox(height: 24),
                const SectionHeading(
                  title: 'Complaint Details',
                  subtitle: 'Provide details about the incident and procedure.',
                ),
                const SizedBox(height: 14),

                // Dropdown Category Dinamik (Auto-filter ikut tab jabatan aktif)
                _isLoading
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Center(child: LinearProgressIndicator()),
                )
                    : LabeledDropdown(
                  label: 'Category',
                  hint: 'Select Category',
                  required: true,
                  items: _listCategories,
                  value: _selectedCategory,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Kotak Teks Input Description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Description', style: AppTextStyles.fieldLabel),
                        Text(' *', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describe your issue here',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.fieldBackground,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Attachment', style: AppTextStyles.fieldLabel),
                    const SizedBox(width: 6),
                    Text('(optional)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 6),

                // === KOTAK pilih ATTACH gambar  ===
                InkWell(
                  onTap: _pilihGambarFizikal,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.fieldBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_attachedFile != null ? Icons.image : Icons.cloud_upload_outlined,
                            size: 20, color: AppColors.navy),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _namaGambarSelected,
                            style: TextStyle(
                                fontSize: 13,
                                color: _attachedFile != null ? AppColors.navy : AppColors.textMuted,
                                fontWeight: _attachedFile != null ? FontWeight.bold : FontWeight.normal
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const SectionHeading(title: 'Your Information'),
                const SizedBox(height: 14),

                // Kotak Teks Input Phone Number
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Phone Number', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+60 1X-XXXXXXX',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.call_outlined, size: 18, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.fieldBackground,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Dropdown Department / Faculty
                LabeledDropdown(
                  label: 'My Department / Faculty',
                  hint: 'Select Department / Faculty',
                  required: true,
                  items: _listDepartments,
                  value: _selectedDepartment,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedDepartment = newValue;
                    });
                  },
                ),

                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SecondaryButton(
                      label: 'Cancel',
                      onPressed: () {
                        Navigator.pushNamed(context, '/dashboard');
                      },
                    ),
                    const SizedBox(width: 12),
                    SuccessButton(
                      label: 'Preview & Review',
                      icon: Icons.arrow_forward,
                      onPressed: _hantarKePreview,
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

  // Fungsi  gaya visual reka bentuk 3 Butang Jabatan di Atas Kad
  Widget _buildTabButton(int index, String title, IconData icon) {
    bool isSelected = _activeTab == index;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _activeTab = index;
        });
        _ambilDataDropdown(_departmentsTabs[index]);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.navy : Colors.grey.shade100,
        foregroundColor: isSelected ? Colors.white : AppColors.textSecondary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
