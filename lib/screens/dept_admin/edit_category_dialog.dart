import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';

Future<void> showEditCategoryDialog(
    BuildContext context, {
      required String categoryId,
      required String categoryName,
    }) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return _EditCategoryDialogContent(categoryId: categoryId, categoryName: categoryName);
    },
  );
}

class _EditCategoryDialogContent extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const _EditCategoryDialogContent({required this.categoryId, required this.categoryName});

  @override
  State<_EditCategoryDialogContent> createState() => _EditCategoryDialogContentState();
}

class _EditCategoryDialogContentState extends State<_EditCategoryDialogContent> {
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.categoryName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _simpanPerubahanKategori() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse('http://$domain/helpdesk_api/edit_category.php');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "category_id": widget.categoryId,
          "category_name": _nameController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final hasil = json.decode(response.body);
        if (hasil['status'] == 'berjaya') {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hasil['mesej'])));
          }
        }
      }
    } catch (e) {
      print("Ralat: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Category Track', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            const Text('Category Name *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: 12.5),
              decoration: const InputDecoration(contentPadding: EdgeInsets.all(10), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                const SizedBox(width: 10),
                _isSaving
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                  onPressed: _simpanPerubahanKategori,
                  child: const Text('Save Changes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
