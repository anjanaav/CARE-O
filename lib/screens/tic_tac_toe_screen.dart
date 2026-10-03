import 'package:flutter/material.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() =>
      _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  List<String> board = List.filled(9, '');

  String currentPlayer = 'X';
  String result = '';

  static const List<List<int>> winningCombinations = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      currentPlayer = 'X';
      result = '';
    });
  }

  void _makeMove(int index) {
    if (board[index].isNotEmpty || result.isNotEmpty) {
      return;
    }

    final player = currentPlayer;

    setState(() {
      board[index] = player;

      if (_hasWinner(player)) {
        result = '$player Wins!';
      } else if (!board.contains('')) {
        result = "It's a Draw!";
      } else {
        currentPlayer = player == 'X' ? 'O' : 'X';
      }
    });
  }

  bool _hasWinner(String player) {
    for (final combination in winningCombinations) {
      if (board[combination[0]] == player &&
          board[combination[1]] == player &&
          board[combination[2]] == player) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic-Tac-Toe'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                children: [
                  Text(
                    result.isEmpty
                        ? 'Player $currentPlayer\'s Turn'
                        : result,
                    textAlign: TextAlign.center,
                    style:
                        theme.textTheme.headlineSmall?.copyWith(
                      color: result.isNotEmpty
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final size =
                          constraints.maxWidth.clamp(
                        260.0,
                        420.0,
                      );

                      return SizedBox(
                        width: size,
                        height: size,
                        child: GridView.builder(
                          physics:
                              const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: 9,
                          itemBuilder: (context, index) {
                            final value = board[index];

                            final valueColor = value == 'X'
                                ? colorScheme.error
                                : colorScheme.primary;

                            return Semantics(
                              button: true,
                              label: value.isEmpty
                                  ? 'Empty cell ${index + 1}'
                                  : 'Cell ${index + 1}, $value',
                              child: Material(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius:
                                    BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  onTap: () =>
                                      _makeMove(index),
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(
                                        milliseconds: 150,
                                      ),
                                      child: Text(
                                        value,
                                        key: ValueKey(value),
                                        style: TextStyle(
                                          fontSize: 42,
                                          fontWeight:
                                              FontWeight.bold,
                                          color: valueColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  FilledButton.icon(
                    onPressed: _resetGame,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Restart Game'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}