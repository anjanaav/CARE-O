import 'package:flutter/material.dart';
import 'dart:async';

class BreathingAnimationWidget extends StatefulWidget {
  const BreathingAnimationWidget({super.key, required Color textColor});

  @override
  _BreathingAnimationWidgetState createState() =>
      _BreathingAnimationWidgetState();
}

class _BreathingAnimationWidgetState extends State<BreathingAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isInhaling = true;
  Timer? _timer; // Store the timer

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 50, end: 150).animate(_controller)
      ..addListener(() {
        if (mounted) {
          setState(() {}); // Check mounted before calling setState
        }
      });

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          isInhaling = !isInhaling;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer
        ?.cancel(); // Cancel the timer to prevent calling setState() after dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isInhaling ? "Inhale..." : "Exhale...",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isInhaling
                ? Color.fromARGB(255, 212, 244, 98) // Orange shade for "Inhale"
                : Color.fromARGB(255, 127, 209, 239), // Blue shade for "Exhale"
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: _animation.value,
            height: _animation.value,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromARGB(255, 255, 211, 182),
            ),
          ),
        ),
      ],
    );
  }
}
