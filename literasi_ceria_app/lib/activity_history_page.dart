import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'log_detail_page.dart'; // <-- 1. IMPORT HALAMAN BARU KITA

// GANTI INI DENGAN ALAMAT IP WIFI-MU
const String _strapiBaseUrl = "http://192.168.1.11:1337";

// Model Laporan (Tidak berubah)
class Laporan {
  int totalAktivitas = 0;
  int totalVideo = 0;
  int totalGame = 0;
  int totalDurasi = 0;
  Laporan();
}

// Model Kamus Konten (Tidak berubah)
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
  Map<String, ContentInfo> _contentMap = {};
  Laporan _laporan = Laporan();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- SEMUA FUNGSI DATA (DI BAWAH INI) SUDAH BENAR ---
  // (Tidak perlu diubah, kita hanya ubah Tampilan)

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
      await Future.wait([_fetchContentMap(token), _fetchActivityLogs(token)]);
      _analyzeLogs();
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
        "$_strapiBaseUrl/api/activity-logs?filters[student_id][\$eq]=${widget.studentId}&sort=createdAt:desc"; // Kita urutkan (sort) agar yang terbaru di atas

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

  Future<void> _fetchContentMap(String token) async {
    final String apiUrl = "$_strapiBaseUrl/api/contents?populate=*";

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
      Map<String, ContentInfo> tempMap = {};
      for (var item in allContent) {
        tempMap[item['id'].toString()] = ContentInfo(
          judul: item['judul'] ?? 'Konten Tanpa Judul',
          tipe: item['tipe_konten'] ?? 'unknown',
        );
      }
      setState(() {
        _contentMap = tempMap;
      });
    } else {
      throw Exception('Gagal mengambil data konten: ${response.statusCode}');
    }
  }

  void _analyzeLogs() {
    if (_activityLogs.isEmpty || _contentMap.isEmpty) return;
    Laporan laporanBaru = Laporan();
    laporanBaru.totalAktivitas = _activityLogs.length;
    for (var log in _activityLogs) {
      laporanBaru.totalDurasi += (log['durasi'] ?? 0) as int;
      final String contentId = log['content_id'] ?? '??';
      final ContentInfo? info = _contentMap[contentId];
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
                _buildLaporanTab(),
                _buildLogList(), // <-- Kita akan ubah ini
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Tab 1: Laporan (Tidak berubah)
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

    final int totalAktivitas = _laporan.totalAktivitas;
    final double videoPct = (totalAktivitas == 0)
        ? 0
        : (_laporan.totalVideo / totalAktivitas) * 100;
    final double gamePct = (totalAktivitas == 0)
        ? 0
        : (_laporan.totalGame / totalAktivitas) * 100;
    List<PieChartSectionData> pieSections = [];

    if (_laporan.totalVideo > 0) {
      pieSections.add(
        PieChartSectionData(
          value: _laporan.totalVideo.toDouble(),
          title: '${videoPct.toStringAsFixed(0)}%',
          color: Colors.redAccent,
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    if (_laporan.totalGame > 0) {
      pieSections.add(
        PieChartSectionData(
          value: _laporan.totalGame.toDouble(),
          title: '${gamePct.toStringAsFixed(0)}%',
          color: Colors.blueAccent,
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    final int totalMenit = (_laporan.totalDurasi / 60).round();

    String insight = "Murid ini seimbang antara video dan game.";
    if (videoPct > 60) {
      insight = "Murid ini lebih menyukai video cerita.";
    } else if (gamePct > 60) {
      insight = "Murid ini lebih menyukai aktivitas game.";
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ringkasan Visual",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: pieSections,
                centerSpaceRadius: 40,
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(color: Colors.redAccent, text: "Video"),
              const SizedBox(width: 20),
              _buildLegend(color: Colors.blueAccent, text: "Game"),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            "Statistik Detail",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text("Total Aktivitas Selesai"),
              subtitle: Text("${_laporan.totalAktivitas} aktivitas"),
            ),
          ),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.timer, color: Colors.orange),
              title: const Text("Total Waktu Belajar"),
              subtitle: Text("~$totalMenit menit"),
            ),
          ),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.movie_filter, color: Colors.red),
              title: const Text("Total Video Ditonton"),
              subtitle: Text("${_laporan.totalVideo} video"),
            ),
          ),
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

  // Widget helper legenda (Tidak berubah)
  Widget _buildLegend({required Color color, required String text}) {
    return Row(
      children: [
        Container(width: 20, height: 20, color: color),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  // === INI WIDGET YANG KITA UBAH (Langkah 81) ===
  // Widget untuk Tab 2: Riwayat
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
        final item = _activityLogs[index]; // Ini adalah Map data log-nya
        final String contentId = item['content_id'] ?? '??';
        final int durasi = item['durasi'] ?? 0;

        // Ambil nama konten dari "kamus" kita
        final String contentName =
            _contentMap[contentId]?.judul ?? 'Konten (ID: $contentId)';
        final String contentType = _contentMap[contentId]?.tipe ?? 'unknown';

        // 2. BUNGKUS DENGAN INKWELL
        return InkWell(
          onTap: () {
            // 3. PINDAH KE HALAMAN DETAIL LOG
            print("Melihat detail log untuk: $contentName");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LogDetailPage(
                  logData: item, // Kirim semua data log
                  contentName: contentName, // Kirim nama kontennya
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: Icon(
                contentType == 'video_cerita'
                    ? Icons.movie_filter
                    : Icons.games,
                color: Colors.indigo,
              ),
              title: Text(contentName),
              subtitle: Text('Selama $durasi detik'),
              trailing: const Icon(Icons.chevron_right), // Tambah ikon panah
            ),
          ),
        );
        // === AKHIR PERUBAHAN ===
      },
    );
  }
}
