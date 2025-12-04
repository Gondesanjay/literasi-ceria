import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'content_list_page.dart';

// GANTI DENGAN IP WIFI-MU YANG BENAR
const String _strapiBaseUrl = "http://192.168.1.12:1337";

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
          _strapiBaseUrl,
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
    final String apiUrl = "$_strapiBaseUrl/api/students?populate=foto_profil";
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
          _errorMessage = 'Gagal: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _onStudentSelected(Student student) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_student_id', student.id);
    await prefs.setString('active_student_name', student.nama);
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage));
    if (_daftarMurid.isEmpty)
      return const Center(child: Text('Tidak ada profil.'));

    // === FITUR ADAPTIF (TABLET SUPPORT) ===
    return LayoutBuilder(
      builder: (context, constraints) {
        int gridCount = 2;
        if (constraints.maxWidth > 600) gridCount = 3;
        if (constraints.maxWidth > 900) gridCount = 4;

        return GridView.builder(
          padding: const EdgeInsets.all(20.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridCount,
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
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.error),
                            ),
                          )
                        : const Icon(
                            Icons.face,
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
      },
    );
  }
}
