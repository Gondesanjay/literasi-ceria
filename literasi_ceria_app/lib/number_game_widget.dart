import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart'; // Pakai TTS
import 'package:lottie/lottie.dart';

// GANTI DENGAN IP WIFI-MU YANG BENAR
const String _strapiBaseUrl = "http://192.168.1.12:1337";

class NumberGameWidget extends StatefulWidget {
  final int contentId;
  final int studentId;

  const NumberGameWidget({
    super.key,
    required this.contentId,
    required this.studentId,
  });

  @override
  State<NumberGameWidget> createState() => _NumberGameWidgetState();
}

class _NumberGameWidgetState extends State<NumberGameWidget> {
  bool _isLoading = true;
  String _errorMessage = '';
  List _allQuizzes = [];

  int _currentIndex = 0;
  List _currentOptions = [];
  bool _isSuccess = false;
  int _attempts = 0;
  DateTime? _startTime;

  // Inisialisasi TTS
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchQuizData();
    _startTime = DateTime.now();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
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
    if (_startTime != null) {
      duration = DateTime.now().difference(_startTime!).inSeconds;
    }

    final String apiUrl = "$_strapiBaseUrl/api/activity-logs";
    try {
      await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {
            'student_id': widget.studentId.toString(),
            'content_id': widget.contentId.toString(),
            'durasi': duration,
            'module': 'Petualangan Angka', // <--- Modul Angka
            'action': action,
            'result': result,
            'detail': detail,
          },
        }),
      );
      print("✅ Log Angka Terkirim: $result");
    } catch (e) {
      print("❌ Gagal kirim log: $e");
    }
  }

  // --- FETCH DATA (Anti-Error 404) ---
  Future<void> _fetchQuizData() async {
    final String apiUrl =
        "$_strapiBaseUrl/api/contents?filters[id][\$eq]=${widget.contentId}&populate=quizzes";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List contentList = data['data'] ?? [];
        if (contentList.isEmpty) throw Exception("Konten tidak ditemukan.");

        final Map<String, dynamic> contentItem = contentList[0];
        final List items = contentItem['quizzes'] ?? [];

        if (items.isEmpty) throw Exception("Data angka kosong. Cek Strapi.");

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
      if (!mounted) return;
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

    // Ambil Angka dan Bersihkan Teks
    String rawNum = target['pertanyaan'] ?? '';
    String targetNum = rawNum.replaceAll('"', '').replaceAll("'", "").trim();

    // TTS Bicara: "Angka... Satu!"
    _speak("Angka... $targetNum");
  }

  void _handleSuccess() {
    setState(() {
      _isSuccess = true;
    });

    // Laporan Sukses
    String detailText =
        "Berhasil menghitung pada percobaan ke-${_attempts + 1}";
    _logActivity("Menghitung Objek", "Sukses", detailText);

    // Bicara Hore
    _speak("Pintar sekali!");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_touohxv0.json',
              height: 200,
              repeat: false,
            ),
            const SizedBox(height: 20),
            const Text(
              "PINTAR!",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
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
    String rawNum = currentQuiz['pertanyaan'] ?? '?';
    final String targetNum = rawNum
        .replaceAll('"', '')
        .replaceAll("'", "")
        .trim();

    return Column(
      children: [
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Pasangkan jumlah benda!",
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),

        // --- TARGET: KOTAK ANGKA (LINGKARAN ORANYE) ---
        Expanded(
          flex: 3,
          child: Center(
            child: DragTarget<String>(
              onAccept: (receivedNum) {
                String cleanReceived = receivedNum
                    .replaceAll('"', '')
                    .replaceAll("'", "")
                    .trim();
                if (cleanReceived == targetNum) {
                  _handleSuccess();
                } else {
                  setState(() {
                    _attempts++;
                  });
                  _logActivity(
                    "Menghitung Objek",
                    "Gagal",
                    "Salah pasang $cleanReceived ke $targetNum",
                  );
                  _speak("Coba hitung lagi.");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Coba hitung lagi ya!"),
                      backgroundColor: Colors.orange,
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                }
              },
              builder: (context, candidateData, rejectedData) {
                bool isHovering = candidateData.isNotEmpty;
                return Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: isHovering
                        ? Colors.orange.shade100
                        : Colors.orange.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isHovering ? Colors.green : Colors.orange,
                      width: 6,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: Center(
                    child: InkWell(
                      onTap: () =>
                          _speak("Angka $targetNum"), // Klik untuk dengar ulang
                      child: Text(
                        targetNum,
                        style: const TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // --- PILIHAN: GAMBAR BENDA (DRAGGABLE) ---
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
                String numVal = option['pertanyaan'] ?? '';

                Widget gameItem = Container(
                  width: 110,
                  height: 110,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: (imgUrl != null)
                      ? Image.network(imgUrl, fit: BoxFit.contain)
                      : const Icon(Icons.image, size: 40, color: Colors.grey),
                );

                return Draggable<String>(
                  data: numVal,
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
