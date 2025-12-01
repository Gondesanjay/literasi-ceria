import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'login_page.dart';
import 'activity_history_page.dart';
import 'teacher_content_detail.dart';

// GANTI DENGAN IP WIFI-MU YANG BENAR
const String _strapiIP = "http://192.168.1.11:1337";

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Data
  List _daftarMurid = [];
  List _daftarMateri = [];

  // State Loading Terpisah (Ini Kuncinya!)
  bool _isLoadingMurid = true; // Loading Awal (Memblokir layar)
  bool _isLoadingMateri = true; // Loading Latar Belakang (Hanya di tab materi)

  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Kita mulai dengan mengambil Murid dulu (Prioritas Utama)
    _fetchMuridData();
  }

  // 1. FUNGSI AMBIL MURID (Cepat & Wajib)
  Future<void> _fetchMuridData() async {
    setState(() => _isLoadingMurid = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      final int? userId = prefs.getInt('user_id');

      if (token == null || userId == null) {
        _logout();
        return;
      }

      final String muridUrl = "$_strapiIP/api/students?populate=guru_pengajar";

      final response = await http.get(
        Uri.parse(muridUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dataMurid = jsonDecode(response.body)['data'];

        // Filter Murid
        final List filteredStudents = (dataMurid as List).where((student) {
          if (student['guru_pengajar'] == null) return false;
          return student['guru_pengajar']['id'] == userId;
        }).toList();

        if (!mounted) return;
        setState(() {
          _daftarMurid = filteredStudents;
          _isLoadingMurid = false; // STOP LOADING UTAMA DI SINI!
        });

        // SETELAH MURID SELESAI, BARU KITA AMBIL MATERI DI BACKGROUND
        _fetchMateriData(token);
      } else {
        throw Exception('Gagal ambil murid: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error Murid: $e. Pastikan Strapi jalan.';
        _isLoadingMurid = false;
      });
    }
  }

  // 2. FUNGSI AMBIL MATERI (Background / Lazy)
  Future<void> _fetchMateriData(String token) async {
    // Jangan set isLoadingMurid = true, biarkan user melihat dasbor!
    // Kita hanya set loading khusus untuk tab materi
    setState(() => _isLoadingMateri = true);

    try {
      final String materiUrl = "$_strapiIP/api/contents?populate=*";
      final response = await http.get(
        Uri.parse(materiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dataMateri = jsonDecode(response.body)['data'];

        if (!mounted) return;
        setState(() {
          _daftarMateri = dataMateri;
          _isLoadingMateri = false; // Selesai load materi
        });
      } else {
        print("Gagal ambil materi: ${response.statusCode}");
        setState(() => _isLoadingMateri = false);
      }
    } catch (e) {
      print("Error Materi: $e");
      setState(() => _isLoadingMateri = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dasbor Guru'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Daftar Murid"),
              Tab(icon: Icon(Icons.library_books), text: "Pustaka Materi"),
            ],
          ),
        ),
        // JIKA MASIH LOADING MURID (AWAL), TAMPILKAN LOADING PENUH
        body: _isLoadingMurid
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : (_errorMessage.isNotEmpty)
            ? Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            : TabBarView(
                children: [
                  // TAB 1: SUDAH SIAP (Karena _isLoadingMurid sudah false)
                  _buildMuridList(),

                  // TAB 2: MUNGKIN MASIH LOADING (Cek _isLoadingMateri)
                  _buildMateriList(),
                ],
              ),
      ),
    );
  }

  Widget _buildMuridList() {
    if (_daftarMurid.isEmpty)
      return const Center(child: Text("Belum ada data murid."));

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _daftarMurid.length,
      itemBuilder: (context, index) {
        final item = _daftarMurid[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(item['nama_lengkap'] ?? '-'),
            subtitle: const Text("Ketuk untuk lihat laporan"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivityHistoryPage(
                    studentId: item['id'],
                    studentName: item['nama_lengkap'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMateriList() {
    // === LAZY LOADING UI ===
    // Jika materi masih diambil di background, tampilkan loading KECIL di tab ini saja
    if (_isLoadingMateri) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Sedang memuat materi ajar..."),
          ],
        ),
      );
    }
    // =======================

    if (_daftarMateri.isEmpty)
      return const Center(child: Text("Belum ada materi."));

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _daftarMateri.length,
      itemBuilder: (context, index) {
        final item = _daftarMateri[index];
        final String judul = item['judul'] ?? '-';
        final String tipe = item['tipe_konten'] ?? '-';

        String? thumbUrl;
        if (item['thumbnail'] != null && item['thumbnail']['url'] != null) {
          String rawUrl = item['thumbnail']['url'];
          if (rawUrl.startsWith('http')) {
            thumbUrl = rawUrl.replaceAll("http://localhost:1337", _strapiIP);
          } else {
            thumbUrl = _strapiIP + rawUrl;
          }
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: thumbUrl != null
                  ? Image.network(
                      thumbUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.image),
                    )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
            title: Text(
              judul,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              tipe.toUpperCase().replaceAll('_', ' '),
              style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
            ),
            trailing: const Icon(Icons.play_circle_fill, color: Colors.teal),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherContentDetail(item: item),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
