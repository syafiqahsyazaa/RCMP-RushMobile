import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import 'add_vendor_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../main.dart';

const _adminNavItems = [
  AdminNavItem(Icons.dashboard_outlined, 'Dashboard', '/admin/dashboard'),
  AdminNavItem(Icons.confirmation_number_outlined, 'All Tickets', '/admin/tickets'),
  AdminNavItem(Icons.people_outline, 'Manage Users', '/admin/users'),
  AdminNavItem(Icons.storefront_outlined, 'Manage Vendors', '/admin/vendors'),
  AdminNavItem(Icons.category_outlined, 'Categories', '/admin/categories'),
  AdminNavItem(Icons.bar_chart_outlined, 'Reports & Analytics', '/admin/reports'),
];

class AdminManageVendorsScreen extends StatefulWidget {
  const AdminManageVendorsScreen({super.key});

  @override
  State<AdminManageVendorsScreen> createState() => _AdminManageVendorsScreenState();
}

class _AdminManageVendorsScreenState extends State<AdminManageVendorsScreen> {
  List<dynamic> _senaraiSemuaVendors = [];
  List<dynamic> _senaraiVendorsDipaparkan = [];
  bool _isLoading = true;

  String _currentEmailLive = '';
  String _namaJabatanLive = 'Loading Department...';
  bool _isDeptInitializedLive = false;

  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All Status';
  String _selectedStateFilter = 'All States';

