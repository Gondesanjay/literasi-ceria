import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chooser_page.dart';
import 'dashboard_page.dart';
import 'parent_dashboard_page.dart';

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
    final String? token = prefs.getString('jwt_token');
    final String? peran = prefs.getString('user_peran');

    if (!mounted) return;

    if (token != null && token.isNotEmpty && peran != null) {
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChooserPage()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChooserPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
