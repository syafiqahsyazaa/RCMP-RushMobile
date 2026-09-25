import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import 'edit_category_dialog.dart';
import 'delete_category_dialog.dart';
import '../../main.dart';

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

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<dynamic> _categoriesList = [];
  bool _isLoading = true;
  bool _isAdding = false;

  String _namaJabatanLive = "Loading Department...";

  // Controller to harvest text directly from the inline form input
  final TextEditingController _categoryNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ambilSenaraiKategori();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  // GET: Fetch and sync all operational tracks live from database
  Future<void> _ambilSenaraiKategori() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_categories.php?email=$currentLoggedInUserEmail');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          _namaJabatanLive = data['department_label'] ?? 'IT Department';
          _categoriesList = data['categories'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading category pool: $e");
      setState(() => _isLoading = false);
    }
  }

  // 💡 POST: Insert new complaint track straight into categories table
  Future<void> _tambahKategoriBaharu() async {
    String textInput = _categoryNameController.text.trim();
    if (textInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please write a category name track first!')),
      );
      return;
    }

    setState(() => _isAdding = true);
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse('http://$domain/helpdesk_api/get_categories.php');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"category_name": textInput}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> resData = json.decode(response.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(resData['mesej'] ?? 'Done')));

        if (resData['status'] == 'berjaya') {
          _categoryNameController.clear(); // Clear the text input layout block
          _ambilSenaraiKategori(); // Refresh the list live on screen
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Connection error: $e")));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      bottomNavigationBar: PortalBottomNav(
        items: _adminNavItems,
        currentRoute: '/admin/categories',
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'lib/assets/images/unikl_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.shield, color: AppColors.navy),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_namaJabatanLive,
                style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const Text('Category Management',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _ambilSenaraiKategori,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '$_namaJabatanLive Categories',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const Text('Manage complaint categories',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 14),

                    // === 💡 LIVE GENERATED DATA ROW CARDS FROM MYSQL 💡 ===
                    ..._categoriesList.map((cat) {
                      String catId = (cat['category_id'] ?? '').toString();
                      String catName =
                          cat['category_name'] ?? 'Unnamed Category';
                      String dateInfo = "Created " + (cat['created_at'] ?? '');
                      int countLogs = cat['total_complaints'] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: DataRowCard(
                          title: catName,
                          subtitle: dateInfo,
                          trailingTag: StatusTag(
                              label: '$countLogs complaints',
                              background: const Color(0xFFEAF1FB),
                              foreground: const Color(0xFF2F5FA3)),
                          actions: [
                            IconTextAction(
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                                onTap: () async {
                                  await showEditCategoryDialog(
                                    context,
                                    categoryId: catId,
                                    categoryName: catName,
                                  );
                                  _ambilSenaraiKategori();
                                }),
                            IconTextAction(
                              icon: Icons.delete_outline,
                              label: 'Delete',
                              color: const Color(0xFFD64545),
                              onTap: () async {
                                await showDeleteCategoryDialog(context,
                                    categoryId: catId, categoryName: catName);
                                _ambilSenaraiKategori();
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // === INLINE ADD CATEGORY DATA ENTRY PACK CARD ===
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
                          const Text('Add Category',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 12),

                          // Harvest input parameters cleanly using controller
                          const Text('Category Name',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _categoryNameController,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'e.g. Hardware & Software Support',
                              prefixIcon:
                                  const Icon(Icons.category_outlined, size: 16),
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          _isAdding
                              ? const Center(child: CircularProgressIndicator())
                              : PrimaryButton(
                                  label: 'Add Category Track',
                                  icon: Icons.add,
                                  onPressed:
                                      _tambahKategoriBaharu, // Triggers database submission sequence
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
