import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// "Add Another Item" — modal where the user picks what department to
/// file the next item against, from within the Confirm All Submissions
/// screen.
///
/// Flow wired per the diagram:
///   Confirm All Submissions --("+ Add Another")--> this dialog
///   Close (X) --> dismiss dialog
///
/// Left un-wired on purpose (present, but no navigation/action yet):
///   - Department option cards (Information Technology / Maintenance /
///     Admin & Facilities Mgmt) — diagram doesn't show where they lead.
Future<void> showAddAnotherItemDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const AddAnotherItemDialog(),
  );
}

class AddAnotherItemDialog extends StatelessWidget {
  const AddAnotherItemDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Add Another Item',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Choose what you'd like to add next. All items will be submitted together.",
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text('CHOOSE DEPARTMENT',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.4)),
            const SizedBox(height: 10),
            _DeptOption(
              icon: Icons.computer,
              label: 'Information Technology',
              color: const Color(0xFF2F5FA3),
              bg: const Color(0xFFEAF1FB),
              onTap: () {
                // TODO: start a new item pre-filled for the IT department.
              },
            ),
            const SizedBox(height: 10),
            _DeptOption(
              icon: Icons.build_outlined,
              label: 'Maintenance',
              color: const Color(0xFF2E9E52),
              bg: const Color(0xFFEAF7EE),
              onTap: () {
                // TODO: start a new item pre-filled for Maintenance.
              },
            ),
            const SizedBox(height: 10),
            _DeptOption(
              icon: Icons.apartment,
              label: 'Admin & Facilities Mgmt',
              color: const Color(0xFFC9701F),
              bg: const Color(0xFFFCEFE1),
              onTap: () {
                // TODO: start a new item pre-filled for Admin & Facilities.
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DeptOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _DeptOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}