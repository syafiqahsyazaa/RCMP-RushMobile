import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; //  kIsWeb
import 'package:http/http.dart' as http; // http.get
import 'dart:convert'; //  json.decode
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../../main.dart';

/// Interface 4: "Help Desk Portal — Operator Sign In" screen.
/// Operators (staff handling tickets) sign in with Microsoft SSO, or via
/// "Other login options" for an email/password fallback.
class OperatorPortalScreen extends StatefulWidget {
  const OperatorPortalScreen({super.key});

  @override
  State<OperatorPortalScreen> createState() => _OperatorPortalScreenState();
}

class _OperatorPortalScreenState extends State<OperatorPortalScreen> {
  bool _showOtherOptions = false;
  bool _isLoading = false;

  void _tampilMesej(String mesej) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mesej)),
      );
    }
  }

  // LANGKAH 1: BACA CREDENTIAL SECARA DINAMIK DARI .ENV BACKEND (PHP)
  Future<void> _handleRealSSOLogin() async {
    setState(() => _isLoading = true);

    final String domain = kIsWeb
        ? 'localhost'
        : (defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : '10.103.19.67');

    final configUrl =
        Uri.parse('http://$domain/helpdesk_api/get_microsoft_config.php');

    try {
      final response = await http.get(configUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final String authUrl = data['auth_url'];
          final Uri uri = Uri.parse(authUrl);

          bool launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          if (!launched) {
            _tampilMesej("Tidak dapat membuka skrin login Microsoft.");
          }
        } else {
          _tampilMesej(data['message'] ?? "Gagal mendapatkan konfigurasi SSO.");
        }
      } else {
        _tampilMesej(
            "Ralat pelayan konfigurasi: Status ${response.statusCode}");
      }
    } catch (e) {
      _tampilMesej("Ralat Sambungan: Pastikan Laragon aktif. ($e)");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // peranan akaun di Laragon & hantar ke destinasi tepat
  Future<void> _prosesSemakPerananDanMasuk() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';

    //  emel sesi global semasa ke API check_user_role php
    final url = Uri.parse(
        'http://$domain/helpdesk_api/check_user_role.php?email=$currentLoggedInUserEmail');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        String userRole =
            (data['role'] ?? 'staff').toString().toLowerCase().trim();
        String fullName =
            (data['full_name'] ?? 'Admin UniKL').toString().trim();

        if (!mounted) return;

        // ===  PENGALIHAN UTAMA (AUTOMATIC REDIRECTION INTERCEPTOR) ===
        final Map<String, dynamic> navigationArgs = {
          "email": currentLoggedInUserEmail,
          "full_name": fullName,
          "role": userRole.toUpperCase()
        };

        if (userRole == 'admin') {
          print("Akaun Admin Dikesan! Meluncur ke Admin Dashboard...");
          Navigator.pushReplacementNamed(context, '/admin/dashboard',
              arguments: navigationArgs);
        } else if (userRole == 'hod') {
          print("Akaun HOD Dikesan! Meluncur ke HOD Dashboard...");
          Navigator.pushReplacementNamed(context, '/hod/dashboard',
              arguments: navigationArgs);
        } else {
          print("Akaun Staff Biasa Dikesan! Meluncur ke Staff Dashboard...");
          Navigator.pushReplacementNamed(context, '/staff/dashboard',
              arguments: navigationArgs);
        }
      }
    } catch (e) {
      print("Ralat ketika menyiasat suis peranan: $e");
      // Fallback keselamatan jika offline/laragon belum dibuka semasa demo
      if (mounted) Navigator.pushNamed(context, '/admin/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: PortalTopBar(
        title: 'UNIKL RCMP',
        subtitle: 'Help Desk Portal',
        trailing: TextButton.icon(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          ),
          icon: const Icon(Icons.arrow_back, size: 14, color: AppColors.navy),
          label: const Text('Back to Home',
              style: TextStyle(color: AppColors.navy, fontSize: 12)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: AuthCard(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'lib/assets/images/unikl_logo.png',
                    width: 70,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined,
                          color: Colors.red, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text('UNIKL RCMP', style: AppTextStyles.brand),
                const Text('Help Desk Portal', style: AppTextStyles.brandSub),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Operator ',
                        style: AppTextStyles.cardTitle,
                      ),
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Not an operator? '),
                      TextSpan(
                        text: 'Go to user portal ',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                        // Use 'recognizer' instead of an 'onTap' parameter:
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.pushNamed(context, '/'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          MicrosoftButton(
                            onPressed: () {
                              _prosesSemakPerananDanMasuk();
                            },
                          ),
                          const SizedBox(height: 10),
                          MicrosoftButton(
                            onPressed: () async {
                              await _handleRealSSOLogin();
                            },
                          ),
                        ],
                      ),
                const SizedBox(height: 6),
                const Text(
                  'Use your UniKL Microsoft account — recommended for all staff and operators.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('or sign in with email',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () =>
                      setState(() => _showOtherOptions = !_showOtherOptions),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Other login options',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Icon(
                        _showOtherOptions
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
                if (_showOtherOptions) ...[
                  const SizedBox(height: 16),
                  const LabeledField(
                    label: 'Work Email',
                    hint: 'operator@unikl.edu.my',
                    icon: Icons.mail_outline,
                  ),
                  const SizedBox(height: 16),
                  const LabeledField(
                    label: 'Password',
                    hint: 'Enter your password',
                    icon: Icons.lock_outline,
                    obscure: true,
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Sign In',
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      // Untuk email/password fallback, kita heret juga ke fungsi suis peranan kita!
                      _prosesSemakPerananDanMasuk();
                    },
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.help_outline,
                        size: 14, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Need help? Contact ITSM  |  142 / 140',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
