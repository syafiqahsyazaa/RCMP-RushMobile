import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import'../../main.dart';

const _adminNavItems = [
  AdminNavItem(Icons.dashboard_outlined, 'Dashboard', '/admin/dashboard'),
  AdminNavItem(Icons.confirmation_number_outlined, 'All Tickets', '/admin/tickets'),
  AdminNavItem(Icons.people_outline, 'Manage Users', '/admin/users'),
  AdminNavItem(Icons.storefront_outlined, 'Manage Vendors', '/admin/vendors'),
  AdminNavItem(Icons.category_outlined, 'Categories', '/admin/categories'),
  AdminNavItem(Icons.bar_chart_outlined, 'Reports & Analytics', '/admin/reports'),
];

class AdminAllTicketsScreen extends StatefulWidget {
  const AdminAllTicketsScreen({super.key});

  @override
  State<AdminAllTicketsScreen> createState() => _AdminAllTicketsScreenState();
}

class _AdminAllTicketsScreenState extends State<AdminAllTicketsScreen> {
bool _isLoading = true;
List<dynamic> _allTickets = [];
List<dynamic> _filteredTickets = [];

String _namaJabatanLive = "Loading Department...";

// Counter Map Elements
Map<String, String> _counters = {"all": "0", "open": "0", "in_progress": "0", "closed": "0"};

// SEARCH & FILTER CONTROLLER
final TextEditingController _searchController = TextEditingController();
String _activeStatusTab = 'All'; // Track current active stat mini card filter
String _selectedPriority = 'All Priorities';
String _selectedCategory = 'All Categories';

final List<String> _priorityOptions = ['All Priorities', 'Low', 'Medium', 'High'];
List<String> _categoryOptions = ['All Categories'];

@override
void initState() {
super.initState();
_ambilSenaraiTiketAdmin();
_loadCategoriesDropdown();
_searchController.addListener(_tapisSenaraiTiketDinamik);
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

Future<void> _ambilSenaraiTiketAdmin() async {
final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
final url = Uri.parse('http://$domain/helpdesk_api/get_admin_tickets.php?email=$currentLoggedInUserEmail');

try {
final response = await http.get(url);
if (response.statusCode == 200) {
final Map<String, dynamic> data = json.decode(response.body);
setState(() {
_namaJabatanLive = data['department_label'] ?? 'IT Department · Admin';
_allTickets = data['tickets'] ?? [];
_counters = Map<String, String>.from(data['counters']);
_isLoading = false;
});
_tapisSenaraiTiketDinamik();
}
} catch (e) {
print("Error linking to admin tickets pool: $e");
setState(() => _isLoading = false);
}
}

  // =========================================================================
  // DROPDOWN FILTER JABATAN: apply email SESI LOGIN REAL-TIME
  // =========================================================================
  Future<void> _loadCategoriesDropdown() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';

    final url = Uri.parse('http://$domain/helpdesk_api/get_dropdowns.php?email=$currentLoggedInUserEmail&b_cache=${DateTime.now().millisecondsSinceEpoch}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<String> fetchedCats = List<String>.from(data['categories'] ?? []);
        setState(() {
          _categoryOptions = ['All Categories', ...fetchedCats];
        });
        print("DROPDOWN CATEGORIES LIVE SYNCED: ${_categoryOptions.length} items loaded for $currentLoggedInUserEmail");
      }
    } catch (e) {
      print("Dropdown category pull fail: $e");
    }
  }


