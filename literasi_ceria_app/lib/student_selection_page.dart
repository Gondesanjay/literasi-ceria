import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'content_list_page.dart'; // Halaman "Pojok Cerita"

// Model sederhana untuk data Murid
class Student {
  final int id;
  final String nama;
  // final String? fotoUrl; // Nanti kita tambahkan

  Student({required this.id, required this.nama});

  // Ini membaca data Strapi v5 (tanpa 'attributes')
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(id: json['id'], nama: json['nama_lengkap'] ?? 'Tanpa Nama');
  }
}

class StudentSelectionPage extends StatefulWidget {
  const StudentSelectionPage({super.key});

  @override
  State<StudentSelectionPage> createState() => _StudentSelectionPageState();
}

class _StudentSelectionPageState extends State<StudentSelectionPage> {
  List<Student> _daftarMurid = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  // Fungsi untuk mengambil daftar murid dari Strapi
  Future<void> _fetchStudents() async {
    // API ini butuh izin 'find' di role 'Public' untuk 'Student'
    final String apiUrl =
        "http://10.0.2.2:1337/api/students?populate=foto_profil";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List studentList = data['data'];

        setState(() {
          _daftarMurid = studentList
              .map((json) => Student.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data murid: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e. Pastikan Strapi & jaringan berjalan.';
        _isLoading = false;
      });
    }
  }

  // Fungsi saat profil murid dipilih
  void _onStudentSelected(Student student) {
    print("Anak yang dipilih: ${student.nama} (ID: ${student.id})");

    // Pindah ke Halaman "Pojok Cerita" dan KIRIM ID MURID
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentListPage(
          studentId: student.id, // <-- KITA KIRIM ID MURID
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Profil Kamu'),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.white,
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
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_daftarMurid.isEmpty) {
      return const Center(
        child: Text('Tidak ada profil murid yang terdaftar.'),
      );
    }

    // Tampilkan Grid (kisi-kisi) profil
    return GridView.builder(
      padding: const EdgeInsets.all(20.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 kolom
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _daftarMurid.length,
      itemBuilder: (context, index) {
        final student = _daftarMurid[index];
        return InkWell(
          onTap: () => _onStudentSelected(student),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.face_retouching_natural, // Placeholder ikon wajah
                  size: 60,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 15),
                Text(
                  student.nama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
