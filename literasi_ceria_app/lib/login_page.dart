import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dashboard_page.dart';
import 'parent_dashboard_page.dart';

// Menggunakan IP WiFi-mu yang benar
const String _strapiIP = "http://192.168.1.12:1337";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = '';
  bool _isLoading = false;

  final String _apiUrl = "$_strapiIP/api/auth/local"; // <-- Diperbarui

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });
    final String email = _emailController.text;
    final String password = _passwordController.text;
    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'identifier': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      print("===== RESPON LOGIN (Status: ${response.statusCode}) =====");
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['jwt'];
        final int userId = data['user']['id'];
        final String peran = data['user']['peran'] ?? 'unknown';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setInt('user_id', userId);
        await prefs.setString('user_peran', peran);
        if (!mounted) return;
        if (peran == 'guru') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        } else if (peran == 'orang_tua') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ParentDashboardPage(),
            ),
          );
        } else {
          setState(() {
            _isLoading = false;
            _message = 'Error: Peran Anda tidak dikenali.';
          });
        }
      } else {
        final data = jsonDecode(response.body);
        final String errorMessage =
            data['error']?['message'] ?? 'Login gagal, cek data Anda.';
        setState(() {
          _isLoading = false;
          _message = errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error: $e. Pastikan Strapi berjalan.';
      });
      print(_message);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI Build tidak berubah) ...
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Mode Dewasa'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Selamat Datang, Guru/Orang Tua',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 20),
                Text(
                  _message,
                  style: TextStyle(
                    color: _message.contains('Berhasil')
                        ? Colors.green
                        : Colors.red,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
