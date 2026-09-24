import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// FUNGSI PEMANGGIL GLOBAL DIALOG EDIT STAFF VENDOR (NAMA BARU!)
Future<void> showEditStaffVendorDialog(BuildContext context,
    Map<String, dynamic> staff, VoidCallback onStaffUpdated) {
  return showDialog(
    context: context,
    builder: (context) =>
        EditStaffVendorDialog(staff: staff, onStaffUpdated: onStaffUpdated),
  );
}

class EditStaffVendorDialog extends StatefulWidget {
  final Map<String, dynamic> staff;
  final VoidCallback onStaffUpdated;
  const EditStaffVendorDialog(
      {super.key, required this.staff, required this.onStaffUpdated});

  @override
  State<EditStaffVendorDialog> createState() => _EditStaffVendorDialogState();
}

class _EditStaffVendorDialogState extends State<EditStaffVendorDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _positionCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.staff['full_name']);
    _positionCtrl = TextEditingController(text: widget.staff['position']);
  }

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
              const Text('Edit Staff',
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.black54))),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A365D),
                        foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      widget
                          .onStaffUpdated(); // TODO: Link database API kemaskini data staff vendor
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