  int _countAll = 0;
  int _countPending = 0;
  int _countActive = 0;
  int _countSuspended = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDeptInitializedLive) {
      try {
        final Map<String, dynamic>? argumentsPetaLogin = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        setState(() {
          _currentEmailLive = (argumentsPetaLogin?['email'] ?? currentLoggedInUserEmail).toString().trim();
          String labelJabatanMentah = (argumentsPetaLogin?['departmentLabel'] ?? 'Loading...').toString();
          if (labelJabatanMentah.contains('·')) {
            _namaJabatanLive = labelJabatanMentah.split('·')[0].trim();
          } else {
            _namaJabatanLive = labelJabatanMentah.trim();
          }
        });
      } catch (e) {
        _currentEmailLive = currentLoggedInUserEmail;
        _namaJabatanLive = 'Administration Department';
      }
      _tarikDataVendorsDariLaragon();
      _isDeptInitializedLive = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _tarikDataVendorsDariLaragon() async {
    final String domain = kIsWeb ? 'localhost' : '10.0.2.2';
    String resolvedDept = _namaJabatanLive;

    if (resolvedDept == 'Loading...') {
      try {
        final deptUrl = Uri.parse('http://$domain/helpdesk_api/get_admin_dashboard.php?email=$_currentEmailLive');
        final deptRespon = await http.get(deptUrl);
        if (deptRespon.statusCode == 200) {
          final Map<String, dynamic> deptData = json.decode(deptRespon.body);
          String fullLabel = deptData['department_label'] ?? 'Unknown Department';
          if (fullLabel.contains('·')) {
            resolvedDept = fullLabel.split('·')[0].trim();
          } else {
            resolvedDept = fullLabel.trim();
          }
          setState(() { _namaJabatanLive = resolvedDept; });
        }
      } catch (e) { print("Gagal tarik info jabatan fallback: $e"); }
    }

    final url = Uri.parse('http://$domain/helpdesk_api/get_vendors.php?email=$_currentEmailLive&department=${Uri.encodeComponent(resolvedDept)}&b_cache=${DateTime.now().millisecondsSinceEpoch}');

    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final List<dynamic> dataDiterima = json.decode(respon.body);
        setState(() {
          _senaraiSemuaVendors = dataDiterima;
          _senaraiVendorsDipaparkan = dataDiterima;
          senaraiVendorGlobalJabatanSyafiqah = List.from(dataDiterima);
          _countAll = dataDiterima.length;
          _countPending = dataDiterima.where((v) => v['status'] == 'pending').length;
          _countActive = dataDiterima.where((v) => v['status'] == 'active' || v['status'] == 'approved').length;
          _countSuspended = dataDiterima.where((v) => v['status'] == 'suspended').length;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Ralat: $e");
      setState(() => _isLoading = false);
    }
  }

  // =========================================================================
  //  PENAPIS GABUNGAN: INTERLOCKING KOTAK SEARCH & KAD STATISTIK ATAS
  // =========================================================================
  void _jalankanPenapisanDinamikLive() {
    String kataKunci = _searchController.text.trim().toLowerCase();

    setState(() {
      _senaraiVendorsDipaparkan = _senaraiSemuaVendors.where((vendor) {
        // filter berdasarkan Kotak Taip Input Carian (Search Text)
        bool matchSearch = (vendor['company_name'] ?? '').toString().toLowerCase().contains(kataKunci) ||
            (vendor['email'] ?? '').toString().toLowerCase().contains(kataKunci) ||
            (vendor['phone'] ?? '').toString().contains(kataKunci);

        // filter berdasarkan 4 Kad Statistik Atas
        String statusSyarikatRaw = (vendor['status'] ?? 'active').toString().toLowerCase().trim();
        bool matchStatusCard = true;

        if (_selectedStatusFilter == 'Pending') {
          matchStatusCard = (statusSyarikatRaw == 'pending');
        } else if (_selectedStatusFilter == 'Active') {
          matchStatusCard = (statusSyarikatRaw == 'active' || statusSyarikatRaw == 'approved');
        } else if (_selectedStatusFilter == 'Suspended') {
          matchStatusCard = (statusSyarikatRaw == 'suspended' || statusSyarikatRaw == 'inactive');
        }

        return matchSearch && matchStatusCard;
      }).toList();
    });
    print("VENDOR MATRIX SYNCED: Card [$_selectedStatusFilter] | Keyword: '$kataKunci'");
  }


  void _bukaBorangAddVendorDanRefresh() async {
    await showDialog(
      context: context,
      builder: (context) => AddVendorDialog(department: _namaJabatanLive),
    );
    _tarikDataVendorsDariLaragon();
  }

  void _pamerSiasatSahkanDeleteDialog(String idVendor, String namaSyarikat) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove $namaSyarikat?'),
          content: Text('Are you sure you want to remove this vendor from $_namaJabatanLive?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _eksekusiPadamVendorDariLaragon(idVendor, namaSyarikat);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future _eksekusiUpdateVendorKeLaragon({required String id, required String company, required String addr, required String cty, required String stt, required String post, required String phn, required String statusText, required String password, required String pName, required String pPos, required String pPhn}) async {
    final String domain = kIsWeb ? 'localhost' : '10.0.2.2';
    final url = Uri.parse('http://$domain/helpdesk_api/update_vendor_profile.php');
    try {
      final respon = await http.post(url, headers: {"Content-Type": "application/json"}, body: json.encode({"vendor_id": id, "company_name": company, "address": addr, "city": cty, "state": stt, "postcode": post, "phone": phn, "status": statusText, "new_password": password, "pic_name": pName, "pic_position": pPos, "pic_phone": pPhn}));
      if (respon.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully!')));
        _tarikDataVendorsDariLaragon();
      }
    } catch (e) { print("Error: $e"); }
  }

  Future _eksekusiPadamVendorDariLaragon(String id, String nama) async {
    final String domain = kIsWeb ? 'localhost' : '10.0.2.2';
    final url = Uri.parse('http://$domain/helpdesk_api/delete_vendor.php?vendor_id=$id');
    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nama removed.')));
        _tarikDataVendorsDariLaragon();
      }
    } catch (e) { print("Error: $e"); }
  }

  // =========================================================================
  // FUNGSI DIALOG POPUP EDIT PROFIL VENDOR JABATAN 📝
  // =========================================================================
  void _pamerDialogEditVendor(Map<String, dynamic> vendorSemasa) {
    final companyNameCtrl = TextEditingController(text: vendorSemasa['company_name']);
    final addressCtrl = TextEditingController(text: vendorSemasa['address'] ?? '');
    final cityCtrl = TextEditingController(text: vendorSemasa['city'] ?? '');
    final stateCtrl = TextEditingController(text: vendorSemasa['state'] ?? '');
    final postcodeCtrl = TextEditingController(text: vendorSemasa['postcode'] ?? '');
    final phoneCtrl = TextEditingController(text: vendorSemasa['phone'] ?? '');
    final picNameCtrl = TextEditingController(text: vendorSemasa['pic_name'] ?? '');
    final picPositionCtrl = TextEditingController(text: vendorSemasa['pic_position'] ?? '');
    final picPhoneCtrl = TextEditingController(text: vendorSemasa['pic_phone'] ?? '');
    final newPasswordCtrl = TextEditingController();
    String statusSemasaLive = (vendorSemasa['status'] ?? 'active').toString().toLowerCase() == 'suspended' ? 'Suspended' : 'Active';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: AppColors.navy, size: 22),
                          const SizedBox(width: 6),
                          const Expanded(child: Text('Edit Vendor Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                          IconButton(icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted), onPressed: () => Navigator.pop(dialogContext)),
                        ],
                      ),
                      const Divider(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSafeEditField(label: 'Company Name', ctrl: companyNameCtrl, icon: Icons.storefront_outlined),
                              const SizedBox(height: 12),
                              _buildSafeEditField(label: 'Address', ctrl: addressCtrl, icon: Icons.location_on_outlined),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildSafeEditField(label: 'City', ctrl: cityCtrl, icon: Icons.location_city_outlined)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildSafeEditField(label: 'State', ctrl: stateCtrl, icon: Icons.map_outlined)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildSafeEditField(label: 'Postcode', ctrl: postcodeCtrl, icon: Icons.markunread_mailbox_outlined, type: TextInputType.number)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildSafeEditField(label: 'Phone *', ctrl: phoneCtrl, icon: Icons.call_outlined, type: TextInputType.phone)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildSafeEditField(label: 'New Password (Optional)', ctrl: newPasswordCtrl, icon: Icons.lock_reset_outlined, obscure: true),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text("Account Status:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 14),
                                  ChoiceChip(
                                    label: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    selected: statusSemasaLive == 'Active',
                                    selectedColor: const Color(0xFFEAF7EE),
                                    onSelected: (bool selected) { if (selected) setDialogState(() => statusSemasaLive = 'Active'); },
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Suspended', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    selected: statusSemasaLive == 'Suspended',
                                    selectedColor: const Color(0xFFFFECE5),
                                    onSelected: (bool selected) { if (selected) setDialogState(() => statusSemasaLive = 'Suspended'); },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              _eksekusiUpdateVendorKeLaragon(
                                id: vendorSemasa['vendor_id'].toString(),
                                company: companyNameCtrl.text.trim(),
                                addr: addressCtrl.text.trim(),
                                cty: cityCtrl.text.trim(),
                                stt: stateCtrl.text.trim(),
                                post: postcodeCtrl.text.trim(),
                                phn: phoneCtrl.text.trim(),
                                statusText: statusSemasaLive == 'Active' ? 'active' : 'suspended',
                                password: newPasswordCtrl.text.trim(),
                                pName: picNameCtrl.text.trim(),
                                pPos: picPositionCtrl.text.trim(),
                                pPhn: picPhoneCtrl.text.trim(),
                              );
                            },
                            child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper widget textfield builder
  Widget _buildSafeEditField({required String label, required TextEditingController ctrl, required IconData icon, TextInputType type = TextInputType.text, bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl, keyboardType: type, obscureText: obscure,
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            fillColor: Colors.white, filled: true,
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      drawer: PortalNavDrawer(
        departmentLabel: '$_namaJabatanLive · Admin',
        currentRoute: '/admin/vendors',
        items: _adminNavItems,
        staffName: (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['full_name'] ?? "Admin UniKL",
        role: (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['role'] ?? "Admin",
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Manage Vendors $_namaJabatanLive', style: const TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: _bukaBorangAddVendorDanRefresh, icon: const Icon(Icons.add_business, color: AppColors.navy))],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(10),
        children: [
          // =========================================================================
          // BARISAN 4 KAD STATISTIK (TAPISAN REAL-TIME)
          // =========================================================================
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, shrinkWrap: true, childAspectRatio: 2.1, physics: const NeverScrollableScrollPhysics(),
            children: [
              // 1. KAD ALL VENDORS
              GestureDetector(
                onTap: () {
                  setState(() { _selectedStatusFilter = 'All Status'; });
                  _jalankanPenapisanDinamikLive();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _selectedStatusFilter == 'All Status' ? AppColors.navy : Colors.transparent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StatMiniCard(value: '$_countAll', label: 'All Vendors', icon: Icons.storefront_outlined),
                ),
              ),
              // 2. KAD PENDING VENDORS
              GestureDetector(
                onTap: () {
                  setState(() { _selectedStatusFilter = 'Pending'; });
                  _jalankanPenapisanDinamikLive();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _selectedStatusFilter == 'Pending' ? Colors.orange : Colors.transparent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StatMiniCard(value: '$_countPending', label: 'Pending', icon: Icons.hourglass_empty, color: Colors.orange),
                ),
              ),
              // 3. KAD ACTIVE VENDORS
              GestureDetector(
                onTap: () {
                  setState(() { _selectedStatusFilter = 'Active'; });
                  _jalankanPenapisanDinamikLive();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _selectedStatusFilter == 'Active' ? Colors.green : Colors.transparent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StatMiniCard(value: '$_countActive', label: 'Active', icon: Icons.check_circle_outline, color: Colors.green),
                ),
              ),
              // 4. KAD SUSPENDED VENDORS
              GestureDetector(
                onTap: () {
                  setState(() { _selectedStatusFilter = 'Suspended'; });
                  _jalankanPenapisanDinamikLive();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _selectedStatusFilter == 'Suspended' ? Colors.red : Colors.transparent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StatMiniCard(value: '$_countSuspended', label: 'Suspended', icon: Icons.block_outlined, color: Colors.red),
                ),
              ),
            ],
          ),



          // =========================================================================
          //  KOTAK INPUT SEARCH BOX
          // =========================================================================
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _jalankanPenapisanDinamikLive(), // Auto-tapis sewaktu menaip huruf
              style: const TextStyle(fontSize: 12.5),
              decoration: InputDecoration(
                hintText: 'Search company, email, phone number...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                fillColor: AppColors.pageBackground,
                filled: true,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // =========================================================================
          // ENGINE RENDERING LOOP KAD KAD VENDOR LIVE JABATAN
          // =========================================================================
          _senaraiVendorsDipaparkan.isEmpty
              ? Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: const Column(
              children: [
                Icon(Icons.storefront_outlined, size: 28, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text('No matching vendors found.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          )
              : Column(
            children: _senaraiVendorsDipaparkan.map((vendor) {

              String compName = vendor['company_name'] ?? 'Syarikat Vendor';
                    String compMail = vendor['email'] ?? 'No Email';
                    String compPhone = vendor['phone'] ?? 'No Phone';
              String statusMentahDariDatabase = (vendor['status'] ?? vendor['account_status'] ?? 'active').toString().trim().toLowerCase();

              // Kita pastikan string dipulangkan dalam format CAPITALIZED
              String statusSyarikat = 'ACTIVE';
              if (statusMentahDariDatabase == 'suspended' || statusMentahDariDatabase == 'inactive' || statusMentahDariDatabase == 'suspend') {
                statusSyarikat = 'SUSPENDED';
              } else if (statusMentahDariDatabase == 'pending') {
                statusSyarikat = 'PENDING';
              }String tarikhMentah = vendor['created_at'] ?? '';
                    String tarikhDipapar = tarikhMentah;

                    if (tarikhMentah.length > 10) {
                      tarikhDipapar = tarikhMentah.substring(8, 10) + "/" + tarikhMentah.substring(5, 7) + "/" + tarikhMentah.substring(0, 4);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))]),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.navy.withOpacity(0.1),
                            child: const Icon(Icons.storefront_outlined, size: 18, color: AppColors.navy),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(compName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),


                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: statusSyarikat == 'ACTIVE'
                                              ? const Color(0xFFEAF7EE) // Hijau Lembut untuk Active
                                              : const Color(0xFFFDF2F2), // Merah Lembut untuk Suspended/Inactive!
                                          borderRadius: BorderRadius.circular(6)),
                                      child: Text(
                                          statusSyarikat,
                                          style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: statusSyarikat == 'ACTIVE'
                                                  ? const Color(0xFF2E9E52) // Teks Hijau
                                                  : const Color(0xFFD64545) // Teks Merah
                                          )
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('✉️ $compMail', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text('📞 $compPhone', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_month_outlined, size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('REGISTERED: $tarikhDipapar', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blueGrey),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _pamerDialogEditVendor(vendor),
                                        ),
                                        const SizedBox(width: 14),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            _pamerSiasatSahkanDeleteDialog(vendor['vendor_id'].toString(), compName);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
