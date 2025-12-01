import 'package:flutter/material.dart';
import 'video_player_widget.dart'; // Kita reuse player yang sudah ada
import 'quiz_game_widget.dart';   // Kita reuse game widget
import 'number_game_widget.dart'; // Kita reuse game angka

class TeacherContentDetail extends StatelessWidget {
  final Map<String, dynamic> item;

  const TeacherContentDetail({super.key, required this.item});

  // Fungsi sederhana untuk mengambil teks dari Rich Text Strapi
  String _parseDescription(dynamic descData) {
    try {
      // Strapi v5 Rich Text biasanya berupa List of Blocks
      if (descData is List && descData.isNotEmpty) {
        // Ambil paragraf pertama, anak pertama, teksnya
        return descData[0]['children'][0]['text'] ?? 'Tidak ada panduan diskusi.';
      } else if (descData is String) {
        return descData;
      }
      return 'Tidak ada panduan diskusi tersedia.';
    } catch (e) {
      return 'Format deskripsi tidak dapat ditampilkan.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String judul = item['judul'] ?? 'Tanpa Judul';
    final String tipe = item['tipe_konten'] ?? 'unknown';
    final dynamic deskripsiRaw = item['deskripsi'];
    final String panduanDiskusi = _parseDescription(deskripsiRaw);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Presentasi Guru'),
        backgroundColor: Colors.teal, // Warna formal Guru
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // Agar bisa di-scroll jika teks panjang
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. AREA KONTEN (Video/Game)
            Container(
              height: 250, // Tinggi tetap untuk area preview
              color: Colors.black,
              child: _buildPreviewContent(tipe, item),
            ),

            // 2. JUDUL MATERI
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.teal),
                    ),
                    child: Text(
                      tipe.toUpperCase().replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1),

            // 3. PANDUAN DISKUSI (Fitur Utama)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.orange),
                      SizedBox(width: 10),
                      Text(
                        "Panduan Diskusi Kelas",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      panduanDiskusi,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Tips: Gunakan pertanyaan di atas untuk memancing interaksi murid setelah menonton video.",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(String tipe, Map<String, dynamic> item) {
    // Kita reuse widget yang ada, tapi tanpa tracking log (studentId: 0)
    // karena ini Guru yang menonton.
    if (tipe == 'video_cerita') {
      return VideoPlayerWidget(item: item);
    } else if (tipe == 'game_huruf') {
      return QuizGameWidget(contentId: item['id'], studentId: 0);
    } else if (tipe == 'game_angka') {
      return NumberGameWidget(contentId: item['id'], studentId: 0);
    } else {
      return const Center(child: Text("Konten tidak didukung", style: TextStyle(color: Colors.white)));
    }
  }
}