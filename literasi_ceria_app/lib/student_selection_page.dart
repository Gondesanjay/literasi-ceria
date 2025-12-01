import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'content_list_page.dart';

// Menggunakan IP WiFi-mu yang benar
const String _strapiBaseUrl = "http://192.168.1.11:1337";

// Model Student
class Student {
  final int id;
  final String nama;
  final String? fotoUrl;

  Student({required this.id, required this.nama, this.fotoUrl});

  factory Student.fromJson(Map<String, dynamic> json) {
    String? finalFotoUrl;
    if (json['foto_profil'] != null && json['foto_profil']['url'] != null) {
      String urlPath = json['foto_profil']['url'];
      if (urlPath.startsWith('http')) {
        finalFotoUrl = urlPath.replaceAll(
          "http://localhost:1337",
          _strapiBaseUrl, // Menggunakan IP WiFi
        );
      } else {
        finalFotoUrl = _strapiBaseUrl + urlPath;
      }
    }
    return Student(
      id: json['id'],
      nama: json['nama_lengkap'] ?? 'Tanpa Nama',
      fotoUrl: finalFotoUrl,
    );
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

  Future<void> _fetchStudents() async {
    final String apiUrl =
        "$_strapiBaseUrl/api/students?populate=foto_profil"; // <-- Diperbarui

    try {
      final response = await http.get(Uri.parse(apiUrl));
      print("===== RESPON DATA MURID (Status: ${response.statusCode}) =====");
      print(response.body);

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

  Future<void> _onStudentSelected(Student student) async {
    print("Anak yang dipilih: ${student.nama} (ID: ${student.id})");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_student_id', student.id);
    await prefs.setString('active_student_name', student.nama);
    print("ID Murid ${student.id} berhasil disimpan ke sesi.");

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ContentListPage(studentId: student.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI Build tidak berubah) ...
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

    return GridView.builder(
      padding: const EdgeInsets.all(20.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
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
                (student.fotoUrl != null)
                    ? ClipOval(
                        child: Image.network(
                          student.fotoUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const CircularProgressIndicator();
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.face_retouching_natural,
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
