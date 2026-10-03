import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class MeditationVideoScreen extends StatefulWidget {
  const MeditationVideoScreen({super.key});

  @override
  _MeditationVideoScreenState createState() => _MeditationVideoScreenState();
}

class _MeditationVideoScreenState extends State<MeditationVideoScreen> {
  final List<Map<String, String>> videos = [
    {
      "title": "Relaxing Meditation",
      "path": "assets/icon/meditation1.mp4",
    },
    {
      "title": "Mindfulness Meditation",
      "path": "assets/icon/meditation2.mp4",
    },
  ];

  void _playVideo(String videoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoPath: videoPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _playVideo(videos[index]["path"]!),
            child: Container(
              height: 150,
              margin: const EdgeInsets.only(bottom: 35),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade100, const Color.fromARGB(255, 199, 195, 195)
                    // const Color.fromARGB(255, 124, 206, 196).withOpacity(0.95),
                    //Colors.orangeAccent.withOpacity(0.9),
                    // const Color.fromARGB(255, 214, 215, 168).withOpacity(0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 162, 162, 161)
                        .withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 3,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      videos[index]["title"]!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors
                            .black, // 🔥 Changed to black for better contrast
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.black, // 🔥 White play button for visibility
                    size: 50,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath);
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _controller,
          autoPlay: true,
          looping: false,
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Player"),
      ),
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: Chewie(controller: _chewieController!),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
