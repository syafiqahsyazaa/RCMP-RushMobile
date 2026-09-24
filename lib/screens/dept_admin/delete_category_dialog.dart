import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';

Future<void> showDeleteCategoryDialog(
  BuildContext context, {
  required String categoryId,
  required String categoryName,
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return _DeleteCategoryDialogContent(
          categoryId: categoryId, categoryName: categoryName);
    },
  );
}

class _DeleteCategoryDialogContent extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const _DeleteCategoryDialogContent(
      {required this.categoryId, required this.categoryName});

  @override
  State<_DeleteCategoryDialogContent> createState() =>
      _DeleteCategoryDialogContentState();
}

class _DeleteCategoryDialogContentState
    extends State<_DeleteCategoryDialogContent> {
  bool _isDeleting = false;

  Future<void> _padamKategoriDariDatabase() async {
    setState(() => _isDeleting = true);
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse('http://$domain/helpdesk_api/delete_category.php');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"category_id": widget.categoryId}),
      );

      if (response.statusCode == 200) {
        final hasil = json.decode(response.body);
        if (hasil['status'] == 'berjaya') {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(hasil['mesej'])));
          }
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(hasil['mesej'])));
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
                const Icon(Icons.delete_forever,
                    color: Color(0xFFD64545), size: 22),
                const SizedBox(width: 8),
                const Text('Delete Category Track',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD64545))),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                children: [
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                      text: widget.categoryName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD64545))),
                  const TextSpan(text: '? This action cannot be undone.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.grey))),
                const SizedBox(width: 10),
                _isDeleting
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD64545),
                            foregroundColor: Colors.white),
                        onPressed: _padamKategoriDariDatabase,
                        child: const Text('Yes, Delete',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
