import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/breathing_animation_widget.dart';
import 'breathing_streak_service.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> {
  final BreathingStreakService _streakService = BreathingStreakService();

  int streakCount = 0;
  int totalSessions = 0;
  String lastSessionDate = 'No sessions yet';
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _fetchBreathingData();
  }

  Future<void> _fetchBreathingData() async {
    try {
      final data = await _streakService.getUserBreathingData();

      if (!mounted || data == null) return;

      final rawDate = data['lastSessionDate'];

      String formattedDate = 'No sessions yet';

      if (rawDate is Timestamp) {
        formattedDate = DateFormat('dd MMM yyyy').format(rawDate.toDate());
      }

      setState(() {
        streakCount = data['streakCount'] ?? 0;
        totalSessions = data['totalSessions'] ?? 0;
        lastSessionDate = formattedDate;
      });
    } catch (e) {
      debugPrint('Error fetching breathing data: $e');
    }
  }

  Future<void> _completeBreathingSession() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      await _streakService.updateBreathingSession();
      await _fetchBreathingData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Breathing session completed!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save the breathing session.'),
        ),
      );

      debugPrint('Error completing breathing session: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/icon/meditation_bg.jpeg',
            fit: BoxFit.cover,
          ),

          // Theme-independent dark overlay keeps text readable
          // over the background image in both light and dark modes.
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 0,
              sigmaY: 1,
            ),
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Streak information
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              context,
                              icon: Icons.local_fire_department,
                              label: 'Streak',
                              value: '$streakCount days',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              context,
                              icon: Icons.calendar_today,
                              label: 'Last Session',
                              value: lastSessionDate,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              context,
                              icon: Icons.self_improvement,
                              label: 'Total Sessions',
                              value: '$totalSessions',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Breathing animation
                      const BreathingAnimationWidget(
                        textColor: Colors.white,
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isCompleting ? null : _completeBreathingSession,
                          icon: _isCompleting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            _isCompleting
                                ? 'Saving...'
                                : 'Complete Breathing Session',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            disabledBackgroundColor:
                                colorScheme.primary.withValues(alpha: 0.5),
                            disabledForegroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          color: colorScheme.secondary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}