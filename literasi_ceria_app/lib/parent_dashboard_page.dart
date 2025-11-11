import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'login_page.dart';
import 'activity_history_page.dart'; // <-- Pastikan ini di-import

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  List _daftarAnak = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAnakData();
  }

  // Fungsi (WORKAROUND) untuk filter anak di Flutter
  Future<void> _fetchAnakData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      final int? userId = prefs.getInt('user_id'); // ID Ortu

      if (token == null || userId == null) {
        _logout();
        return;
      }

      // 1. Ambil SEMUA murid, tapi populate data 'orang_tua_wali'
      final String apiUrl =
          "http://10.0.2.2:1337/api/students?populate=orang_tua_wali";

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
        final List allStudents = data['data'];

        // 2. Filter di sisi KLIEN (Flutter)
        final List filteredStudents = allStudents.where((student) {
          final List? ortuList = student['orang_tua_wali'];
          if (ortuList == null || ortuList.isEmpty) {
            return false;
          }
          // Cek apakah ID Ortu yang login ada di dalam daftar wali
          return ortuList.any((ortu) => ortu['id'] == userId);
        }).toList();

        setState(() {
          _daftarAnak = filteredStudents;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal mengambil data anak: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e. Pastikan Strapi berjalan.';
        _isLoading = false;
      });
    }
  }

  // Fungsi Logout
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dasbor Orang Tua'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _buildAnakList(),
    );
  }

  Widget _buildAnakList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_daftarAnak.isEmpty) {
      return const Center(
        child: Text('Belum ada data anak yang tertaut ke akun Anda.'),
      );
    }

    return ListView.builder(
      itemCount: _daftarAnak.length,
      itemBuilder: (context, index) {
        final item = _daftarAnak[index];
        final String nama = item['nama_lengkap'] ?? 'Tanpa Nama';
        final int studentId = item['id'];

        // Dibuat bisa diklik (Langkah 49)
        return InkWell(
          onTap: () {
            print("Melihat riwayat untuk: $nama (ID: $studentId)");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityHistoryPage(
                  studentId: studentId,
                  studentName: nama,
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: const Icon(Icons.face, color: Colors.deepPurple),
              title: Text(nama),
              subtitle: const Text("Lihat Riwayat Aktivitas"),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        );
      },
    );
  }
}
