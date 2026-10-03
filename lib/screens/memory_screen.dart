import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimonSaysScreen extends StatefulWidget {
  const SimonSaysScreen({super.key});

  @override
  _SimonSaysScreenState createState() => _SimonSaysScreenState();
}

class _SimonSaysScreenState extends State<SimonSaysScreen> {
  final List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
  }

  void _startNewGame() {
    setState(() {
      sequence.clear();
      playerInput.clear();
      score = 0;
      _addNewStep();
    });
  }

  void _addNewStep() {
    setState(() {
      isPlayerTurn = false;
      sequence.add(Random().nextInt(4));
      _playSequence();
    });
  }

  Future<void> _playSequence() async {
    setState(() => isAnimating = true);
    for (int i = 0; i < sequence.length; i++) {
      setState(() => currentIndex = sequence[i]);
      await Future.delayed(Duration(milliseconds: 600));
      setState(() => currentIndex = -1);
      await Future.delayed(Duration(milliseconds: 300));
    }
    setState(() {
      isAnimating = false;
      isPlayerTurn = true;
    });
  }

  void _handlePlayerTap(int index) {
    if (!isPlayerTurn || isAnimating) return;
    setState(() => currentIndex = index);
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() => currentIndex = -1);
    });

    playerInput.add(index);
    if (playerInput[playerInput.length - 1] !=
        sequence[playerInput.length - 1]) {
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
      Future.delayed(Duration(seconds: 1), _addNewStep);
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Game Over"),
        content: Text("Your final score: $score"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: Text("Restart"),
          ),
        ],
      ),
    );
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("How to Play"),
        content: Text(
          "1. Watch the sequence of lights carefully.\n"
          "2. Repeat the sequence by tapping the colored tiles in order.\n"
          "3. If you make a mistake, the game is over.\n"
          "4. Each correct round increases your score.\n"
          "5. Try to beat your high score!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Got it!"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Game'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _showInstructionsDialog,
          ),
        ],
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Score: $score",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            "High Score: $highScore",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700]),
          ),
          SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _handlePlayerTap(index),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: currentIndex == index
                        ? colors[index].withOpacity(0.5)
                        : colors[index],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: currentIndex == index
                        ? [BoxShadow(color: Colors.white, blurRadius: 20)]
                        : [],
                  ),
                  child: Center(
                    child: Icon(
                      icons[index],
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
