import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_selection_page.dart';
import 'login_page.dart';
import 'content_list_page.dart';

class ChooserPage extends StatefulWidget {
  const ChooserPage({super.key});
  @override
  State<ChooserPage> createState() => _ChooserPageState();
}

class _ChooserPageState extends State<ChooserPage> {
  // Fungsi untuk cek sesi anak
  Future<void> _goToModeAnak() async {
    final prefs = await SharedPreferences.getInstance();
    final int? studentId = prefs.getInt('active_student_id');

    if (!mounted) return;

    if (studentId != null) {
      // JIKA ADA SESI ANAK: Langsung loncat ke Pojok Cerita
      print("Sesi anak ditemukan (ID: $studentId). Langsung ke Pojok Cerita.");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContentListPage(studentId: studentId),
        ),
      );
    } else {
      // JIKA TIDAK ADA SESI ANAK: Pergi ke Halaman Pemilihan Profil
      print("Sesi anak tidak ditemukan. Pergi ke Halaman Pilih Profil.");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StudentSelectionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Literasi Ceria',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 50),

              // Tombol "Mode Anak" (Pintar)
              ElevatedButton.icon(
                icon: const Icon(Icons.child_care, size: 30),
                label: const Text('Mode Anak'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _goToModeAnak, // Panggil fungsi cek sesi
              ),

              const SizedBox(height: 30),

              // Tombol "Mode Dewasa"
              ElevatedButton.icon(
                icon: const Icon(Icons.person, size: 30),
                label: const Text('Mode Dewasa'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
