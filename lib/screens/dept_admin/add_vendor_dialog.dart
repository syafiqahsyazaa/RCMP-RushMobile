import 'package:flutter/material.dart';import '../../theme/app_theme.dart';import 'package:http/http.dart' as http;import 'dart:convert';import 'package:flutter/foundation.dart';
/// "Add New Vendor" dialog - FULLY WIRED WITH POSITION & DUAL INSERT OPERATIONAL
Future<void> showAddVendorDialog(BuildContext context, {required String department}) {
  return showDialog(
    context: context,
    builder: (context) => AddVendorDialog(department: department),
  );
}
class AddVendorDialog extends StatefulWidget {
  final String department;
  const AddVendorDialog({super.key, required this.department});

  @override
  State<AddVendorDialog> createState() => _AddVendorDialogState();
}
class _AddVendorDialogState extends State<AddVendorDialog> {
  // 💡 Controllers to suck every text input typed by the Admin
  final _companyNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postcodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _picNameCtrl = TextEditingController();
  final _picPositionCtrl = TextEditingController(); // Position Controller for vendor_staff
  final _picPhoneCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _postcodeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _picNameCtrl.dispose();
    _picPositionCtrl.dispose();
    _picPhoneCtrl.dispose();
    super.dispose();
  }

  // =========================================================================
  // PEGANG DATA JABATAN CURRENT LOGIN
  // =========================================================================
  Future<void> _hantarDataVendorKeLaragon() async {
    String company = _companyNameCtrl.text.trim();
    String email = _emailCtrl.text.trim();
    String phone = _phoneCtrl.text.trim();

    if (company.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all mandatory (*) fields!')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final String domain = kIsWeb ? 'localhost' : '10.0.2.2';
    final url = Uri.parse('http://$domain/helpdesk_api/add_vendor.php');

    try {
      final respon = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "company_name": company,
          "address": _addressCtrl.text.trim(),
          "city": _cityCtrl.text.trim(),
          "state": _stateCtrl.text.trim(),
          "postcode": _postcodeCtrl.text.trim(),
          "email": email,
          "phone": phone,
          "pic_name": _picNameCtrl.text.trim(),
          "pic_position": _picPositionCtrl.text.trim(),
          "pic_phone": _picPhoneCtrl.text.trim(),

          //  hantar parameter jabatan current login admin!
          "department": widget.department,
        }),
      );

      if (respon.statusCode == 200) {
        final Map<String, dynamic> hasil = json.decode(respon.body);
        if (hasil['status'] == 'berjaya') {
          if (mounted) {
            Navigator.pop(context); // Tutup popup dialog borang admin

            String passwordUnikBaru = hasil['temp_password'] ?? 'Gagal Janu Password';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 12),
                backgroundColor: const Color(0xFF0D3B66),
                content: Text(
                  'Vendor successfully registered! \nEMAILED PASSWORD CREDENTIAL: $passwordUnikBaru',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12.5),
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hasil['mesej'] ?? 'Failed.')));
        }
      }
    } catch (e) {
      print("Ralat penambahan vendor: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }


  // Safe Input Field Component - 100% Kalis Infinite Width Crash
  Widget _buildSafeInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isRequired = false,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            if (isRequired) const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 660),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                children: [
                  const Expanded(
                    child: Text('Add New Vendor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Form Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSafeInputField(label: 'Company Name', hint: 'PT One Sdn Bhd', icon: Icons.storefront_outlined, controller: _companyNameCtrl, isRequired: true),
                      const SizedBox(height: 12),
                      _buildSafeInputField(label: 'Address', hint: 'Street address', icon: Icons.location_on_outlined, controller: _addressCtrl),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildSafeInputField(label: 'City', hint: 'e.g. Ipoh', icon: Icons.location_city_outlined, controller: _cityCtrl)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSafeInputField(label: 'State', hint: 'e.g. Perak', icon: Icons.map_outlined, controller: _stateCtrl)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildSafeInputField(label: 'Postcode', hint: 'e.g. 30450', icon: Icons.markunread_mailbox_outlined, controller: _postcodeCtrl, type: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSafeInputField(label: 'Phone *', hint: 'Company phone', icon: Icons.call_outlined, controller: _phoneCtrl, isRequired: true, type: TextInputType.phone)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSafeInputField(label: 'Email', hint: 'vendor@company.com', icon: Icons.mail_outline, controller: _emailCtrl, isRequired: true, type: TextInputType.emailAddress),
                      const SizedBox(height: 16),

                      const Align(alignment: Alignment.centerLeft, child: Text('Person In Charge (PIC)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                      const Divider(height: 16),

                      _buildSafeInputField(label: 'PIC Name', hint: 'e.g. Ahmad Zaki', icon: Icons.person_outline, controller: _picNameCtrl),
                      const SizedBox(height: 12),

                      // POSITION: Slid in beautifully right under PIC Name!
                      _buildSafeInputField(label: 'Position', hint: 'e.g. Manager / Supervisor', icon: Icons.badge_outlined, controller: _picPositionCtrl),
                      const SizedBox(height: 12),

                      _buildSafeInputField(label: 'PIC Phone Number', hint: '01XXXXXXXXX', icon: Icons.call_outlined, controller: _picPhoneCtrl, type: TextInputType.phone),
                      const SizedBox(height: 16),

                      const InfoBanner(
                        tone: BannerTone.info,
                        title: 'This vendor will automatically be sent an invitation email to activate their account once added.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Actions Button Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  _isSaving
                      ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                      : PrimaryButton(
                          label: 'Add Vendor',
                          icon: Icons.add,
                          width: null,
                          onPressed: _hantarDataVendorKeLaragon,
                        ),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
