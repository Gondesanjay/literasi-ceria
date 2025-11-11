import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Untuk API
import 'dart:convert'; // Untuk jsonEncode
import 'package:video_player/video_player.dart'; // <-- Import package video

//========================================================
//=== KODE FINAL: DetailPage (Perbaikan URL) ===
//========================================================

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final int studentId;

  const DetailPage({super.key, required this.item, required this.studentId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late VideoPlayerController _controller;
  bool _isLoadingVideo = true;
  bool _isLogging = true;
  bool _logSuccess = false;
  String _errorMessage = '';

  // Kita TIDAK butuh _strapiBaseUrl lagi
  // final String _strapiBaseUrl = "http://10.0.2.2:1337";

  @override
  void initState() {
    super.initState();
    _logActivity();
    _initializeVideoPlayer();
  }

  // --- FUNGSI VIDEO PLAYER (DIPERBARUI TOTAL) ---
  Future<void> _initializeVideoPlayer() async {
    try {
      // 1. Ambil URL mentah dari Strapi (cth: http://localhost:1337/uploads/video.mp4)
      final String? rawVideoUrl = widget.item['video_url'];

      if (rawVideoUrl == null || rawVideoUrl.isEmpty) {
        throw Exception(
          "Video tidak ditemukan di Strapi (video_url null atau kosong).",
        );
      }

      // 2. === INI PERBAIKANNYA (Langkah Final) ===
      // Ganti 'localhost' (yang tidak bisa diakses Emulator)
      // dengan '10.0.2.2' (alamat IP khusus Emulator)
      final String fullVideoUrl = rawVideoUrl.replaceAll(
        "http://localhost:1337", // Teks yang salah
        "http://10.0.2.2:1337", // Teks pengganti yang benar
      );
      // === AKHIR PERBAIKAN ===

      print("Mencoba memutar video dari (setelah replace): $fullVideoUrl");

      _controller = VideoPlayerController.networkUrl(Uri.parse(fullVideoUrl));
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.play();

      setState(() {
        _isLoadingVideo = false;
      });
    } catch (e) {
      print("❌ Error inisialisasi video: $e");
      setState(() {
        _isLoadingVideo = false;
        _errorMessage = "Gagal memuat video: ${e.toString()}";
      });
    }
  }

  // --- FUNGSI LOG (SUDAH BENAR) ---
  Future<void> _logActivity() async {
    // ... (Fungsi _logActivity() kamu sudah 100% benar, tidak perlu diubah) ...
    setState(() {
      _isLogging = true;
    });
    final String apiUrl = "http://10.0.2.2:1337/api/activity-logs";
    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'data': {
                'student_id': widget.studentId.toString(),
                'content_id': widget.item['id'].toString(),
                'durasi': 10,
              },
            }),
          )
          .timeout(const Duration(seconds: 10));

      print("===== MENGIRIM LOG (Status: ${response.statusCode}) =====");
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Log aktivitas berhasil disimpan!");
        setState(() {
          _isLogging = false;
          _logSuccess = true;
        });
      } else {
        print("❌ Gagal menyimpan log. Status: ${response.statusCode}");
        setState(() {
          _isLogging = false;
          _logSuccess = false;
        });
      }
    } catch (e) {
      print("❌ Error saat mengirim log: $e");
      setState(() {
        _isLogging = false;
        _logSuccess = false;
      });
    }
  }

  @override
  void dispose() {
    if (_isLoadingVideo == false && _errorMessage.isEmpty) {
      _controller.dispose();
    }
    super.dispose();
  }

  // --- TAMPILAN BUILD (SUDAH BENAR) ---
  @override
  Widget build(BuildContext context) {
    final String judul = widget.item['judul'] ?? 'Tanpa Judul';

    return Scaffold(
      appBar: AppBar(
        title: Text(judul),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _buildVideoContent(), // Panggil body baru
      ),

      // Tombol Play/Pause (Sudah benar, sembunyi saat loading)
      floatingActionButton: (_isLoadingVideo || _errorMessage.isNotEmpty)
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
    );
  }

  // --- TAMPILAN VIDEO (SUDAH BENAR) ---
  Widget _buildVideoContent() {
    if (_isLoadingVideo) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Memuat video..."),
        ],
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          "Error: $_errorMessage",
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Tampilkan video
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}
