import 'package:flutter/material.dart';

import 'student_selection_page.dart'; // <-- Arahkan ke file yang benar
import 'login_page.dart'; // Halaman Login (Mode Dewasa)

class ChooserPage extends StatelessWidget {
  const ChooserPage({super.key});

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

              // Tombol 1: Mode Anak (Arahnya sudah benar)
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
                onPressed: () {
                  // Pindah ke Halaman Pemilihan Profil
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentSelectionPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Tombol 2: Mode Dewasa (Ini sudah benar)
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
