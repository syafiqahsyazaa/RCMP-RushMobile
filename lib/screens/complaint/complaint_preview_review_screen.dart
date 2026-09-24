import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'complaint_fill_details_screen.dart';

/// Interface 6: "Submit a Complaint" — Step 2: Preview & Review.
class ComplaintPreviewReviewScreen extends StatelessWidget {
  const ComplaintPreviewReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. TANGKAP SEMUA DATA DENGAN SELAMAT DARI SKRIN SEBELUM INI
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic> dataAduan =
        (args != null) ? args as Map<String, dynamic> : {};

    // Mengambil data aduan yang diisi oleh pengguna
    String category = dataAduan['category'] ?? 'No Category';
    String description = dataAduan['description'] ?? 'No Description';
    String phoneNumber = dataAduan['phone_number'] ?? 'No Phone Number';
    String department = dataAduan['department'] ?? 'No Department';
    String attachmentName = dataAduan['attachment_path'] ?? 'No attachment';

    // 2. MENGAMBIL DATA PROFIL PENGGUNA DINAMIK DARI DATABASE (HASIL LOGIN)
    // Jika data tiada, ia akan menggunakan nilai default Nur Syafiqah Syaza
    String full_name = dataAduan['full_name'] ?? 'NUR SYAFIQAH SYAZA';
    String email = dataAduan['email'] ?? 'syafiqahsyaza@gmail.com';

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: PortalTopBar(
        title: 'UNIKL RCMP',
        subtitle: 'Help Desk System',
        trailing: TextButton.icon(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          ),
          icon: const Icon(Icons.close, size: 14, color: AppColors.navy),
          label: const Text('Close',
              style: TextStyle(color: AppColors.navy, fontSize: 12)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: FlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                const Text('Submit a Complaint',
                    style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                const Text(
                  'Fill the details and your assigned department will attend to your request.',
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 20),
                const StepTracker(currentStep: 2),
                const SizedBox(height: 22),
                const Text('Review Your Complaint',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text(
                  'Please check everything carefully before submitting.',
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 20),
                const SectionHeading(title: 'Your Information'),
                const SizedBox(height: 14),

                // === PAPARAN MAKLUMAT STAFF DINAMIK (DARI DATABASE) ===
                Row(
                  children: [
                    Expanded(
                        child:
                            ReviewField(label: 'Full Name', value: full_name)),
                    const SizedBox(width: 16),
                    Expanded(
                        child:
                            ReviewField(label: 'Email Address', value: email)),
                  ],
                ),
                const SizedBox(height: 16),

                // === PAPARAN PHONE NUMBER & JABATAN DINAMIK (INPUT USER) ===
                Row(
                  children: [
                    Expanded(
                        child: ReviewField(
                            label: 'Phone Number', value: phoneNumber)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: ReviewField(
                            label: 'My Department / Faculty',
                            value: department)),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.border),
                const SizedBox(height: 20),
                const SectionHeading(title: 'Complaint Details'),
                const SizedBox(height: 14),

                // === PAPARAN KATEGORI DINAMIK ===
                Row(
                  children: [
                    Expanded(
                        child: ReviewField(label: 'Category', value: category)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: ReviewField(
                            label: 'Assigned To', value: '$category Team')),
                  ],
                ),
                const SizedBox(height: 16),

                // === show desc ===
                ReviewField(
                  label: 'Description',
                  value: description,
                ),
                const SizedBox(height: 16),
                ReviewField(label: 'Attachment', value: attachmentName),
                const SizedBox(height: 22),
                const InfoBanner(
                  tone: BannerTone.warning,
                  title: "Once submitted, this complaint can't be edited",
                ),
                const SizedBox(height: 12),
                const InfoBanner(
                  tone: BannerTone.success,
                  title:
                      'Working hours active — complaint will be attended to today.',
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SecondaryButton(
                      label: 'Back to Edit',
                      icon: Icons.arrow_back,
                      onPressed: () {
                        // Hanya kembali ke skrin Edit tanpa menyimpan apa-apa data
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 12),
                    SuccessButton(
                      label: 'Next: Review All',
                      icon: Icons.arrow_forward,
                      onPressed: () {
                        // Semak status aduan dari arguments
                        bool isAddAnother = dataAduan['isAddAnother'] ?? false;

                        if (isAddAnother) {
                          // Jika ini aduan dari butang Add Another, kita POP (hantar balik) data ini terus ke skrin Confirm lama
                          // Kita buat pop 2 kali (sekali untuk tutup skrin Preview, sekali untuk tutup skrin Fill)
                          Navigator.pop(context); // Tutup skrin Preview
                          Navigator.pop(context, {
                            'category': category,
                            'description': description,
                            'phone_number': phoneNumber,
                            'department': department,
                            'full_name': full_name,
                            'email': email,
                            'attachment_path': attachmentName,
                            'attached_file_bytes':
                                dataAduan['attachment_file_bytes'],
                            'attachment_file_path':
                                dataAduan['attachment_file_path'],
                          }); // Tutup skrin Fill sambil hantar data baharu ke senarai
                        } else {
                          // Jika aduan pertama (aliran biasa), pergi ke skrin Confirm macam biasa
                          Navigator.pushNamed(
                            context,
                            '/complaint/confirm',
                            arguments: {
                              'category': category,
                              'description': description,
                              'phone_number': phoneNumber,
                              'department': department,
                              'full_name': full_name,
                              'email': email,
                              'attachment_path': attachmentName,
                              'attachment_file_bytes':
                                  dataAduan['attachment_file_bytes'],
                              'attachment_file_path':
                                  dataAduan['attachment_file_path'],
                            },
                          );
                        }
                      },
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