// INTERACTIVE LIVE FILTER MATRIX LOGIC
void _tapisSenaraiTiketDinamik() {
String query = _searchController.text.toLowerCase().trim();

setState(() {
_filteredTickets = _allTickets.where((ticket) {
String ticketId = (ticket['ticket_id'] ?? '').toString().toLowerCase();
String title    = (ticket['title'] ?? '').toString().toLowerCase();
String priority = (ticket['priority'] ?? 'Medium').toString().toLowerCase();
String category = (ticket['category'] ?? ticket['title'] ?? '').toString().toLowerCase();
String status   = (ticket['status'] ?? 'open').toString().toLowerCase();

// 1. Verify Stat Card Status Selection Tab
bool matchesStatus = _activeStatusTab == 'All' ||
(_activeStatusTab == 'Open' && status == 'open') ||
(_activeStatusTab == 'In Progress' && status == 'in_progress') ||
(_activeStatusTab == 'Closed' && status == 'closed');

// 2. Verify Search Bar Query
bool matchesSearch = ticketId.contains(query) || title.contains(query);

// 3. Verify Priority Dropdown State
bool matchesPriority = _selectedPriority == 'All Priorities' ||
priority == _selectedPriority.toLowerCase();

// 4. Verify Categories Dropdown Track
bool matchesCategory = _selectedCategory == 'All Categories' ||
category.contains(_selectedCategory.toLowerCase());

return matchesStatus && matchesSearch && matchesPriority && matchesCategory;
}).toList();
});
}

Color _getStatusColor(String status) {
if (status.toLowerCase() == 'closed') return const Color(0xFF2E9E52);
if (status.toLowerCase() == 'in_progress') return const Color(0xFFC9A227);
return const Color(0xFFD64545);
}

