import 'package:flutter/material.dart';
import '../widgets/yoga_pose_card.dart';
import 'video_player_screen.dart';

class YogaScreen extends StatelessWidget {
  final List<Map<String, String>> yogaPoses = [
    {
      "name": "Mountain Pose",
      "image": "assets/icon/mountain_pose.png",
      "video": "assets/icon/mountain_pose.mp4"
    },
    {
      "name": "Downward Dog",
      "image": "assets/icon/downward_dog.png",
      "video": "assets/icon/downward_dog.mp4"
    },
    {
      "name": "Tadasana",
      "image": "assets/icon/Tadasana.png",
      "video": "assets/icon/Tadasana.mp4"
    },
    {
      "name": "Tree Pose",
      "image": "assets/icon/Tree.png",
      "video": "assets/icon/Tree.mp4"
    },
    {
      "name": "Child Pose",
      "image": "assets/icon/child pose.png",
      "video": "assets/icon/child pose.mp4"
    },
  ];

  YogaScreen({super.key});

  void _playVideo(BuildContext context, String videoPath) {
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: yogaPoses.length,
          itemBuilder: (context, index) {
            return YogaPoseCard(
              name: yogaPoses[index]["name"]!,
              imagePath: yogaPoses[index]["image"]!,
              videoPath: yogaPoses[index]["video"]!,
              onTap: () => _playVideo(context, yogaPoses[index]["video"]!),
            );
          },
        ),
      ),
    );
  }
}
