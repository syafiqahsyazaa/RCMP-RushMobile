import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Ditambah untuk fungsi Clipboard.setData
import '../../theme/app_theme.dart';
import 'add_another_item_dialog.dart';

/// Interface 8: "All Submitted!" success screen.
class ComplaintSubmittedScreen extends StatelessWidget {
  const ComplaintSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. TANGKAP SENARAI TIKET ID YANG DIHANTAR SELEPAS BERJAYA SUBMIT ALL
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic> dataDiterima =
        (args != null && args is Map<String, dynamic>) ? args : {};

    // Jika tiada data (contohnya akses terus), gunakan nombor contoh lalai
    List<String> senaraiTiket =
        List<String>.from(dataDiterima['ticket_ids'] ?? ['RCMP-17082026-1']);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: FlowCard(
            maxWidth: 420,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF7EE),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check_circle,
                      color: Color(0xFF2E9E52), size: 36),
                ),
                const SizedBox(height: 18),
                const Text('All Submitted!',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                const Text(
                  'Your items have been received. Here are your reference numbers.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 22),

                // 2. PAPARKAN SENARAI NOMBOR RUJUKAN SECARA DINAMIK (Boleh papar lebih dari 1 tiket)
                ...senaraiTiket.map((ticketId) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.fieldBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const StatusTag(
                            label: 'COMPLAINT',
                            background: Color(0xFFEAF1FB),
                            foreground: Color(0xFF2F5FA3),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ticketId, // Memaparkan ID tiket dari database
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),

                          // 3. FUNGSI COPY NOMBOR RUJUKAN KE CLIPBOARD
                          IconButton(
                            icon: const Icon(Icons.copy_outlined,
                                size: 16, color: AppColors.textMuted),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: ticketId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Copied reference number: $ticketId')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Submit More',
                        icon: Icons.add,
                        onPressed: () => showAddAnotherItemDialog(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/dashboard',
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.dashboard_outlined, size: 15),
                          label: const Text('Back to Dashboard',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
