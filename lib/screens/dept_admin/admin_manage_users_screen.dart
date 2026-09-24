import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import 'add_staff_dialog.dart';
import 'edit_staff_dialog.dart';
import 'delete_staff_dialog.dart';
import '../../main.dart';

const _adminNavItems = [
  AdminNavItem(Icons.dashboard_outlined, 'Dashboard', '/admin/dashboard'),
  AdminNavItem(Icons.confirmation_number_outlined, 'All Tickets', '/admin/tickets'),
  AdminNavItem(Icons.people_outline, 'Manage Users', '/admin/users'),
  AdminNavItem(Icons.storefront_outlined, 'Manage Vendors', '/admin/vendors'),
  AdminNavItem(Icons.category_outlined, 'Categories', '/admin/categories'),
  AdminNavItem(Icons.bar_chart_outlined, 'Reports & Analytics', '/admin/reports'),
];

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
List<dynamic> _allStaffList = []; // Menyimpan data asal daripada database
List<dynamic> _filteredStaffList = []; // Menyimpan data yang telah ditapis untuk dipaparkan
bool _isLoading = true;

String _namaJabatanLive = "Loading Department...";

// PENGURUS CARIAN & TAPISAN JAWATAN
final TextEditingController _searchController = TextEditingController();
String _selectedRoleFilter = 'All Roles';
final List<String> _roleOptions = ['All Roles', 'STAFF', 'ADMIN'];

