import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';

// Fungsi utama untuk memanggil kotak pop-up dari mana-mana skrin user
Future<bool?> showUserFeedbackPopup(BuildContext context, {required String ticketId}) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // Paksa user isi atau tekan cancel (tidak boleh klik luar kotak)
    builder: (BuildContext context) {
      return _FeedbackPopupContent(ticketId: ticketId);
    },
  );
}

class _FeedbackPopupContent extends StatefulWidget {
  final String ticketId;
  const _FeedbackPopupContent({required this.ticketId});

  @override
  State<_FeedbackPopupContent> createState() => _FeedbackPopupContentState();
}

class _FeedbackPopupContentState extends State<_FeedbackPopupContent> {
  bool _isSaving = false;
  int _selectedRating = 5; // Nilai lalai 5 Bintang
  final TextEditingController _commentController = TextEditingController();

  // Senarai Emoji dan Label mengikut database (1=Very Dissatisfied ... 5=Very Satisfied)
  final List<String> _emojis = ['🤬', '🙁', '😐', '🙂', '🥰'];
  final List<String> _labels = [
    'Very Dissatisfied',
    'Dissatisfied',
    'Average Support',
    'Satisfied',
    'Very Satisfied'
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    setState(() => _isSaving = true);
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse('http://$domain/helpdesk_api/add_ticket_feedback.php');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "ticket_id": widget.ticketId,
          "submitter_id": 1, // Boleh diganti dengan ID pengadu live session
          "rating": _selectedRating,
          "comment": _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> resData = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resData['mesej'] ?? 'Thank you!')));
          Navigator.pop(context, true); // Tutup pop-up dan pulangkan nilai 'true' untuk refresh skrin asal
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Network error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        width: 420, // Lebar kotak pop-up yang sangat ngam dan seimbang
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Paksa kotak mengikut ketinggian kandungan sahaja
          children: [
            // Header Pop-up
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.rate_review_outlined, color: AppColors.navy, size: 20),
                    SizedBox(width: 8),
                    Text('Rate Our Support', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            const Text('How was your complaint resolution experience?', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            // 💡 EMOTICON DIAL LIVE: Berubah saiz dan rupa mengikut ketukan bintang 💡
            Text(_emojis[_selectedRating - 1], style: const TextStyle(fontSize: 54)),
            const SizedBox(height: 6),
            Text(_labels[_selectedRating - 1], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _selectedRating >= 4 ? const Color(0xFF2E9E52) : const Color(0xFFC9A227))),
            const SizedBox(height: 16),

            // Barisan Bintang Kuning Interaktif
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                int starValue = index + 1;
                bool isLit = starValue <= _selectedRating;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = starValue),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isLit ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 34,
                      color: const Color(0xFFC9A227),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),

            // Ruangan Input Komen Teks
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Write a comment (Optional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _commentController,
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Share your thoughts with us...',
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppColors.pageBackground,
              ),
            ),
            const SizedBox(height: 20),

            // Butang Aksi Bawah Pop-up
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Maybe Later', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                  onPressed: _submitFeedback,
                  child: const Text('Submit Feedback', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
