import 'dart:async';

import 'package:flutter/material.dart';

class BreathingAnimationWidget extends StatefulWidget {
  const BreathingAnimationWidget({
    super.key,
    required this.textColor,
  });

  final Color textColor;

  @override
  State<BreathingAnimationWidget> createState() =>
      _BreathingAnimationWidgetState();
}

class _BreathingAnimationWidgetState
    extends State<BreathingAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _timer;

  bool isInhaling = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 50,
      end: 150,
    ).animate(_controller);

    _timer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (!mounted) return;

        setState(() {
          isInhaling = !isInhaling;
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final textColor = widget.textColor;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                isInhaling ? 'Inhale...' : 'Exhale...',
                key: ValueKey(isInhaling),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: _animation.value,
                height: _animation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}