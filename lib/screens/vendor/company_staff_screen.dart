import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../theme/app_theme.dart';

class CompanyStaffScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final Map<String, dynamic> vendorData;

  const CompanyStaffScreen(
      {super.key, this.onBackPressed, required this.vendorData});

  @override
  State<CompanyStaffScreen> createState() => _CompanyStaffScreenState();
}

class _CompanyStaffScreenState extends State<CompanyStaffScreen> {
  List<dynamic> _senaraiStaffLive = [];
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _tarikSenaraiStaffDariDatabase();
  }

// =========================================================================
  Future<void> _tarikSenaraiStaffDariDatabase() async {
    final String domain = kIsWeb ? 'localhost' : '10.0.2.2';
    final String vId = (widget.vendorData['vendor_id'] ?? '0').toString();
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_vendor_staff.php?vendor_id=$vId&b_cache=${DateTime.now().millisecondsSinceEpoch}');

    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        if (mounted) {
          setState(() {
            _senaraiStaffLive = json.decode(respon.body);
            _isDataLoading = false;
          });
        }
      }
    } catch (e) {
      print("Ralat tarik staff: $e");
      if (mounted) setState(() => _isDataLoading = false);
    }
  }

// =========================================================================
//  POP-UP CONFIRMATION DIALOG PEMADAMAN SUB-STAFF VENDOR
// =========================================================================
  void _pamerSahkanDeleteStaffDialog(String staffId, String namaStaff) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text('Remove Crew Member',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent)),
            ],
          ),
          content: RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 12.5, color: Colors.black87, height: 1.4),
              children: [
                const TextSpan(text: 'Are you sure you want to remove '),
                TextSpan(
                    text: namaStaff.toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.redAccent)),
                const TextSpan(text: ' permanently from company records ?'),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white),
              onPressed: () =>
                  _eksekusiPadamStaffDariDatabase(dialogContext, staffId),
              child: const Text('Confirm Remove',
                  style:
                      TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  Future<void> _eksekusiPadamStaffDariDatabase(
      BuildContext dContext, String staffId) async {
    Navigator.pop(dContext);
    final String domain = kIsWeb ? 'localhost' : '10.0.2.2';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/delete_vendor_staff.php?staff_id=$staffId');

    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Crew member deleted successfully ! ')));
        _tarikSenaraiStaffDariDatabase(); // Auto-refresh data live !
      }
    } catch (e) {
      print("Ralat delete staff: $e");
    }
  }

  void _bukaBorangTambahStaffDialog() {
    final nameCtrl = TextEditingController();
    final positionCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Add New Staff Crew',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Full Name *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(
                  controller: positionCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Position / Role *',
                      border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Phone Number', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A365D),
                  foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                Navigator.pop(dialogContext);
                final String domain = kIsWeb ? 'localhost' : '10.0.2.2';
                final url = Uri.parse(
                    'http://$domain/helpdesk_api/add_vendor_staff.php');
                try {
                  await http.post(url,
                      headers: {"Content-Type": "application/json"},
                      body: json.encode({
                        "vendor_id": widget.vendorData['vendor_id'],
                        "full_name": nameCtrl.text.trim(),
                        "position": positionCtrl.text.trim(),
                        "phone": phoneCtrl.text.trim()
                      }));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                          'New sub-staff crew injected successfully! 🚀')));
                  _tarikSenaraiStaffDariDatabase();
                } catch (e) {
                  print(e);
                }
              },
              child: const Text('Save Crew'),
            )
          ],
        );
      },
    );
  }

  void _bukaBorangEditStaffDialog(Map<String, dynamic> staffSemasa) {
    final nameCtrl = TextEditingController(text: staffSemasa['full_name']);
    final positionCtrl = TextEditingController(text: staffSemasa['position']);
    final phoneCtrl = TextEditingController(text: staffSemasa['phone'] ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Edit Staff Parameters',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Full Name *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(
                  controller: positionCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Position / Role *',
                      border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Phone Number', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A365D),
                  foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                Navigator.pop(dialogContext);
                final String domain = kIsWeb ? 'localhost' : '10.0.2.2';
                final url = Uri.parse(
                    'http://$domain/helpdesk_api/update_vendor_staff.php');
                try {
                  await http.post(url,
                      headers: {"Content-Type": "application/json"},
                      body: json.encode({
                        "staff_id": staffSemasa['staff_id'],
                        "full_name": nameCtrl.text.trim(),
                        "position": positionCtrl.text.trim(),
                        "phone": phoneCtrl.text.trim()
                      }));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                          'Staff deployment data updated successfully! 🚀')));
                  _tarikSenaraiStaffDariDatabase();
                } catch (e) {
                  print(e);
                }
              },
              child: const Text('Update Changes'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
// Butang Back
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () {
                      if (widget.onBackPressed != null) widget.onBackPressed!();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.arrow_back_ios_new_rounded,
                              size: 12, color: AppColors.navy),
                          SizedBox(width: 6),
                          Text('Back to Work Orders',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
// Kepala Header Skrin
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Company Staff',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          SizedBox(height: 4),
                          Text(
                              'Manage crew members assigned to execute UniKL RCMP helpdesk work orders.',
                              style: TextStyle(
                                  fontSize: 11.5, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A365D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12)),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add Staff',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: _bukaBorangTambahStaffDialog,
                    )
                  ],
                ),
                const SizedBox(height: 20),
                _senaraiStaffLive.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12)),
                        child: const Text('No crew sub-staff registered.',
                            style: TextStyle(color: Colors.grey, fontSize: 12)))
                    : Column(
                        children: _senaraiStaffLive.map((staff) {
// Mengesan status PIC / Owner dari database (1 = true, 0 = false)
                          bool isOwner = (staff['is_primary'] == 1 ||
                              staff['is_primary'] == '1');
                          return Container(
                            key: ValueKey(
                                "${staff['staff_id']}_${staff['full_name']}"),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.01),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))
                                ]),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isOwner
                                      ? const Color(0xFFFFF8E6)
                                      : const Color(0xFFF4F6F9),
                                  child: Icon(
                                      isOwner
                                          ? Icons.admin_panel_settings_outlined
                                          : Icons.person_outline_rounded,
                                      size: 16,
                                      color: isOwner
                                          ? const Color(0xFFC9A227)
                                          : Colors.grey),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                              staff['full_name']
                                                  .toString()
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppColors.textPrimary)),
                                          if (isOwner) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFFFF8E6),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4)),
                                                child: const Text('OWNER',
                                                    style: TextStyle(
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFFC9A227))))
                                          ]
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                          '💼 ${staff['position'] ?? 'No Position'} | 📞 ${staff['phone'] ?? 'No Phone'}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),

                                // =========================================================================
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    //  IKON BUTTON EDIT MINI
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border:
                                            Border.all(color: Colors.black12),
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Edit Staff',
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 15, color: AppColors.navy),
                                        onPressed: () =>
                                            _bukaBorangEditStaffDialog(
                                                Map<String, dynamic>.from(
                                                    staff)),
                                      ),
                                    ),

                                    // =========================================================================
                                    // IKON BUTTON REMOVE MERAH  (DISEKAT AUTOMATIK PADA KAD PIC / OWNER!)
                                    // =========================================================================
                                    if (!isOwner) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFECE5),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: Colors.redAccent
                                                  .withOpacity(0.3)),
                                        ),
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'Remove Staff',
                                          icon: const Icon(
                                              Icons.delete_forever_outlined,
                                              size: 15,
                                              color: Colors.redAccent),
                                          onPressed: () =>
                                              _pamerSahkanDeleteStaffDialog(
                                                  staff['staff_id'].toString(),
                                                  staff['full_name']
                                                      .toString()),
                                        ),
                                      ),
                                    ],
                                  ],
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
