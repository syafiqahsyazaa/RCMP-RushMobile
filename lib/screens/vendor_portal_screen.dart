import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Interface 2: "RUSH — Vendor Portal" screen.
/// Company email + password sign-in for vendors managing work orders.
class VendorPortalScreen extends StatefulWidget {
  const VendorPortalScreen({super.key});

  @override
  State<VendorPortalScreen> createState() => _VendorPortalScreenState();
}

class _VendorPortalScreenState extends State<VendorPortalScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Pengurus teks kotak input email & password vendor
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================================================================
  // ENJIN API AUTENTIKASI LOGIN VENDOR LARAGON
  // =========================================================================
  Future<void> _prosesLoginVendorLive() async {
    String emailText = _emailController.text.trim();
    String passwordText = _passwordController.text.trim();

    if (emailText.isEmpty || passwordText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both Company Email and Password columns !')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Jalur domain pintar kalis sekatan web browser vs handphone emulator
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse('http://$domain/helpdesk_api/vendor_login.php');

    try {
      final respon = await http.post(
        url,
        //  header Content-Type JSON wajib supaya API PHP Laragon tidak buta!
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: json.encode({
          "email": emailText,
          "password": passwordText,
        }),
      );

      if (respon.statusCode == 200) {
        final Map<String, dynamic> hasil = json.decode(respon.body);

        if (hasil['status'] == 'success') {
          Map<String, dynamic> vendorProfile = Map<String, dynamic>.from(hasil['data'] ?? {});

          // =========================================================================
          //  KEMASKINI: SELARASKAN DATA TYPE FIRST_LOGIN
          // Kita simpan dalam format String/dynamic yang dinamik supaya dashboard
          // baharu boleh mengesan dengan tepat sama ada 1 (baru) atau 0 (kali kedua).
          // =========================================================================
          vendorProfile['first_login'] = hasil['first_login'];

          // Perisai keselamatan 'mounted context' wajib dipasang sebelum melompat screen!
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Vendor Authentication successfully verified!')
            ),
          );

          // : Meluncur lurus tanpa sekatan ke pintu portal vendor dashboard!
          Navigator.pushReplacementNamed(
            context,
            '/vendor/dashboard',
            arguments: vendorProfile,
          );
        } else {
          _pamerAmaranMesej(hasil['message'] ?? 'Invalid credential combination murni.');
        }
      } else {
        _pamerAmaranMesej('Server Response Error: Status ${respon.statusCode}');
      }
    } catch (e) {
      print("Ralat sambungan login vendor: $e");
      _pamerAmaranMesej('Connection failure to Laragon server. Please check your Apache connection murni.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _pamerAmaranMesej(String mesej) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent, content: Text(mesej)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: PortalTopBar(
        title: 'UNIKL RCMP',
        subtitle: 'RUSH — Vendor Portal',
        trailing: TextButton.icon(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
          icon: const Icon(Icons.arrow_back, size: 14, color: AppColors.navy),
          label: const Text('Back to Home', style: TextStyle(color: AppColors.navy, fontSize: 12)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 60,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'lib/assets/images/unikl_logo.png',
                    width: 70,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, color: Colors.red, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text('UNIKL RCMP', style: AppTextStyles.brand),
                const Text('Vendor Portal', style: AppTextStyles.brandSub),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(text: 'Vendor ', style: AppTextStyles.cardTitle),
                      TextSpan(text: 'Access', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: AppColors.gold)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Sign in to manage your assigned work orders.', style: AppTextStyles.cardSubtitle, textAlign: TextAlign.center),
                const SizedBox(height: 24),

                LabeledField(
                  label: 'Company Email',
                  hint: 'vendor@company.com',
                  icon: Icons.mail_outline,
                  controller: _emailController,
                ),
                const SizedBox(height: 16),

                LabeledField(
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  obscure: _obscurePassword,
                  controller: _passwordController,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18, color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                const SizedBox(height: 22),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                  label: 'Sign In',
                  icon: Icons.arrow_forward,
                  onPressed: _prosesLoginVendorLive,
                ),
                const SizedBox(height: 18),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.help_outline, size: 14, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Text('Need help? Contact 03-142  |  142 / 140', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
