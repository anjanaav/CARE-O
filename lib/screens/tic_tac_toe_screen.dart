import 'package:flutter/material.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  _TicTacToeScreenState createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  List<String> board = List.generate(9, (index) => '');
  String currentPlayer = 'X';
  String result = '';

  void _resetGame() {
    setState(() {
      board = List.generate(9, (index) => '');
      currentPlayer = 'X';
      result = '';
    });
  }

  void _makeMove(int index) {
    if (board[index] == '' && result == '') {
      setState(() {
        board[index] = currentPlayer;
        _checkWinner();
        currentPlayer = (currentPlayer == 'X') ? 'O' : 'X';
      });
    }
  }

  void _checkWinner() {
    List<List<int>> winningCombinations = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ];

    for (var combo in winningCombinations) {
      if (board[combo[0]] != '' &&
          board[combo[0]] == board[combo[1]] &&
          board[combo[1]] == board[combo[2]]) {
        setState(() {
          result = '${board[combo[0]]} Wins!';
        });
        return;
      }
    }

    if (!board.contains('')) {
      setState(() {
        result = 'It\'s a Draw!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tic-Tac-Toe')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _makeMove(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Center(
                      child: Text(
                        board[index],
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: board[index] == 'X'
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Text(
            result,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetGame,
            child: const Text('Restart Game'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
