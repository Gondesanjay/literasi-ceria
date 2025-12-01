import 'package:flutter/material.dart';
import 'splash_page.dart'; // Pintu masuk utama (Logic Pengecekan Sesi)

void main() {
  // WAJIB: Memastikan "jembatan" Flutter ke native sudah siap
  // sebelum menjalankan kode lain (seperti SharedPreferences).
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Literasi Ceria',
      // Menggunakan Material 3 agar tampilan lebih modern
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // Opsional: Kamu bisa atur font default di sini jika mau
      ),
      home: const SplashPage(), // Selalu mulai dari Splash Screen
      debugShowCheckedModeBanner:
          false, // Menghilangkan pita "DEBUG" di pojok kanan atas
    );
  }
}
