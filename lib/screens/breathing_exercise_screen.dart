import 'dart:ui'; // Import for blur effect
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/breathing_animation_widget.dart';
import '../screens/breathing_streak_service.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  _BreathingExerciseScreenState createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> {
  final BreathingStreakService _streakService = BreathingStreakService();
  int streakCount = 0;
  int totalSessions = 0;
  String lastSessionDate = "No sessions yet";

  @override
  void initState() {
    super.initState();
    _fetchBreathingData();
  }

  Future<void> _fetchBreathingData() async {
    var data = await _streakService.getUserBreathingData();
    if (data != null) {
      setState(() {
        streakCount = data['streakCount'] ?? 0;
        totalSessions = data['totalSessions'] ?? 0;
        DateTime lastSession = (data['lastSessionDate'] as Timestamp).toDate();
        lastSessionDate = DateFormat('dd MMM yyyy').format(lastSession);
      });
    }
  }

  Future<void> _completeBreathingSession() async {
    await _streakService.updateBreathingSession();
    _fetchBreathingData(); // Refresh the UI after updating
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🔥 Background Image
          Image.asset(
            "assets/icon/meditation_bg.jpeg",
            fit: BoxFit.cover,
          ),

          // 🔹 Blur Effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 1),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // 🔹 Content on Top
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔥 Streak Info
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text("🔥 Streak: $streakCount days",
                        style:
                            const TextStyle(fontSize: 20, color: Colors.white)),
                    Text("📅 Last Session: $lastSessionDate",
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white)),
                    Text("🧘‍♂️ Total Sessions: $totalSessions",
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Breathing Animation
              const BreathingAnimationWidget(textColor: Colors.white),

              const SizedBox(height: 30),

              // ✅ Complete Session Button
              ElevatedButton(
                onPressed: _completeBreathingSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text("Complete Breathing Session",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
