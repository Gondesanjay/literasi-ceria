import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'login_page.dart';
import 'activity_history_page.dart'; // <-- Pastikan ini di-import

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List _daftarMurid = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMuridData();
  }

  // Fungsi (WORKAROUND) untuk filter murid di Flutter
  Future<void> _fetchMuridData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      final int? userId = prefs.getInt('user_id'); // ID Guru

      if (token == null || userId == null) {
        _logout();
        return;
      }

      // 1. Ambil SEMUA murid, tapi populate data 'guru_pengajar'
      final String apiUrl =
          "http://10.0.2.2:1337/api/students?populate=guru_pengajar";

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
          if (student['guru_pengajar'] == null) {
            return false;
          }
          final int? guruMuridId = student['guru_pengajar']['id'];
          if (guruMuridId == null) {
            return false;
          }
          // Tampilkan HANYA jika ID Guru Murid == ID Guru yang login
          return guruMuridId == userId;
        }).toList();

        setState(() {
          _daftarMurid = filteredStudents;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal mengambil data murid: ${response.statusCode}';
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
    await prefs.clear(); // Hapus semua sesi
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
        title: const Text('Dasbor Guru'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _buildMuridList(),
    );
  }

  Widget _buildMuridList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_daftarMurid.isEmpty) {
      return const Center(
        child: Text('Belum ada data murid yang tertaut ke akun Anda.'),
      );
    }

    // Tampilkan daftar
    return ListView.builder(
      itemCount: _daftarMurid.length,
      itemBuilder: (context, index) {
        final item = _daftarMurid[index];
        final String nama = item['nama_lengkap'] ?? 'Tanpa Nama';
        final int studentId = item['id'];

        // Dibuat bisa diklik (Langkah 48)
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
              leading: const Icon(Icons.person, color: Colors.teal),
              title: Text(nama),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        );
      },
    );
  }
}
