import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// IMPORT SEMUA WIDGET KITA
import 'video_player_widget.dart';
import 'quiz_game_widget.dart';
import 'number_game_widget.dart'; // Pastikan file ini sudah ada

// GANTI DENGAN IP WIFI-MU YANG BENAR (Cek ipconfig)
const String _strapiBaseUrl = "http://192.168.1.12:1337";

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final int studentId;

  const DetailPage({super.key, required this.item, required this.studentId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String _tipeKonten = 'unknown';
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _tipeKonten = widget.item['tipe_konten'] ?? 'unknown';

    // Mulai hitung waktu (Stopwatch) saat halaman dibuka
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    // Logika khusus untuk VIDEO:
    // Kita kirim log durasi saat halaman ditutup.
    // (Untuk Game, log dikirim saat anak berhasil menjawab/menang di dalam widget game-nya sendiri)
    if (_tipeKonten == 'video_cerita' && _startTime != null) {
      final endTime = DateTime.now();
      final int durasiNyata = endTime.difference(_startTime!).inSeconds;
      _logVideoActivity(durasiNyata);
    }
    super.dispose();
  }

  // Fungsi Log Khusus Video
  Future<void> _logVideoActivity(int durasiDetik) async {
    // Jangan catat jika durasi terlalu singkat (misal: kepencet)
    if (durasiDetik < 3) return;

    final String apiUrl = "$_strapiBaseUrl/api/activity-logs";
    try {
      await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {
            'student_id': widget.studentId.toString(),
            'content_id': widget.item['id'].toString(),
            'durasi': durasiDetik,
            // Data Laporan Canggih untuk Video
            'module': 'Pojok Cerita',
            'action': 'Menonton Video',
            'result': 'Selesai',
            'detail': 'Menonton selama $durasiDetik detik',
          },
        }),
      );
      print("✅ Log Video Terkirim!");
    } catch (e) {
      print("❌ Error log video: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String judul = widget.item['judul'] ?? 'Tanpa Judul';

    return Scaffold(
      appBar: AppBar(
        title: Text(judul),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      // Body hanya berfungsi sebagai "Penjaga Gerbang"
      body: Center(child: _buildContentBody()),
    );
  }

  // Fungsi "Penjaga Gerbang" yang memilih widget sesuai tipe
  Widget _buildContentBody() {
    // 1. JIKA VIDEO
    if (_tipeKonten == 'video_cerita') {
      return VideoPlayerWidget(item: widget.item);
    }
    // 2. JIKA GAME HURUF (TAMAN HURUF)
    else if (_tipeKonten == 'game_huruf') {
      return QuizGameWidget(
        contentId: widget.item['id'],
        studentId: widget.studentId, // Kirim ID Murid untuk laporan
      );
    }
    // 3. JIKA GAME ANGKA (PETUALANGAN ANGKA)
    else if (_tipeKonten == 'game_angka') {
      return NumberGameWidget(
        contentId: widget.item['id'],
        studentId: widget.studentId, // Kirim ID Murid untuk laporan
      );
    }
    // 4. JIKA TIDAK DIKENALI
    else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 10),
          Text(
            "Tipe konten tidak dikenali: $_tipeKonten",
            style: const TextStyle(color: Colors.red),
          ),
        ],
      );
    }
  }
}
