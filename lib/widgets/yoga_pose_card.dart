import 'package:flutter/material.dart';
import '../widgets/video_player_widget.dart';

class YogaPoseCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final String videoPath;

  const YogaPoseCard({
    super.key,
    required this.name,
    required this.imagePath,
    required this.videoPath,
    required void Function() onTap,
  });

  void _playVideo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerWidget(videoPath: videoPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading:
            Image.asset(imagePath, width: 50, height: 50, fit: BoxFit.cover),
        title: Text(name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.play_circle_fill,
            color: Colors.orangeAccent, size: 36),
        onTap: () => _playVideo(context),
      ),
    );
  }
}
