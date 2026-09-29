import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../theme/app_theme.dart';

/// FUNGSI PEMANGGIL GLOBAL UNTUK MEMBUKA SKRIN PROFIL VENDOR
Future<void> showProfileSetupDialog({
  required BuildContext context,
  required Map<String, dynamic> vendorData,
  required ValueChanged<Map<String, dynamic>> onProfileFinalized,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VendorProfileScreen(
        vendorData: vendorData,
        onProfileFinalized: onProfileFinalized,
      ),
    ),
  );
}

class VendorProfileScreen extends StatefulWidget {
  final Map<String, dynamic> vendorData;
  final ValueChanged<Map<String, dynamic>> onProfileFinalized;

  const VendorProfileScreen({
    super.key,
    required this.vendorData,
    required this.onProfileFinalized,
  });

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  // 11 Pemegang data input tulen database unicomplaint
  late final TextEditingController _companyNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postcodeController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  late final TextEditingController _picNameController;
  late final TextEditingController _picPositionController;
  late final TextEditingController _picPhoneController;
  late final TextEditingController _newPasswordController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _companyNameController =
        TextEditingController(text: widget.vendorData['company_name'] ?? '');
    _emailController =
        TextEditingController(text: widget.vendorData['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.vendorData['phone'] ?? '');
    _addressController =
        TextEditingController(text: widget.vendorData['address'] ?? '');
    _cityController =
        TextEditingController(text: widget.vendorData['city'] ?? '');
    _stateController =
        TextEditingController(text: widget.vendorData['state'] ?? '');
    _postcodeController =
        TextEditingController(text: widget.vendorData['postcode'] ?? '');

    _picNameController =
        TextEditingController(text: widget.vendorData['pic_name'] ?? '');
    _picPositionController =
        TextEditingController(text: widget.vendorData['pic_position'] ?? '');
    _picPhoneController =
        TextEditingController(text: widget.vendorData['pic_phone'] ?? '');
    _newPasswordController = TextEditingController();
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
    const String domain = kIsWeb ? 'localhost' : '10.0.2.2';
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
            // Update local widget map values
            widget.vendorData['company_name'] =
                _companyNameController.text.trim();
            widget.vendorData['address'] = _addressController.text.trim();
            widget.vendorData['city'] = _cityController.text.trim();
            widget.vendorData['state'] = _stateController.text.trim();
            widget.vendorData['postcode'] = _postcodeController.text.trim();
            widget.vendorData['phone'] = _phoneController.text.trim();
            widget.vendorData['pic_name'] = _picNameController.text.trim();
            widget.vendorData['pic_position'] =
                _picPositionController.text.trim();
            widget.vendorData['pic_phone'] = _picPhoneController.text.trim();
            widget.vendorData['first_login'] = 0;

            Navigator.pop(context);
            widget.onProfileFinalized(widget.vendorData);
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
    bool isFirstLoginTulen = (widget.vendorData['first_login'] == 1 ||
        widget.vendorData['first_login'] == '1');

    return PopScope(
      canPop: isFirstLoginTulen ? false : true,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: PortalTopBar(
          title: 'UNIKL RCMP',
          subtitle: 'Vendor Profile Setup',
          trailing: isFirstLoginTulen
              ? null
              : TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back,
                      size: 14, color: AppColors.navy),
                  label: const Text('Back',
                      style: TextStyle(color: AppColors.navy, fontSize: 12)),
                ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: FlowCard(
                maxWidth: 600,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirstLoginTulen) ...[
                      const InfoBanner(
                        title: 'Welcome! Complete Your Profile',
                        subtitle:
                            'Please fill in all company information details before continuing. Changing your initial password is optional.',
                        tone: BannerTone.info,
                      ),
                      const SizedBox(height: 20),
                    ],
                    const Text(
                      'Company Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Company Name',
                      hint: 'Company Name',
                      icon: Icons.business,
                      controller: _companyNameController,
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Company Address',
                      hint: 'Street Address',
                      icon: Icons.location_on_outlined,
                      controller: _addressController,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: LabeledField(
                            label: 'City',
                            hint: 'City',
                            icon: Icons.location_city,
                            controller: _cityController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LabeledField(
                            label: 'State',
                            hint: 'State',
                            icon: Icons.map,
                            controller: _stateController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: LabeledField(
                            label: 'Postcode',
                            hint: 'Postcode',
                            icon: Icons.pin_drop,
                            controller: _postcodeController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LabeledField(
                            label: 'Phone Number',
                            hint: 'Phone Number',
                            icon: Icons.phone_outlined,
                            controller: _phoneController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Company Email (Read-Only)',
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Person In Charge (PIC) Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'PIC Name',
                      hint: 'PIC Full Name',
                      icon: Icons.person_outline,
                      controller: _picNameController,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: LabeledField(
                            label: 'PIC Position',
                            hint: 'Position',
                            icon: Icons.badge_outlined,
                            controller: _picPositionController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LabeledField(
                            label: 'PIC Phone',
                            hint: 'Phone Number',
                            icon: Icons.phone_android,
                            controller: _picPhoneController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Security Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'New Password (Optional)',
                      hint: 'Leave blank to keep current password',
                      icon: Icons.lock_outline,
                      controller: _newPasswordController,
                      obscure: true,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isFirstLoginTulen) ...[
                          SecondaryButton(
                            label: 'Cancel',
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                        ],
                        _isSaving
                            ? const CircularProgressIndicator()
                            : SuccessButton(
                                label: 'Save Changes',
                                icon: Icons.check,
                                onPressed: _hantarProfilVendorKeDatabaseLive,
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
