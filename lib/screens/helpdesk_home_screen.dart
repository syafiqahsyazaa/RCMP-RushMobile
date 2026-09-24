import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Interface 1: "RUSH — RCMP User Helpdesk" home screen.
/// Shows the USH logo and three department tiles (IT, Administration &
/// Facilities, Maintenance). Tapping a tile goes to the User Login screen.
/// The two circular icons top-right open the Vendor Portal and the
/// Operator Portal respectively.
class HelpdeskHomeScreen extends StatelessWidget {
  const HelpdeskHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: PortalTopBar(
        title: 'UNIKL RCMP',
        subtitle: 'RUSH — RCMP User Helpdesk',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoundIconButton(
              icon: Icons.person_outline,
              tooltip: 'Operator Portal',
              onTap: () => Navigator.pushNamed(context, '/operator'),
            ),
            const SizedBox(width: 8),
            _RoundIconButton(
              icon: Icons.storefront_outlined,
              tooltip: 'Vendor Portal',
              onTap: () => Navigator.pushNamed(context, '/vendor'),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.directions_run,
                            color: AppColors.gold, size: 34),
                        SizedBox(width: 8),
                        Text(
                          'USH',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'RUSH USER HELPDESK',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'SELECT A DEPARTMENT TO SUBMIT A TICKET',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        _DepartmentTile(
                          icon: Icons.computer,
                          label: 'IT',
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/login',
                            arguments: 'IT',
                          ),
                        ),
                        _DepartmentTile(
                          icon: Icons.apartment,
                          label: 'ADMINISTRATION\n& FACILITIES',
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/login',
                            arguments: 'Administration & Facilities',
                          ),
                        ),
                        _DepartmentTile(
                          icon: Icons.build_outlined,
                          label: 'MAINTENANCE',
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/login',
                            arguments: 'Maintenance',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const _BottomStatusBar(),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.navy,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _DepartmentTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DepartmentTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 130,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.navy, size: 26),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomStatusBar extends StatelessWidget {
  const _BottomStatusBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navyDark,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildStatusItem(Icons.access_time, 'Mon - Sun · 8am - 5pm'),
          _buildStatusItem(Icons.call_outlined, 'Ext. 142 / 140'),
          _buildStatusItem(
              Icons.list_alt_outlined, 'Real-time Ticket Tracking'),
          const Text(
            '© 2025 UniKL RCMP · RUSH  |  User Manual',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
