import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimonSaysScreen extends StatefulWidget {
  const SimonSaysScreen({super.key});

  @override
  State<SimonSaysScreen> createState() => _SimonSaysScreenState();
}

class _SimonSaysScreenState extends State<SimonSaysScreen> {
  final List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.amber,
  ];

  final List<IconData> icons = [
    Icons.star,
    Icons.favorite,
    Icons.flash_on,
    Icons.music_note,
  ];

  List<int> sequence = [];
  List<int> playerInput = [];

  bool isPlayerTurn = false;
  int score = 0;
  int highScore = 0;
  int currentIndex = -1;
  bool isAnimating = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startNewGame();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
  }

  void _startNewGame() {
    setState(() {
      sequence.clear();
      playerInput.clear();
      score = 0;
    });

    _addNewStep();
  }

  void _addNewStep() {
    setState(() {
      isPlayerTurn = false;
      sequence.add(Random().nextInt(4));
    });

    _playSequence();
  }

  Future<void> _playSequence() async {
    if (!mounted) return;

    setState(() => isAnimating = true);

    for (final index in sequence) {
      if (!mounted) return;

      setState(() => currentIndex = index);

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;

      setState(() => currentIndex = -1);

      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;

    setState(() {
      isAnimating = false;
      isPlayerTurn = true;
    });
  }

  void _handlePlayerTap(int index) {
    if (!isPlayerTurn || isAnimating) return;

    setState(() => currentIndex = index);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() => currentIndex = -1);
    });

    playerInput.add(index);

    final currentInputIndex = playerInput.length - 1;

    if (playerInput[currentInputIndex] != sequence[currentInputIndex]) {
      _showGameOverDialog();
      return;
    }

    if (playerInput.length == sequence.length) {
      setState(() {
        score++;

        if (score > highScore) {
          highScore = score;
          _saveHighScore();
        }
      });

      playerInput.clear();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _addNewStep();
        }
      });
    }
  }

  void _showGameOverDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text('Game Over'),
          content: Text('Your final score: $score'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _startNewGame();
              },
              child: Text(
                'Restart',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInstructionsDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text('How to Play'),
          content: const Text(
            '1. Watch the sequence of lights carefully.\n'
            '2. Repeat the sequence by tapping the colored tiles in order.\n'
            '3. If you make a mistake, the game is over.\n'
            '4. Each correct round increases your score.\n'
            '5. Try to beat your high score!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Got it!',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Game'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How to play',
            onPressed: _showInstructionsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Score: $score',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'High Score: $highScore',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isPlayerTurn
                      ? 'Your turn!'
                      : 'Watch the sequence...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final bool isActive = currentIndex == index;

                      return Semantics(
                        button: true,
                        label: 'Memory game tile ${index + 1}',
                        child: GestureDetector(
                          onTap: () => _handlePlayerTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colors[index].withValues(alpha: 0.65)
                                  : colors[index],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 2,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.35),
                                        blurRadius: 20,
                                        spreadRadius: 3,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: colorScheme.shadow
                                            .withValues(alpha: 0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: AnimatedScale(
                                scale: isActive ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  icons[index],
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}