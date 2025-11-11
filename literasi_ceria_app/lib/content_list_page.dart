import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import untuk API
import 'dart:convert'; // Import untuk jsonDecode

import 'detail_page.dart'; // Import halaman detail yang baru

//========================================================
//=== KODE FINAL: content_list_page.dart
//========================================================

class ContentListPage extends StatefulWidget {
  final int studentId;
  const ContentListPage({super.key, required this.studentId});

  @override
  State<ContentListPage> createState() => _ContentListPageState();
}

class _ContentListPageState extends State<ContentListPage> {
  List _daftarKonten = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // === INI PERBAIKANNYA ===
  // Kita HAPUS "?populate=file_konten" karena field itu sudah tidak ada.
  // Field 'video_url' (Teks) akan otomatis terkirim.
  final String _apiUrl = "http://10.0.2.2:1337/api/contents";
  // === AKHIR PERBAIKAN ===

  @override
  void initState() {
    super.initState();
    _fetchData();
    print("Membuka Pojok Cerita untuk Murid ID: ${widget.studentId}");
  }

  Future<void> _fetchData() async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      print("===== RESPON KONTEN (Status: ${response.statusCode}) =====");
      print(response.body); // Cek log ini, 'video_url' akan muncul

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _daftarKonten = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Gagal mengambil data: ${response.statusCode}. Body: ${response.body}';
          _isLoading = false;
        });
        print(_errorMessage);
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Error: $e. Pastikan Strapi berjalan dan IP 10.0.2.2 bisa diakses.';
        _isLoading = false;
      });
      print(_errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pojok Cerita'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // ... (kode error & empty state tidak berubah) ...
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_daftarKonten.isEmpty) {
      return const Center(child: Text('Belum ada konten di Strapi.'));
    }

    return ListView.builder(
      itemCount: _daftarKonten.length,
      itemBuilder: (context, index) {
        final item = _daftarKonten[index];
        final String judul = item['judul'] ?? 'Tanpa Judul';
        final String tipe = item['tipe_konten'] ?? 'Tipe Tidak Diketahui';

        return InkWell(
          onTap: () {
            print("Kamu mengklik: $judul (oleh Murid ID: ${widget.studentId})");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DetailPage(item: item, studentId: widget.studentId),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: Icon(
                tipe == 'video_cerita'
                    ? Icons.movie_filter
                    : (tipe == 'game_angka'
                          ? Icons.format_list_numbered
                          : Icons.games),
                color: Colors.blueAccent,
              ),
              title: Text(judul),
              subtitle: Text(tipe),
            ),
          ),
        );
      },
    );
  }
}
