import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart'; 

// GANTI DENGAN IP WIFI-MU YANG BENAR
const String _strapiBaseUrl = "http://192.168.1.11:1337"; 

class VideoPlayerWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  const VideoPlayerWidget({super.key, required this.item});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController; // <-- 2. Controller Chewie
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final String? rawVideoUrl = widget.item['video_url'];
      if (rawVideoUrl == null || rawVideoUrl.isEmpty) {
        throw Exception("Video tidak ditemukan di Strapi.");
      }
      
      // Perbaikan URL
      final String fullVideoUrl = rawVideoUrl.replaceAll(
        "http://localhost:1337", 
        _strapiBaseUrl
      );
      
      print("Memuat video: $fullVideoUrl");

      // 1. Siapkan Video Player dasar
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(fullVideoUrl));
      await _videoPlayerController.initialize();

      // 2. Siapkan Chewie (Tampilan UI Keren)
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: true,
        aspectRatio: _videoPlayerController.value.aspectRatio, // Ikuti rasio video asli
        
        // Kustomisasi agar ramah anak
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.orange, // Warna cerah
          handleColor: Colors.blue,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightGreen,
        ),
        placeholder: const Center(child: CircularProgressIndicator()),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage, 
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat video: $e";
      });
    }
  }

  @override
  void dispose() {
    // 3. Matikan player saat keluar agar tidak bocor memori
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Menyiapkan Bioskop..."), // Teks lebih ceria
        ],
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 10),
            Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    // 4. Tampilkan Chewie
    return Center(
      child: _chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(controller: _chewieController!)
          : const CircularProgressIndicator(),
    );
  }
}