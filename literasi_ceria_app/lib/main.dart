import 'package:flutter/material.dart';
import 'splash_page.dart'; // Pintu masuk utama kita

void main() {
  // Memastikan "jembatan" Flutter ke native sudah siap
  // Ini memperbaiki masalah "Layar Gelap" (Black Screen)
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Literasi Ceria',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