Color _getStatusBg(String status) {
if (status.toLowerCase() == 'closed') return const Color(0xFFEAF7EE);
if (status.toLowerCase() == 'in_progress') return const Color(0xFFFFF8E6);
return const Color(0xFFFDF2F2);
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.pageBackground,
drawer:  PortalNavDrawer(
departmentLabel: '$_namaJabatanLive · Admin',
currentRoute: '/admin/tickets',
items: _adminNavItems,
staffName: (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['full_name'] ?? "Admin UniKL",
role: (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['role'] ?? "Admin",
),
appBar: AppBar(
backgroundColor: Colors.white,
elevation: 0,
iconTheme: const IconThemeData(color: AppColors.navy),
title: const Text('All Tickets', style: TextStyle(color: AppColors.navy, fontSize: 14, fontWeight: FontWeight.w700)),
),
body: SafeArea(
child: _isLoading
? const Center(child: CircularProgressIndicator())
: RefreshIndicator(
onRefresh: _ambilSenaraiTiketAdmin,
child: ListView(
padding: const EdgeInsets.all(16),
children: [
  SizedBox(
    height: 96,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        GestureDetector(
          onTap: () => setState(() { _activeStatusTab = 'All'; _tapisSenaraiTiketDinamik(); }),
          child: Container(
            decoration: BoxDecoration(
                border: _activeStatusTab == 'All' ? Border.all(color: AppColors.navy, width: 2) : null,
                borderRadius: BorderRadius.circular(12)
            ),
            child: StatMiniCard(value: _counters['all']!, label: 'All', icon: Icons.confirmation_number_outlined),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => setState(() { _activeStatusTab = 'Open'; _tapisSenaraiTiketDinamik(); }),
          child: Container(
            decoration: BoxDecoration(
                border: _activeStatusTab == 'Open' ? Border.all(color: AppColors.navy, width: 2) : null,
                borderRadius: BorderRadius.circular(12)
            ),
            child: StatMiniCard(value: _counters['open']!, label: 'Open', icon: Icons.mark_email_unread_outlined, color: const Color(0xFFD64545)),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => setState(() { _activeStatusTab = 'In Progress'; _tapisSenaraiTiketDinamik(); }),
          child: Container(
            decoration: BoxDecoration(
                border: _activeStatusTab == 'In Progress' ? Border.all(color: AppColors.navy, width: 2) : null,
                borderRadius: BorderRadius.circular(12)
            ),
            child: StatMiniCard(value: _counters['in_progress']!, label: 'In Progress', icon: Icons.autorenew, color: const Color(0xFFC9A227)),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => setState(() { _activeStatusTab = 'Closed'; _tapisSenaraiTiketDinamik(); }),
          child: Container(
            decoration: BoxDecoration(
                border: _activeStatusTab == 'Closed' ? Border.all(color: AppColors.navy, width: 2) : null,
                borderRadius: BorderRadius.circular(12)
            ),
            child: StatMiniCard(value: _counters['closed']!, label: 'Closed', icon: Icons.check_circle_outline, color: const Color(0xFF2E9E52)),
          ),
        ),
      ],
    ),
  ),

const SizedBox(height: 16),

// Integrated Search & Dropdown Filter Layout Panel
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
child: Column(
children: [
TextField(
controller: _searchController,
style: const TextStyle(fontSize: 12.5),
decoration: InputDecoration(
hintText: 'Search ticket ID or title...',
prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
contentPadding: const EdgeInsets.symmetric(vertical: 10),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide:
const BorderSide(color: AppColors.border)),
filled: true, fillColor: AppColors.pageBackground,
),
),
const SizedBox(height: 10),
Row(
children: [
  // Priority Dropdown Filter
Expanded(
child: SizedBox(
height: 34,
child: DropdownButtonFormField(
value: _selectedPriority,
style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 8),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
items: _priorityOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
onChanged: (v) { if (v != null) { setState(() => _selectedPriority = v);
  _tapisSenaraiTiketDinamik(); } },
),
),
),
const SizedBox(width: 8),
// Category Dropdown Filter
  Expanded(
    child: SizedBox(
      height: 34,
      child: DropdownButtonFormField<String>(
        isExpanded: true,

        value: _selectedCategory,
        style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))
        ),
        items: _categoryOptions.map((v) {
          return DropdownMenuItem<String>(
              value: v,
              child: Text(
                v,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              )
          );
        }).toList(),

        onChanged: (v) {
          if (v != null) {
            setState(() => _selectedCategory = v);
            _tapisSenaraiTiketDinamik();
          }
        },
      ),
    ),
  ),
],
)
],
),
),
Padding(
padding: const EdgeInsets.symmetric(vertical: 12),
child: Text('Showing ${_filteredTickets.length} results', style: const TextStyle(fontSize: 11,
color: AppColors.textMuted, fontWeight: FontWeight.bold)),
),
if (_filteredTickets.isEmpty)
  const Padding(
padding: EdgeInsets.symmetric(vertical: 40),
child: Center(child: Text('No complaints match your active filter tracks.', style:
TextStyle(color: AppColors.textMuted, fontSize: 13))),
),
// === LIVE FILTERED TICKETS LOOP GENERATOR ===
..._filteredTickets.map((ticket) {
  String idVal     = ticket['ticket_id'] ?? '';
  //String titleVal  = ticket['title'] ?? 'General Issue';
  String emailVal  = ticket['submitter_email'] ?? 'No Submitter Email';
  String deptVal   = ticket['my_department'] ?? 'General Support';
  String catVal    = ticket['category'] ?? ticket['title'] ?? 'General';
  String prioRaw   = ticket['priority'] ?? 'Medium';
  String statusRaw = ticket['status'] ?? 'open';

  String tajukAsal = ticket['title'] ?? 'General Issue';
  String namaStaffRemark = (ticket['remarks'] ?? '').toString().trim();
  String titleVal = tajukAsal;
  if (namaStaffRemark.isNotEmpty && namaStaffRemark.toLowerCase() != 'null') {
    titleVal = "$tajukAsal - ${namaStaffRemark.toUpperCase()}";
  }

  String formattedPrio = prioRaw.substring(0,1).toUpperCase() +
prioRaw.substring(1).toLowerCase();

return Padding(
padding: const EdgeInsets.only(bottom: 8.0),
child: TicketCard(
ticketId: idVal,
title: titleVal,
submittedBy: emailVal,
department: deptVal,
category: catVal,
priority: formattedPrio,
status: statusRaw.toUpperCase().replaceAll('_', ' '),
statusColor: _getStatusColor(statusRaw),
statusBg: _getStatusBg(statusRaw),
onView: () async {
  // Pass the entire record packet down to workspace dynamically
final refresh = await Navigator.pushNamed(context, '/tickets/workspace', arguments:
ticket);
if (refresh == true) _ambilSenaraiTiketAdmin();
},
),
);
}
),
],
),
),
),
);
}
}