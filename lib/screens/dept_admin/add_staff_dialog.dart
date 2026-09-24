import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../main.dart';

Future<void> showAddStaffDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return const _AddStaffDialogContent();
    },
  );
}

class _AddStaffDialogContent extends StatefulWidget {
  const _AddStaffDialogContent();

  @override
  State<_AddStaffDialogContent> createState() => _AddStaffDialogContentState();
}

class _AddStaffDialogContentState extends State<_AddStaffDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // DROPDOWN CATEGORY
  String? _selectedCategory;
  List<String> _categoriesOptions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCategoriesDropdown(); // Auto-load kategori sebaik sahaja dialog dibuka
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //  FUNGSI fetch KATEGORI LIVE DARI DATABASE
  Future<void> _loadCategoriesDropdown() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_dropdowns.php?email=$currentLoggedInUserEmail');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _categoriesOptions = List<String>.from(data['categories'] ?? []);
          if (_categoriesOptions.isNotEmpty) {
            _selectedCategory =
                _categoriesOptions.first; // Set item pertama sebagai default
          }
        });
      }
    } catch (e) {
      print("Error filling categories dropdown: $e");
    }
  }

  Future<void> _simpanStaffBaharu() async {
    if (_codeController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty) {
      _tampilMesej("Please fill in at least Staff Code and Full Name!");
      return;
    }

    setState(() => _isSaving = true);
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse('http://$domain/helpdesk_api/add_staff.php');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "staff_code": _codeController.text.trim(),
          "full_name": _nameController.text.trim(),
          "email": _emailController.text.trim().isEmpty
              ? "${_codeController.text.trim()}@unikl.edu.my"
              : _emailController.text.trim(),
          "phone": _phoneController.text.trim(),
          "password": _passwordController.text.trim().isEmpty
              ? "password123"
              : _passwordController.text.trim(),
          // HANTAR KATEGORI DIPILIH KE PHP
          "category": _selectedCategory ?? '',
          "admin_email": currentLoggedInUserEmail,
        }),
      );

      if (response.statusCode == 200) {
        final hasil = json.decode(response.body);
        if (hasil['status'] == 'berjaya') {
          if (mounted) {
            Navigator.pop(context); // Tutup dialog
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(hasil['mesej'])));
          }
        } else {
          _tampilMesej(hasil['mesej'] ?? "Failed to insert record.");
        }
      }
    } catch (e) {
      _tampilMesej("Connection Failure: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _tampilMesej(String mesej) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesej)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add New Staff Account',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy)),
                    IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),

                // Staff Code Input
                const Text('Staff Code *',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _codeController,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                      hintText: 'e.g. 10099',
                      contentPadding: EdgeInsets.all(10),
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                // Full Name Input
                const Text('Full Name *',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                      hintText: 'Full name as per ID',
                      contentPadding: EdgeInsets.all(10),
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                // Email & Phone Grid
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Email',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                                hintText: 'staff@unikl.edu.my',
                                contentPadding: EdgeInsets.all(10),
                                border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Phone',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                                hintText: 'e.g. 0127001007',
                                contentPadding: EdgeInsets.all(10),
                                border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Password Input
                const Text('Account Password *',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                      hintText: 'Default password handle',
                      contentPadding: EdgeInsets.all(10),
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),

                // REKA BENTUK DROPDOWN CATEGORY DI DALAM UI DIALOG
                LabeledDropdown(
                  label: 'Assign Operational Track Category *',
                  hint: _selectedCategory ?? 'Select track track',
                  items: _categoriesOptions,
                  value: _categoriesOptions.contains(_selectedCategory)
                      ? _selectedCategory
                      : null,
                  onChanged: (v) {
                    setState(() {
                      _selectedCategory = v;
                    });
                  },
                ),
                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    _isSaving
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: Colors.white),
                            onPressed: _simpanStaffBaharu,
                            child: const Text('Add Staff Account',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
