import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Untuk memanggil API
import 'package:shared_preferences/shared_preferences.dart'; // Untuk ambil token
import 'dart:convert'; // Untuk jsonDecode

// Model Sederhana untuk Laporan
class Laporan {
  int totalAktivitas = 0;
  int totalVideo = 0;
  int totalGame = 0;
  int totalDurasi = 0;

  Laporan();
}

// Model Sederhana untuk Kamus Konten
class ContentInfo {
  final String judul;
  final String tipe;
  ContentInfo({required this.judul, required this.tipe});
}

class ActivityHistoryPage extends StatefulWidget {
  final int studentId;
  final String studentName;

  const ActivityHistoryPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  List _activityLogs = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // === INI KAMUS YANG SUDAH DIPERBAIKI ===
  // Cth: "8" -> ContentInfo(judul: "Cerita Kancil", tipe: "video_cerita")
  Map<String, ContentInfo> _contentMap = {};
  // === AKHIR PERBAIKAN ===

  Laporan _laporan = Laporan(); // Objek untuk menyimpan hasil analisis

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Sesi tidak ditemukan. Silakan login ulang.');
      }

      // 1. Ambil "kamus" konten dulu (ini penting untuk analisis)
      await _fetchContentMap(token);

      // 2. Ambil log aktivitas
      await _fetchActivityLogs(token);

      // 3. (BARU) Analisis log yang sudah didapat
      _analyzeLogs();

      // 4. Setelah semua selesai, matikan loading
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}. Pastikan Strapi berjalan.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchActivityLogs(String token) async {
    final String apiUrl =
        "http://10.0.2.2:1337/api/activity-logs?filters[student_id][\$eq]=${widget.studentId}";

    final response = await http
        .get(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _activityLogs = data['data'];
      });
    } else {
      throw Exception('Gagal mengambil riwayat: ${response.statusCode}');
    }
  }

  // --- FUNGSI KAMUS (DIPERBAIKI) ---
  Future<void> _fetchContentMap(String token) async {
    final String apiUrl = "http://10.0.2.2:1337/api/contents?populate=*";

    final response = await http
        .get(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List allContent = data['data'];

      // Buat "kamus" kita
      Map<String, ContentInfo> tempMap = {};
      for (var item in allContent) {
        tempMap[item['id'].toString()] = ContentInfo(
          judul: item['judul'] ?? 'Konten Tanpa Judul',
          tipe: item['tipe_konten'] ?? 'unknown',
        );
      }

      // Simpan "kamus" ke state
      setState(() {
        _contentMap = tempMap;
      });
    } else {
      throw Exception('Gagal mengambil data konten: ${response.statusCode}');
    }
  }
  // --- AKHIR FUNGSI KAMUS (DIPERBAIKI) ---

  // --- FUNGSI ANALISIS (DIPERBAIKI) ---
  void _analyzeLogs() {
    if (_activityLogs.isEmpty || _contentMap.isEmpty) return;

    Laporan laporanBaru = Laporan();
    laporanBaru.totalAktivitas = _activityLogs.length;

    for (var log in _activityLogs) {
      // Tambahkan durasi
      laporanBaru.totalDurasi += (log['durasi'] ?? 0) as int;

      // Cek tipe konten
      final String contentId = log['content_id'] ?? '??';
      final ContentInfo? info = _contentMap[contentId]; // Cari di kamus

      if (info != null) {
        if (info.tipe == 'video_cerita') {
          laporanBaru.totalVideo += 1;
        } else if (info.tipe == 'game_huruf' || info.tipe == 'game_angka') {
          laporanBaru.totalGame += 1;
        }
      }
    }

    setState(() {
      _laporan = laporanBaru;
    });
  }
  // === AKHIR FUNGSI ANALISIS (DIPERBAIKI) ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat: ${widget.studentName}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBodyWithTabs(),
    );
  }

  Widget _buildBodyWithTabs() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.analytics), text: "Laporan"),
              Tab(icon: Icon(Icons.history), text: "Riwayat"),
            ],
          ),

          Expanded(
            child: TabBarView(
              children: [
                // === Isi Tab 1: Laporan (Analisis Kualitatif) ===
                _buildLaporanTab(),

                // === Isi Tab 2: Riwayat (Daftar Log) ===
                _buildLogList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk Tab 1: Laporan
  Widget _buildLaporanTab() {
    if (_activityLogs.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data untuk dianalisis.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    // Ubah durasi dari detik ke menit
    final int totalMenit = (_laporan.totalDurasi / 60).round();

    // Ini adalah "Insight Deskriptif" sederhana kita
    String insight = "Murid ini seimbang antara video dan game.";
    if (_laporan.totalVideo > _laporan.totalGame) {
      insight = "Murid ini lebih menyukai video cerita.";
    } else if (_laporan.totalGame > _laporan.totalVideo) {
      insight = "Murid ini lebih menyukai aktivitas game.";
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ringkasan Kualitatif",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 20),

          // Card 1
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text("Total Aktivitas Selesai"),
              subtitle: Text("${_laporan.totalAktivitas} aktivitas"),
            ),
          ),

          // Card 2
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.timer, color: Colors.orange),
              title: const Text("Total Waktu Belajar"),
              subtitle: Text("~$totalMenit menit"),
            ),
          ),

          // Card 3
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.movie_filter, color: Colors.red),
              title: const Text("Total Video Ditonton"),
              subtitle: Text("${_laporan.totalVideo} video"),
            ),
          ),

          // Card 4
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.games, color: Colors.blue),
              title: const Text("Total Game Dimainkan"),
              subtitle: Text("${_laporan.totalGame} game"),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            "Insight Sederhana",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          Text(
            insight,
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // Widget untuk Tab 2: Riwayat (Kode lama kita)
  Widget _buildLogList() {
    if (_activityLogs.isEmpty) {
      return const Center(
        child: Text(
          'Murid ini belum memiliki riwayat aktivitas.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _activityLogs.length,
      itemBuilder: (context, index) {
        final item = _activityLogs[index];
        final String contentId = item['content_id'] ?? '??';
        final int durasi = item['durasi'] ?? 0;

        // Cari nama konten di "kamus" _contentMap kita
        final String contentName =
            _contentMap[contentId]?.judul ?? 'Konten (ID: $contentId)';
        final String contentType = _contentMap[contentId]?.tipe ?? 'unknown';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: Icon(
              contentType == 'video_cerita' ? Icons.movie_filter : Icons.games,
              color: Colors.indigo,
            ),
            title: Text(contentName),
            subtitle: Text('Selama $durasi detik'),
          ),
        );
      },
    );
  }
}
