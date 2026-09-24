import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// "Staff Sign In" — a separate portal from the IT Department admin
/// Operator sign-in, used by department staff who handle tickets day to
/// day (not full admins).
///
/// Flow wired per the diagram:
///   "Continue with Microsoft (UniKL SSO)" --> Staff Dashboard
///
/// Buttons left un-wired on purpose (present, but no action yet):
///   - "Other login options"
class StaffLoginScreen extends StatelessWidget {
  const StaffLoginScreen({super.key});

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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.badge_outlined,
                      color: AppColors.gold, size: 22),
                ),
                const SizedBox(height: 6),
                const Text('UNIKL RCMP', style: AppTextStyles.brand),
                const Text('Help Desk Portal', style: AppTextStyles.brandSub),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(text: 'Staff ', style: AppTextStyles.cardTitle),
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
                const Text('Sign in as operator? Go to your portal.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 22),
                MicrosoftButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/staff/dashboard',
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'Use your UniKL Microsoft account — recommended for all staff and operators.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // TODO: show email/password sign-in fallback.
                  },
                  child: const Text('Other login options',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
