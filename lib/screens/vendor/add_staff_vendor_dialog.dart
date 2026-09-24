import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 🌟 FUNGSI PEMANGGIL GLOBAL DIALOG ADD STAFF VENDOR (NAMA BARU!) 🌟
Future<void> showAddStaffVendorDialog(
    BuildContext context, VoidCallback onStaffAdded) {
  return showDialog(
    context: context,
    builder: (context) => AddStaffVendorDialog(onStaffAdded: onStaffAdded),
  );
}

class AddStaffVendorDialog extends StatefulWidget {
  final VoidCallback onStaffAdded;
  const AddStaffVendorDialog({super.key, required this.onStaffAdded});

  @override
  State<AddStaffVendorDialog> createState() => _AddStaffVendorDialogState();
}

class _AddStaffVendorDialogState extends State<AddStaffVendorDialog> {
  final _nameCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _positionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Staff',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const Divider(height: 20),
              const Text('FULL NAME *',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'e.g. Ahmad Faisal',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              const Text('POSITION / JOB TITLE *',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _positionCtrl,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'e.g. Network Technician',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.black54)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A365D),
                        foregroundColor: Colors.white),
                    onPressed: () {
                      if (_nameCtrl.text.isNotEmpty &&
                          _positionCtrl.text.isNotEmpty) {
                        Navigator.pop(context);
                        widget
                            .onStaffAdded(); // // TODO: Link database API hantaran data staff vendor
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
