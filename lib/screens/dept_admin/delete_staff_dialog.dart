import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';

Future<void> showDeleteStaffDialog(BuildContext context, {required String staffName, required String staffCode}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return _DeleteStaffDialogContent(staffName: staffName, staffCode: staffCode);
    },
  );
}

class _DeleteStaffDialogContent extends StatefulWidget {
  final String staffName;
  final String staffCode;

  const _DeleteStaffDialogContent({required this.staffName, required this.staffCode});

  @override
  State<_DeleteStaffDialogContent> createState() => _DeleteStaffDialogContentState();
}

class _DeleteStaffDialogContentState extends State<_DeleteStaffDialogContent> {
  bool _isDeleting = false;

  Future<void> _padamStaffDariDatabase() async {
    setState(() => _isDeleting = true);
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse('http://$domain/helpdesk_api/delete_staff.php');

    try {
      final respon = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "staff_code": widget.staffCode,
        }),
      );

      if (respon.statusCode == 200) {
        final hasil = json.decode(respon.body);
        if (hasil['status'] == 'berjaya') {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hasil['mesej'])));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hasil['mesej'])));
        }
      }
    } catch (e) {
      print("Ralat: $e");
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.delete_forever, color: Color(0xFFD64545), size: 22),
                const SizedBox(width: 8),
                const Text('Delete Staff Member', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD64545))),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                children: [
                  const TextSpan(text: 'Delete '),
                  TextSpan(text: widget.staffName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD64545))),
                  const TextSpan(text: '?\n\nThis action is '),
                  const TextSpan(text: 'permanent', style: TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: ' and cannot be undone. The staff member will be completely removed from the unicomplaint help desk system.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.shade100)),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Make sure all open tickets are reassigned before deleting.', style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                const SizedBox(width: 10),
                _isDeleting
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD64545), foregroundColor: Colors.white),
                  onPressed: _padamStaffDariDatabase,
                  child: const Text('Yes, Delete Staff', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
