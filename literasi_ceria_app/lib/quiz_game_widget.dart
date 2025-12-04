import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart'; // <-- PAKAI TTS
import 'package:lottie/lottie.dart';

// GANTI DENGAN IP WIFI-MU
const String _strapiBaseUrl = "http://192.168.1.12:1337";

class QuizGameWidget extends StatefulWidget {
  final int contentId;
  final int studentId;

  const QuizGameWidget({
    super.key,
    required this.contentId,
    required this.studentId,
  });

  @override
  State<QuizGameWidget> createState() => _QuizGameWidgetState();
}

class _QuizGameWidgetState extends State<QuizGameWidget> {
  bool _isLoading = true;
  String _errorMessage = '';
  List _allQuizzes = [];

  int _currentIndex = 0;
  List _currentOptions = [];
  bool _isSuccess = false;
  int _attempts = 0;
  DateTime? _startTime;

  // === INI TTS ENGINE KITA ===
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _setupTts(); // Siapkan suara
    _fetchQuizData();
    _startTime = DateTime.now();
  }

  // Konfigurasi Bahasa (Indonesia)
  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("id-ID"); // Set Bahasa Indonesia
    await _flutterTts.setSpeechRate(0.5); // Kecepatan sedang
    await _flutterTts.setPitch(1.0); // Nada normal
  }

  // Fungsi Bicara
  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      print("🗣️ Mengucapkan: $text");
      await _flutterTts.speak(text);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  // --- LAPORAN (Tanpa Bintang) ---
  Future<void> _logActivity(String action, String result, String detail) async {
    int duration = 0;
    if (_startTime != null)
      duration = DateTime.now().difference(_startTime!).inSeconds;
    try {
      await http.post(
        Uri.parse("$_strapiBaseUrl/api/activity-logs"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {
            'student_id': widget.studentId.toString(),
            'content_id': widget.contentId.toString(),
            'durasi': duration,
            'module': 'Taman Huruf',
            'action': action,
            'result': result,
            'detail': detail,
          },
        }),
      );
    } catch (e) {
      print("Log error: $e");
    }
  }

  Future<void> _fetchQuizData() async {
    final String apiUrl =
        "$_strapiBaseUrl/api/contents?filters[id][\$eq]=${widget.contentId}&populate=quizzes";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List contentList = data['data'] ?? [];
        if (contentList.isEmpty) throw Exception("Konten tidak ditemukan.");
        final List items = contentList[0]['quizzes'] ?? [];
        if (items.isEmpty) throw Exception("Data kuis kosong.");

        items.shuffle();
        if (!mounted) return;
        setState(() {
          _allQuizzes = items;
          _isLoading = false;
        });
        _prepareLevel();
      } else {
        throw Exception('Gagal ambil data: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
    }
  }

  void _prepareLevel() {
    var target = _allQuizzes[_currentIndex];
    List options = [target];
    if (_allQuizzes.length > 1) {
      var others = List.from(_allQuizzes)..remove(target);
      others.shuffle();
      options.addAll(others.take(2));
    }
    options.shuffle();

    setState(() {
      _isSuccess = false;
      _currentOptions = options;
      _attempts = 0;
    });

    // === BICARA ===
    // Bersihkan teks agar enak didengar
    String targetLetter = target['pertanyaan'] ?? '';
    targetLetter = targetLetter.replaceAll('"', '').replaceAll("'", "").trim();

    // Aplikasi akan bicara: "Huruf... A!"
    _speak("Huruf... $targetLetter");
  }

  void _handleSuccess() {
    setState(() {
      _isSuccess = true;
    });
    _logActivity("Menebak Huruf", "Sukses", "Percobaan ke-${_attempts + 1}");
    _speak("Hebat! Itu benar."); // Bicara saat menang

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_touohxv0.json',
              height: 150,
            ),
            const Text(
              "HEBAT!",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      Navigator.of(context).pop();
      if (_currentIndex < _allQuizzes.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _prepareLevel();
      } else {
        setState(() {
          _currentIndex = 0;
          _allQuizzes.shuffle();
        });
        _prepareLevel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty)
      return Center(child: Text("Error: $_errorMessage"));

    final currentQuiz = _allQuizzes[_currentIndex];
    String rawLetter = currentQuiz['pertanyaan'] ?? '?';
    final String targetLetter = rawLetter
        .replaceAll('"', '')
        .replaceAll("'", "")
        .trim();

    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          flex: 3,
          child: Center(
            child: DragTarget<String>(
              onAccept: (receivedLetter) {
                String cleanReceived = receivedLetter
                    .replaceAll('"', '')
                    .replaceAll("'", "")
                    .trim();
                if (cleanReceived == targetLetter) {
                  _handleSuccess();
                } else {
                  setState(() {
                    _attempts++;
                  });
                  _logActivity(
                    "Menebak Huruf",
                    "Gagal",
                    "Salah pilih $cleanReceived",
                  );
                  _speak("Coba lagi ya."); // Bicara saat salah
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Ups, coba lagi!"),
                      backgroundColor: Colors.orange,
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                }
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? Colors.green.shade100
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.blueAccent, width: 4),
                  ),
                  child: Center(
                    child: InkWell(
                      onTap: () =>
                          _speak(targetLetter), // Klik untuk dengar ulang
                      child: Text(
                        targetLetter,
                        style: const TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // ... (Bagian Pilihan Gambar di bawah SAMA PERSIS dengan sebelumnya) ...
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _currentOptions.map((option) {
                String? imgUrl;
                if (option['gambar_url'] != null) {
                  imgUrl = option['gambar_url'].replaceAll(
                    "http://localhost:1337",
                    _strapiBaseUrl,
                  );
                }
                String letter = option['pertanyaan'] ?? '';
                Widget gameItem = Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: (imgUrl != null)
                      ? Image.network(imgUrl, fit: BoxFit.contain)
                      : const Icon(Icons.image, size: 40, color: Colors.orange),
                );
                return Draggable<String>(
                  data: letter,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(opacity: 0.8, child: gameItem),
                  ),
                  childWhenDragging: Opacity(opacity: 0.3, child: gameItem),
                  child: gameItem,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
