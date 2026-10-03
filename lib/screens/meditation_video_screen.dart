import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class MeditationVideoScreen extends StatefulWidget {
  const MeditationVideoScreen({super.key});

  @override
  State<MeditationVideoScreen> createState() =>
      _MeditationVideoScreenState();
}

class _MeditationVideoScreenState extends State<MeditationVideoScreen> {
  final List<Map<String, String>> videos = [
    {
      'title': 'Relaxing Meditation',
      'path': 'assets/icon/meditation1.mp4',
    },
    {
      'title': 'Mindfulness Meditation',
      'path': 'assets/icon/meditation2.mp4',
    },
  ];

  void _playVideo(String videoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoPath: videoPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Color cardStartColor = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.12),
      colorScheme.surface,
    );

    final Color cardEndColor = Color.alphaBlend(
      colorScheme.secondary.withValues(alpha: 0.10),
      colorScheme.surface,
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final String title = videos[index]['title']!;
        final String path = videos[index]['path']!;

        return GestureDetector(
          onTap: () => _playVideo(path),
          child: Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  cardStartColor,
                  cardEndColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(
                    alpha: 0.12,
                  ),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.play_circle_fill,
                  color: colorScheme.primary,
                  size: 50,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(
      widget.videoPath,
    );

    _initializeVideoPlayerFuture = _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await _controller.initialize();

    if (!mounted) {
      return;
    }

    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: true,
        looping: false,
      );
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Video Player',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_chewieController == null) {
              return Center(
                child: Text(
                  'Unable to load video.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            return Center(
              child: Chewie(
                controller: _chewieController!,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load video.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            );
          }

          return Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}