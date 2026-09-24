import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// "Remove this item?" confirmation dialog.
///
/// Flow wired per the diagram:
///   Confirm All Submissions --("Cancel" on an item)--> this dialog
///   "Keep Item" --> dismiss dialog (no change)
///
/// Left un-wired on purpose (dialog closes, but no data mutation yet):
///   - "Yes, Remove" only pops the dialog; actually removing the item
///     from the submission batch is a TODO.
Future<void> showRemoveItemDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const RemoveItemDialog(),
  );
}

class RemoveItemDialog extends StatelessWidget {
  const RemoveItemDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(color: Color(0xFFFCEAEA), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.close, color: Color(0xFFD64545), size: 26),
            ),
            const SizedBox(height: 14),
            const Text('Remove this item?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'This item will be removed from your submission. This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Keep Item',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: actually remove the item from the submission batch.
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD64545),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Yes, Remove',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}