@override
void initState() {
super.initState();
_ambilSenaraiStaff();
_searchController.addListener(_jalankanTapisanData);
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

Future<void> _ambilSenaraiStaff() async {
  final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
  final url = Uri.parse(
      'http://$domain/helpdesk_api/get_all_staff.php?email=$currentLoggedInUserEmail');

  try {
    final respon = await http.get(url);
    if (respon.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(respon.body);

      setState(() {
        _namaJabatanLive = data['department_label'] ?? 'IT Department · Admin';

        _allStaffList = data['staff'] ?? [];
        _filteredStaffList = data['staff'] ?? [];

        _isLoading = false;
      });
      _jalankanTapisanData();
    }
  } catch (e) {
    print("Ralat sambungan Laragon: $e");
    setState(() => _isLoading = false);
  }
}

//  CARIAN & TAPISAN UTAMA (LIVE FILTER)
void _jalankanTapisanData() {
String query = _searchController.text.toLowerCase().trim();

setState(() {
_filteredStaffList = _allStaffList.where((staff) {
String staffCode = (staff['staff_code'] ?? '').toString().toLowerCase();
String fullName  = (staff['full_name'] ?? '').toString().toLowerCase();
String email     = (staff['email'] ?? '').toString().toLowerCase();
String roleName  = (staff['role'] ?? 'Staff').toString().toUpperCase();

// Semakan syarat A: Mengandungi teks carian nama/email/kod
bool matchesSearch = fullName.contains(query) ||
email.contains(query) ||
staffCode.contains(query);

// Semakan syarat B: Menepati peranan (Sort by Role) dropdown terpilih
bool matchesRole = _selectedRoleFilter == 'All Roles' || roleName == _selectedRoleFilter;

return matchesSearch && matchesRole;
}).toList();
});
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.pageBackground,
drawer:  PortalNavDrawer(
departmentLabel: '$_namaJabatanLive · Admin',
currentRoute: '/admin/users',
items: _adminNavItems,
staffName: (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['full_name'] ?? "Staff Support",
role: (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['role'] ?? "Admin",
),
appBar: AppBar(
backgroundColor: Colors.white,
elevation: 0,
iconTheme: const IconThemeData(color: AppColors.navy),
title: const Text('Manage Users', style: TextStyle(color: AppColors.navy, fontSize: 14, fontWeight: FontWeight.w700)),
actions: [
Padding(
padding: const EdgeInsets.only(right: 12),
child: Center(
child: SizedBox(
height: 34,
child: ElevatedButton.icon(
onPressed: () async {
await showAddStaffDialog(context);
_ambilSenaraiStaff(); // Segarkan data selepas tambah user ditutup
},
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.navy, foregroundColor: Colors.white, elevation: 0,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
padding: const EdgeInsets.symmetric(horizontal: 12),
),
icon: const Icon(Icons.add, size: 15),
label: const Text('Add User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
),
),
),
),
],
),
body: SafeArea(
child: _isLoading
? const Center(child: CircularProgressIndicator())
: RefreshIndicator(
onRefresh: _ambilSenaraiStaff,
child: ListView(
padding: const EdgeInsets.all(16),
children: [
// UI BAR CARIAN & SUSUNAN TAPISAN BARU (SORT BY ROLE)
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(10),
border: Border.all(color: AppColors.border),
),
child: Column(
children: [
// Kotak Carian Input Teks Rasmi
TextField(
controller: _searchController,
style: const TextStyle(fontSize: 12.5),
decoration: InputDecoration(
hintText: 'Search name, email, code...',
prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
contentPadding: const EdgeInsets.symmetric(vertical: 10),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
filled: true,
fillColor: AppColors.pageBackground,
),
),
const SizedBox(height: 10),

// Dropdown "Sort by Role"
Row(
children: [
const Text('Sort by Role:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
const SizedBox(width: 10),
Expanded(
child: SizedBox(
height: 34,
child: DropdownButtonFormField<String>(
value: _selectedRoleFilter,
style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
decoration: InputDecoration(
contentPadding: const EdgeInsets.symmetric(horizontal: 10),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
),
items: _roleOptions.map((role) {
return DropdownMenuItem<String>(value: role, child: Text(role));
}).toList(),
onChanged: (newValue) {
if (newValue != null) {
setState(() {
_selectedRoleFilter = newValue;
});
_jalankanTapisanData(); // Segarkan senarai mengikut penapisan jawatan baharu
}
},
),
),
),
],
),
],
),
),
const SizedBox(height: 14),

if (_filteredStaffList.isEmpty)
const Padding(
padding: EdgeInsets.symmetric(vertical: 40),
child: Center(child: Text('No matching staff record found.', style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
),

// === PERULANGAN KAD YANG MEMBACA DATA YANG TELAH DITAPIS (_filteredStaffList) ===
..._filteredStaffList.map((staff) {
String staffCodeVal = (staff['staff_code'] ?? '').toString();
String fullName     = staff['full_name'] ?? 'No Name';
String email        = staff['email'] ?? 'No Email';
String phone        = (staff['phone'] == null || staff['phone'] == '') ? '—' : staff['phone'];
String dbStatus  = (staff['status'] ?? 'active').toString().toLowerCase();
String categoryMentah = (staff['category'] ?? 'General Support').toString().trim();
String category = categoryMentah;

  if (categoryMentah.contains('/')) {
    category = categoryMentah.split('/').last.trim();
  }
String passHash  = staff['password_hash'] ?? 'password123';
String roleName  = (staff['role'] ?? 'Staff').toString().toUpperCase();

bool isActive = dbStatus == 'active';
String statusLabel = isActive ? 'ACTIVE' : 'INACTIVE';

return Padding(
padding: const EdgeInsets.only(bottom: 10.0),
child: DataRowCard(
title: fullName.toUpperCase(),
subtitle: email,
fields: [
  MapEntry('Staff Code', staffCodeVal),
MapEntry('Phone', phone),
MapEntry('Role', roleName),
MapEntry('Category', category),

],
trailingTag: StatusTag(
label: statusLabel,
background: isActive ?
const Color(0xFFEAF7EE) : const Color(0xFFFDF2F2),
foreground: isActive ? const Color(0xFF2E9E52) : const Color(0xFFD64545)
),
actions: [
  IconTextAction(
icon: Icons.edit_outlined,
label: 'Edit',
onTap: () async {
  String actualStaffCode = (staff['staff_code'] ?? staff['staff_id'] ?? '').toString();
  if (actualStaffCode.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Error: This staff row does not contain a valid Staff Code!')),
);
    return;
  }
await showEditStaffDialog(
context,
staffName: fullName,
staffCode: actualStaffCode,
email: email,
phone: phone,
password: passHash,
status: dbStatus,
category: category,
);
  _ambilSenaraiStaff();
}
),
  IconTextAction(
    icon: Icons.delete_outline,
    label: 'Remove',
    color: const Color(0xFFD64545),
    onTap: () async {
      await showDeleteStaffDialog(context, staffName: fullName, staffCode: staffCodeVal);
      _ambilSenaraiStaff();
      },
  ),
],
),
);
}),
],
),
),
),
);
}
}