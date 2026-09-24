import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../main.dart';

Future<void> showEditStaffDialog(
    BuildContext context, {
      required String staffName,
      required String staffCode,
      required String email,
      required String phone,
      required String password,
      required String status,
      required String category,
    }) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return _EditStaffDialogContent(
        staffName: staffName,
        staffCode: staffCode,
        email: email,
        phone: phone == '—' ? '' : phone,
        password: password,
        status: status,
        category: category,
      );
    },
  );
}

class _EditStaffDialogContent extends StatefulWidget {
  final String staffName;
  final String staffCode;
  final String email;
  final String phone;
  final String password;
  final String status;
  final String category;

  const _EditStaffDialogContent({
    required this.staffName,
    required this.staffCode,
    required this.email,
    required this.phone,
    required this.password,
    required this.status,
    required this.category,
  });

  @override
  State<_EditStaffDialogContent> createState() => _EditStaffDialogContentState();
}

class _EditStaffDialogContentState extends State<_EditStaffDialogContent> {
late TextEditingController _codeController;
late TextEditingController _nameController;
late TextEditingController _emailController;
late TextEditingController _phoneController;
late TextEditingController _passwordController;

late bool _isActive;
String? _selectedCategory;
List<String> _categoriesOptions = [];
bool _isSaving = false;

@override
void initState() {
super.initState();
_codeController = TextEditingController(text: widget.staffCode);
_nameController = TextEditingController(text: widget.staffName);
_emailController = TextEditingController(text: widget.email);
_phoneController = TextEditingController(text: widget.phone);
_passwordController = TextEditingController();

_isActive = widget.status.toLowerCase() == 'active';
_selectedCategory = widget.category;
_loadCategoriesDropdown();
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

Future<void> _loadCategoriesDropdown() async {
final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
final url = Uri.parse('http://$domain/helpdesk_api/get_dropdowns.php?email=$currentLoggedInUserEmail');
try {
final response = await http.get(url);
if (response.statusCode == 200) {
final Map<String, dynamic> data = json.decode(response.body);
setState(() {
_categoriesOptions = List<String>.from(data['categories'] ?? []);
if (!_categoriesOptions.contains(_selectedCategory)) {
_selectedCategory = _categoriesOptions.isNotEmpty ? _categoriesOptions.first : null;
}
});
}
} catch (e) { print("Error: $e"); }
}

Future<void> _saveStaffEdits() async {
if (_codeController.text.trim().isEmpty || _nameController.text.trim().isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff Code and Name fields cannot be blank!')));
return;
}

setState(() => _isSaving = true);
final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
final url = Uri.parse('http://$domain/helpdesk_api/edit_staff.php');

try {
final response = await http.post(
url,
headers: {"Content-Type": "application/json"},
body: json.encode({
"old_staff_code": widget.staffCode,
"staff_code": _codeController.text.trim(),
"full_name": _nameController.text.trim(),
"email": _emailController.text.trim(),
"phone": _phoneController.text.trim(),
"password": _passwordController.text.trim().isEmpty ? widget.password : _passwordController.text.trim(),
"status": _isActive ? 'active' : 'inactive',
"category": _selectedCategory ?? '',
}),
);

if (response.statusCode == 200) {
final resData = json.decode(response.body);
if (resData['status'] == 'berjaya') {
if (mounted) {
Navigator.pop(context);
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resData['mesej'])));
}
}
}
} catch (e) { print("Error: $e"); }
finally { if (mounted) setState(() => _isSaving = false); }
}

@override
Widget build(BuildContext context) {
return Dialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
child: Container(
width: 460,
padding: const EdgeInsets.all(20),
child: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text('Edit User Profile & Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
],
),
const Divider(),
const SizedBox(height: 10),
const Text('Staff Code *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
const SizedBox(height: 6),
TextFormField(
controller: _codeController,
style: const TextStyle(fontSize: 12),
decoration: const InputDecoration(contentPadding: EdgeInsets.all(10), border: OutlineInputBorder()),
),
const SizedBox(height: 12),
const Text('Full Name *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
const SizedBox(height: 6),
TextFormField(
controller: _nameController, style: const TextStyle(fontSize: 12),
decoration: const InputDecoration(contentPadding: EdgeInsets.all(10), border: OutlineInputBorder()),
),
const SizedBox(height: 12),

Row(
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('Email *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
const SizedBox(height: 6),
TextFormField(
controller: _emailController, style: const TextStyle(fontSize: 12),
decoration: const InputDecoration(contentPadding: EdgeInsets.all(10), border: OutlineInputBorder()),
),
],
),
),
const SizedBox(width: 12),
  Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Edit Password *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          style: const TextStyle(fontSize: 12),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.all(10),
            border: OutlineInputBorder(),
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    ),
  ),
],
),
const SizedBox(height: 12),
const Text('Phone Number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
const SizedBox(height: 6),
TextFormField(
controller: _phoneController,
style: const TextStyle(fontSize: 12),
decoration: const InputDecoration(hintText: 'e.g. 0127001007', contentPadding: EdgeInsets.all(10), border: OutlineInputBorder()),
),
const SizedBox(height: 12),

LabeledDropdown(
label: 'Assigned Category Operations', hint: _selectedCategory ?? 'Select operational track',
items: _categoriesOptions, value: _categoriesOptions.contains(_selectedCategory) ? _selectedCategory : null,
onChanged: (v) { setState(() { _selectedCategory = v; }); },
),
const SizedBox(height: 14),
const Text('Account Activation Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
const SizedBox(height: 8),
SizedBox(
width: double.infinity,
child: OutlinedButton.icon(
style: OutlinedButton.styleFrom(
backgroundColor: _isActive ? const Color(0xFFEAF7EE) : const Color(0xFFFDF2F2),
side: BorderSide(color: _isActive ? const Color(0xFF2E9E52) : const Color(0xFFD64545)),
padding: const EdgeInsets.symmetric(vertical: 12),),
onPressed: () => setState(() => _isActive = !_isActive),
icon: Icon(
_isActive ? Icons.check_circle : Icons.cancel,
size: 16,
color: _isActive ? const Color(0xFF2E9E52) : const Color(0xFFD64545)
),
label: Text(
_isActive ? 'ACCOUNT STATUS: ACTIVE (Click to Change)' : 'ACCOUNT STATUS: INACTIVE (Click to Change)',
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.bold,
color: _isActive ? const Color(0xFF2E9E52) : const Color(0xFFD64545)
),
),
),
),
const SizedBox(height: 22),
Row(
mainAxisAlignment: MainAxisAlignment.end,
children: [
  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style:
TextStyle(color: Colors.grey))),
const SizedBox(width: 10),
_isSaving
? const CircularProgressIndicator()
: ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor:
Colors.white),
onPressed: _saveStaffEdits,
child: const Text('Save Changes', style: TextStyle(fontSize: 12,
fontWeight: FontWeight.bold)),
),
],)],),),),);}}