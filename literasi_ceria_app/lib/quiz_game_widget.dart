import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';

// GANTI DENGAN IP WIFI-MU YANG BENAR
const String _strapiBaseUrl = "http://192.168.1.11:1337";

class QuizGameWidget extends StatefulWidget {
  final int contentId;
  final int studentId; // ID murid untuk laporan

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

  // State Game
  int _currentIndex = 0;
  List _currentOptions = [];
  bool _isSuccess = false;

  // Variabel Laporan
  int _attempts = 0;
  DateTime? _startTime;

  // Inisialisasi Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
    _startTime = DateTime.now(); // Mulai stopwatch
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- FUNGSI LAPORAN CANGGIH (Ke Strapi) ---
  Future<void> _logActivity(String action, String result, String detail) async {
    // Hitung durasi bermain saat ini
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
            'module': 'Taman Huruf', // Nama Modul
            'action': action, // Apa yang dilakukan
            'result': result, // Hasil (Sukses/Gagal)
            'detail': detail, // Detail (Percobaan ke-X)
          },
        }),
      );
      print("✅ Log Laporan Canggih Terkirim: $action - $result");
    } catch (e) {
      print("❌ Gagal kirim log: $e");
    }
  }

  // --- AMBIL DATA DARI STRAPI ---
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

        if (items.isEmpty) throw Exception("Data kuis kosong.");

        // Acak soal agar seru
        items.shuffle();

        if (!mounted) return;
        setState(() {
          _allQuizzes = items;
          _isLoading = false;
        });

        _prepareLevel(); // Siapkan level pertama
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

  // --- PERSIAPAN LEVEL ---
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
      _attempts = 0; // Reset percobaan
    });

    // Putar suara huruf target
    String targetLetter = target['pertanyaan'] ?? '';
    _playLocalSound(targetLetter);
  }

  // --- AUDIO LOKAL ---
  Future<void> _playLocalSound(String label) async {
    // Bersihkan label (misal '"A"' -> 'a')
    String cleanLabel = label
        .replaceAll('"', '')
        .replaceAll("'", "")
        .trim()
        .toLowerCase();
    String fileName = "audio/$cleanLabel.mp3";

    print("🎵 Memutar aset: assets/$fileName");

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(fileName));
    } catch (e) {
      print("❌ Gagal memutar audio lokal: $e");
    }
  }

  // --- SAAT MENANG ---
  void _handleSuccess() {
    setState(() {
      _isSuccess = true;
    });

    // Kirim Laporan SUKSES (Hijau)
    String detailText = "Berhasil pada percobaan ke-${_attempts + 1}";
    _logActivity("Menebak Huruf", "Sukses", detailText);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_touohxv0.json',
              height: 200,
              repeat: false,
              errorBuilder: (ctx, err, stack) =>
                  const Icon(Icons.star, size: 100, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "HEBAT!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 2500), () {
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

    // Bersihkan label huruf target
    String rawLetter = currentQuiz['pertanyaan'] ?? '?';
    final String targetLetter = rawLetter
        .replaceAll('"', '')
        .replaceAll("'", "")
        .trim();

    return Column(
      children: [
        const SizedBox(height: 20),

        // AREA TARGET (HURUF)
        Expanded(
          flex: 3,
          child: Center(
            child: DragTarget<String>(
              onAccept: (receivedLetter) {
                // Bersihkan huruf yang diterima sebelum dicek
                String cleanReceived = receivedLetter
                    .replaceAll('"', '')
                    .replaceAll("'", "")
                    .trim();

                if (cleanReceived == targetLetter) {
                  _handleSuccess();
                } else {
                  // === JIKA SALAH ===
                  setState(() {
                    _attempts++;
                  }); // Tambah counter salah

                  // KIRIM LAPORAN GAGAL (MERAH) KE STRAPI
                  _logActivity(
                    "Menebak Huruf", // Action
                    "Gagal", // Result (Merah di Detail)
                    "Salah menebak. Memilih $cleanReceived tapi targetnya $targetLetter", // Detail
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Ups, coba gambar yang lain!"),
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
                        ? Colors.green.shade100
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isHovering ? Colors.green : Colors.blueAccent,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        targetLetter,
                        style: const TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const Text(
                        "Taruh gambar di sini!",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // AREA PILIHAN (GAMBAR)
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
