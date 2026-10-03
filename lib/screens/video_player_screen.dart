import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/widgets/state_views.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({
    super.key,
    required this.videoPath,
  });

  @override
  State<VideoPlayerScreen> createState() =>
      _VideoPlayerScreenState();
}

class _VideoPlayerScreenState
    extends State<VideoPlayerScreen> {
  late final VideoPlayerController _controller;

  ChewieController? _chewieController;

  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(
      widget.videoPath,
    );

    _initializeVideoPlayerFuture =
        _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();

      if (!mounted) return;

      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _controller,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          showControls: true,
        );
      });
    } catch (e) {
      debugPrint(
        'Video Player Initialization Error: $e',
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    // Chewie should be disposed before its underlying
    // video controller.
    _chewieController?.dispose();
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
      ),
      body: FutureBuilder<void>(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState !=
                  ConnectionState.done &&
              !snapshot.hasError) {
            return const LoadingState(
              message: 'Loading video…',
            );
          }

          if (snapshot.hasError ||
              _chewieController == null) {
            return const AppErrorState(
              message:
                  "We couldn't play this video. Please try again later.",
            );
          }

          return Center(
            child: AspectRatio(
              aspectRatio:
                  _controller.value.aspectRatio,
              child: Chewie(
                controller: _chewieController!,
              ),
            ),
          );
        },
      ),
    );
  }
}