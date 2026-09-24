import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../theme/app_theme.dart';

/// FUNGSI PEMANGGIL GLOBAL DIALOG PROFIL 1 LAJUR
Future<void> showProfileSetupDialog({
  required BuildContext context,
  required Map<String, dynamic> vendorData,
  required VoidCallback onProfileFinalized,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false, // Kunci klik luar kotak dialog
    builder: (context) => ProfileSetupDialog(
      vendorData: vendorData,
      onProfileFinalized: onProfileFinalized,
    ),
  );
}

class ProfileSetupDialog extends StatefulWidget {
  final Map<String, dynamic> vendorData;
  final VoidCallback onProfileFinalized;

  const ProfileSetupDialog({
    super.key,
    required this.vendorData,
    required this.onProfileFinalized,
  });

  @override
  State<ProfileSetupDialog> createState() => _ProfileSetupDialogState();
}

class _ProfileSetupDialogState extends State<ProfileSetupDialog> {
  // 11 Pemegang data input tulen database unicomplaint
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _picNameController = TextEditingController();
  final _picPositionController = TextEditingController();
  final _picPhoneController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _companyNameController.text = widget.vendorData['company_name'] ?? '';
    _emailController.text = widget.vendorData['email'] ?? '';
    _phoneController.text = widget.vendorData['phone'] ?? '';
    _addressController.text = widget.vendorData['address'] ?? '';
    _cityController.text = widget.vendorData['city'] ?? '';
    _stateController.text = widget.vendorData['state'] ?? '';
    _postcodeController.text = widget.vendorData['postcode'] ?? '';

    _picNameController.text = widget.vendorData['pic_name'] ?? '';
    _picPositionController.text = widget.vendorData['pic_position'] ?? '';
    _picPhoneController.text = widget.vendorData['pic_phone'] ?? '';
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _picNameController.dispose();
    _picPositionController.dispose();
    _picPhoneController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _hantarProfilVendorKeDatabaseLive() async {
    if (_addressController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _postcodeController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please complete all mandatory profile fields column murni!')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final String domain = kIsWeb ? 'localhost' : '10.0.2.2';
    final url =
        Uri.parse('http://$domain/helpdesk_api/update_vendor_profile.php');

    try {
      final respon = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "vendor_id": widget.vendorData['vendor_id'],
          "company_name": _companyNameController.text.trim(),
          "address": _addressController.text.trim(),
          "city": _cityController.text.trim(),
          "state": _stateController.text.trim(),
          "postcode": _postcodeController.text.trim(),
          "phone": _phoneController.text.trim(),
          "pic_name": _picNameController.text.trim(),
          "pic_position": _picPositionController.text.trim(),
          "pic_phone": _picPhoneController.text.trim(),
          "new_password": _newPasswordController.text.trim()
        }),
      );

      if (respon.statusCode == 200) {
        final Map<String, dynamic> res = json.decode(respon.body);
        if (res['status'] == 'success') {
          if (mounted) {
            Navigator.pop(context);
            widget.onProfileFinalized();
          }
        }
      }
    } catch (e) {
      print("Ralat: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // SUIS PENAPIS PINTAR: Mengesan sama ada ini first_login tulen (1 atau '1')
    bool isFirstLoginTulen = (widget.vendorData['first_login'] == 1 ||
        widget.vendorData['first_login'] == '1');

    return PopScope(
      canPop: isFirstLoginTulen
          ? false
          : true, // Jika first login, haram pop guna back button handphone!
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Profile Setup — Vendor Portal',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =========================================================================
                //  SUIS NOTA : HANYA MENYALA JIKA FIRST TIME LOGIN SAHAJA
                // Sekiranya user klik dari AppBar (bukan first login),
                // =========================================================================
                if (isFirstLoginTulen) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    color: Colors.green.shade50,
                    child: const Text(
                        'Welcome! Please fill in all company information details before continuing. Changing your initial password is optional.',
                        style: TextStyle(fontSize: 11, color: Colors.black87)),
                  ),
                  const SizedBox(height: 14),
                ],

                // Bahagian A: Maklumat Syarikat
                TextField(
                    controller: _companyNameController,
                    decoration: const InputDecoration(
                        labelText: 'Company Name *',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                        labelText: 'Company Address *',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                        labelText: 'City *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                        labelText: 'State *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: _postcodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Postcode *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: InputDecoration(
                        labelText: 'Company Email (Read-Only)',
                        border: const OutlineInputBorder(),
                        fillColor: Colors.grey.shade100,
                        filled: true)),
                const SizedBox(height: 10),
                TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Company Phone *',
                        border: OutlineInputBorder())),

                const SizedBox(height: 18),
                const Text('Person In Charge (PIC) Details',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const Divider(height: 14),

                // Bahagian B: Maklumat PIC
                TextField(
                    controller: _picNameController,
                    decoration: const InputDecoration(
                        labelText: 'PIC Name *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: _picPositionController,
                    decoration: const InputDecoration(
                        labelText: 'PIC Position *',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: _picPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'PIC Phone Number *',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),

                // Bahagian C: Tukar Password
                TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'New Encryption Password (Optional)',
                        border: OutlineInputBorder())),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // =========================================================================
              // BUTANG CANCEL (SEBELAH SAVE CHANGES):
              // Hanya keluar jika user klik dari AppBar (bukan first login)
              // =========================================================================
              if (!isFirstLoginTulen) ...[
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold))),
                const SizedBox(width: 10),
              ],
              _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D3B66),
                          foregroundColor: Colors.white),
                      onPressed: _hantarProfilVendorKeDatabaseLive,
                      child: const Text('Save Changes',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }
}
