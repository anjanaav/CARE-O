import '../core/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

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
      if (mounted) {
        // ✅ Prevents setting state after widget is disposed
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _controller,
            autoPlay: true,
            looping: false,
          );
        });
      }
    }).catchError((error) {
      debugPrint("Video Player Initialization Error: $error");
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
          if (snapshot.hasError || _chewieController == null) {
            if (snapshot.connectionState != ConnectionState.done &&
                !snapshot.hasError) {
              return const LoadingState(message: 'Loading video…');
            }
            return const AppErrorState(
              message: "We couldn't play this video. Please try again later.",
            );
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(child: Chewie(controller: _chewieController!));
          }
          return const LoadingState(message: 'Loading video…');
        },
      ),
    );
  }
}
