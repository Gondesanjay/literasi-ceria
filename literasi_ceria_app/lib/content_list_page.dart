import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'detail_page.dart';
import 'student_selection_page.dart';

// GANTI INI DENGAN ALAMAT IP WIFI-MU YANG BENAR
const String _strapiIP = "http://192.168.1.11:1337";

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

  final String _apiUrl = "$_strapiIP/api/contents?populate=*";

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

      if (!mounted) return;

      print("===== RESPON KONTEN (Status: ${response.statusCode}) =====");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _daftarKonten = data['data'];
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Gagal mengambil data: ${response.statusCode}.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: $e. Pastikan Strapi berjalan di $_strapiIP';
        _isLoading = false;
      });
      print(_errorMessage);
    }
  }

  Future<void> _gantiProfil() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_student_id');
    await prefs.remove('active_student_name');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const StudentSelectionPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pojok Cerita'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _gantiProfil,
            tooltip: 'Ganti Profil',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_daftarKonten.isEmpty) {
      return const Center(child: Text('Belum ada konten di Strapi.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _daftarKonten.length,
      itemBuilder: (context, index) {
        final item = _daftarKonten[index];
        final String judul = item['judul'] ?? 'Tanpa Judul';
        final String tipe = item['tipe_konten'] ?? 'Tipe Tidak Diketahui';

        // Logika URL Thumbnail
        String? thumbnailUrl;
        if (item['thumbnail'] != null && item['thumbnail']['url'] != null) {
          String urlPath = item['thumbnail']['url'];
          if (urlPath.startsWith('http')) {
            thumbnailUrl = urlPath.replaceAll(
              "http://localhost:1337",
              _strapiIP,
            );
          } else {
            thumbnailUrl = _strapiIP + urlPath;
          }
        }

        // === LOGIKA IKON TERBARU ===
        IconData placeholderIcon;
        if (tipe == 'video_cerita') {
          placeholderIcon = Icons.movie_filter;
        } else if (tipe == 'game_angka') {
          placeholderIcon = Icons.format_list_numbered; // Ikon Angka
        } else {
          placeholderIcon = Icons.games; // Ikon Game Huruf
        }
        // ===========================

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
            elevation: 4,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: (thumbnailUrl != null)
                      ? Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            // Gunakan ikon yang sesuai tipe jika gambar gagal
                            return Icon(
                              placeholderIcon,
                              size: 50,
                              color: Colors.grey[300],
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            placeholderIcon,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    judul,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
