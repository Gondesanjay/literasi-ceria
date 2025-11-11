import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import SEMUA halaman tujuan kita
import 'chooser_page.dart';
import 'dashboard_page.dart';
import 'parent_dashboard_page.dart'; // <-- Pastikan ini di-import

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();

    // Ambil token DAN peran
    final String? token = prefs.getString('jwt_token');
    final String? peran = prefs.getString(
      'user_peran',
    ); // <-- KITA BACA PERANNYA

    if (!mounted) return;

    if (token != null && token.isNotEmpty && peran != null) {
      // --- JIKA ADA TOKEN DAN PERAN ---
      if (peran == 'guru') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      } else if (peran == 'orang_tua') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ParentDashboardPage()),
        );
      } else {
        // Peran tidak diketahui
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChooserPage()),
        );
      }
    } else {
      // --- JIKA TIDAK ADA TOKEN (BELUM LOGIN) ---
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChooserPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan Splash Screen (sederhana, hanya loading)
    return const Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Literasi Ceria',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
