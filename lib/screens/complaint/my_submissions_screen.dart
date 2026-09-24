import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../main.dart';

/// "My Submissions" — list of all complaints/requests the signed-in user has submitted.
class MySubmissionsScreen extends StatefulWidget {
  const MySubmissionsScreen({super.key});

  @override
  State<MySubmissionsScreen> createState() => _MySubmissionsScreenState();
}

class _MySubmissionsScreenState extends State<MySubmissionsScreen> {
  // Pengurus data asal dari database
  List<dynamic> _listTickets = [];

  // 👇 1. SENARAI BARU UNTUK MENYIMPAN DATA YANG TELAH DITAPIS
  List<dynamic> _filteredTickets = [];

  // 👇 2. CONTROLLER UNTUK MENGESAN TAIPAN USER PADA KOTAK CARIAN
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
   String get _emailStaff => currentLoggedInUserEmail ?? "user@gmail.com";


  @override
  void initState() {
    super.initState();
    _ambilDataSubmissions();

    // Tambah listener untuk kesan setiap kali user menaip huruf di kotak carian
    _searchController.addListener(_laksanakanCarian);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _ambilDataSubmissions() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse('http://$domain/helpdesk_api/get_my_submissions.php?email=${_emailStaff.trim()}');

    try {
      final respon = await http.get(url);

      if (respon.statusCode == 200) {
        // Dekod data json dengan selamat
        final decodedData = json.decode(respon.body);

        setState(() {
          // Semak jika data wujud dan ia adalah sejenis List (Array)
          if (decodedData != null && decodedData is List) {
            _listTickets = decodedData;
            _filteredTickets = decodedData;
          } else {
            // Jika data rosak atau null, setkan sebagai senarai kosong
            _listTickets = [];
            _filteredTickets = [];
          }
          _isLoading = false;
        });
      } else {
        print("Gagal muat submissions. Status: ${respon.statusCode}");
        setState(() {
          _listTickets = [];
          _filteredTickets = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Ralat sambungan Laragon: $e");
      setState(() {
        _listTickets = [];
        _filteredTickets = [];
        _isLoading = false;
      });
    }
  }


  // filter function
  void _laksanakanCarian() {
    String kataKunci = _searchController.text.toLowerCase().trim();

    setState(() {
      if (kataKunci.isEmpty) {
        // Jika kotak carian kosong, papar semula semua tiket
        _filteredTickets = _listTickets;
      } else {
        // Tapis berdasarkan Ticket ID, Title (Kategori), atau Submitter Name
        _filteredTickets = _listTickets.where((ticket) {
          String ticketId = (ticket['ticket_id'] ?? '').toString().toLowerCase();
          String title = (ticket['title'] ?? '').toString().toLowerCase();
          String name = (ticket['submitter_name'] ?? '').toString().toLowerCase();

          return ticketId.contains(kataKunci) ||
              title.contains(kataKunci) ||
              name.contains(kataKunci);
        }).toList();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return const Color(0xFF2E9E52);
      case 'in_progress':
        return Colors.orange;
      default:
        return const Color(0xFF2F5FA3);
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return const Color(0xFFEAF7EE);
      case 'in_progress':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFEAF1FB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy),
        title: const Text('UniKL RCMP Help Desk',
            style: TextStyle(color: AppColors.navy, fontSize: 14, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.description_outlined, color: Color(0xFF2F5FA3), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Submissions',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text('All complaints  requests you have submitted.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),


            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController, // Menyambungkan taipan ke controller carian
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search by ID, title or category',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Memaparkan jumlah dinamik tiket yang berjaya dijumpai hasil tapisan carian
            Text('Showing ${_filteredTickets.length} of ${_listTickets.length} tickets',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 10),

            if (_filteredTickets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('No matching tickets found.', style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
              ),

            ..._filteredTickets.map((ticket) {
              String currentStatus = ticket['status'] ?? 'open';

              String tarikhMentah = ticket['created_at'] ?? '';
              String tarikhDipapar = 'No Date';

              if (tarikhMentah.isNotEmpty && tarikhMentah.length >= 10) {
                String ymd = tarikhMentah.substring(0, 10); // Ambil Tahun-Bulan-Hari
                List<String> susunan = ymd.split('-');
                if (susunan.length == 3) {
                  tarikhDipapar = "${susunan[2]}-${susunan[1]}-${susunan[0]}"; // Susun jadi Hari-Bulan-Tahun
                }
              }

              // Pulangkan terus tanpa balutan Padding tambahan
              return _ActivityRow(
                reference: ticket['ticket_id'] ?? 'No Reference',
                title: ticket['title'] ?? 'No Title Provided',
                department: tarikhDipapar,
                statusLabel: currentStatus == 'open' ? 'Open' : (currentStatus == 'in_progress' ? 'In Progress' : 'Closed'),
                statusColor: _getStatusColor(currentStatus),
                statusBg: _getStatusBg(currentStatus),
                onView: () {
                  Navigator.pushNamed(
                    context,
                    '/tickets/user-detail',
                    arguments: ticket,
                  );
                },
              );
            }),



            const SizedBox(height: 4),
            const Align(alignment: Alignment.centerRight),
          ],
        ),
      ),
    );
  }
}


class _ActivityRow extends StatelessWidget {
  final String reference;
  final String title;
  final String department;
  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
  final VoidCallback onView;

  const _ActivityRow({
    required this.reference,
    required this.title,
    required this.department,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onView, // Membolehkan seluruh kawasan baris kad boleh diklik untuk ke detail page
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FB),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.assignment_outlined, color: Color(0xFF2F5FA3), size: 18),
            ),
            const SizedBox(width: 14),

            // Bahagian Teks Kandungan Tengah
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tajuk Aduan / Nama Kategori Jabatan (Teks Tebal Atas)
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Baris Bawah: Gabungan No Rujukan & Tarikh
                  Row(
                    children: [
                      Text(
                        reference,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      const Text('·', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(
                        department, // Memaparkan tarikh pendek (cth: 19-08-2026)
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Bahagian Hujung Kanan: Tag Status & Ikon Anak Panah Meluncur
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 10.5, color: statusColor, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
