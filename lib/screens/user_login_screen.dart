import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// Interface 3: "Help Desk System — Welcome Back / User Login" screen.
class UserLoginScreen extends StatefulWidget {
  final String? department;

  const UserLoginScreen({super.key, this.department});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  bool _isLoading = false;

  // Fungsi simulasi SSO: Tarik data
  Future<void> _loginDanTarikDataAutomatik() async {
    setState(() {
      _isLoading = true;
    });

    // Menggunakan email contoh
    const String emelSimulasi = "syafiqahsyaza@gmail.com";

    final String domain = kIsWeb
        ? 'localhost'
        : (defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : '10.103.19.67');
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_user.php?email=$emelSimulasi');

    try {
      final respon = await http.get(url);

      if (respon.statusCode == 200) {
        final Map<String, dynamic> hasil = json.decode(respon.body);

        if (hasil['status'] == 'wujud') {
          // Mengambil data mengikut nama ruangan jadual staff anda
          String namaDariDB = hasil['data']['full_name'];
          String emelDariDB = hasil['data']['email'];

          if (mounted) {
            // 1. get nama jabatan dari skrin depan
            final Object? argsTargetDept =
                ModalRoute.of(context)?.settings.arguments;
            String targetDept = (widget.department ?? argsTargetDept ?? 'IT')
                .toString()
                .trim()
                .toLowerCase();

            // 2.  terus kekalkan masuk ke fail  /complaint/fill
            Navigator.pushReplacementNamed(
              context,
              '/complaint/fill',
              arguments: {
                'nama_user': namaDariDB,
                'emel_user': emelDariDB,
                'selected_dept':
                    targetDept, //   jenis jabatan ke dalam arguments!
              },
            );
          }
        } else {
          _tampilMesej(hasil['mesej'] ?? "Pengguna tiada dalam database.");
        }
      } else {
        _tampilMesej("Ralat Pelayan: Status ${respon.statusCode}");
      }
    } catch (e) {
      _tampilMesej("Ralat Sambungan Laragon. Pastikan Laragon aktif.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      // 1. Ambil Auth URL daripada backend PHP yang membaca fail .env di helpdesk_api
      final response = await http.get(configUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final String authUrl = data['auth_url'];
          final Uri uri = Uri.parse(authUrl);

          // 2. Buka halaman Microsoft di External Browser
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

  void _tampilMesej(String mesej) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesej)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/assets/images/bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2B3A55), Color(0xFF16233F)],
                ),
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.45)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: AuthCard(
                maxWidth: 380,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            'lib/assets/images/unikl_logo.png',
                            width: 70,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
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
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('UNIKL ROYAL COLLEGE OF MEDICINE PERAK',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textSecondary)),
                              Text('Help Desk System',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Welcome ',
                            style: AppTextStyles.cardTitle,
                          ),
                          TextSpan(
                            text: 'Back',
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
                    const Text('User Login', style: AppTextStyles.cardTitle),
                    const SizedBox(height: 8),
                    Text(
                      widget.department == null
                          ? 'Log in with your UniKL email to access the Help Desk.'
                          : 'Log in with your UniKL email to submit a ${widget.department} ticket.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cardSubtitle,
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                            children: [
                              MicrosoftButton(
                                onPressed: _loginDanTarikDataAutomatik,
                              ),
                              const SizedBox(height: 12),
                              RealSSOButton(
                                onPressed: () async {
                                  //  SSO !
                                  await _handleRealSSOLogin();
                                },
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      ),
                      icon: const Icon(Icons.home_outlined,
                          size: 14, color: AppColors.textSecondary),
                      label: const Text(
                        'Back to Homepage',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
