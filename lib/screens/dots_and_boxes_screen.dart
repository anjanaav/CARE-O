import 'package:flutter/material.dart';

class DotsAndBoxesScreen extends StatefulWidget {
  const DotsAndBoxesScreen({super.key});

  @override
  State<DotsAndBoxesScreen> createState() =>
      _DotsAndBoxesScreenState();
}

class _DotsAndBoxesScreenState extends State<DotsAndBoxesScreen> {
  final int gridSize = 3;

  late List<List<bool>> horizontalLines;
  late List<List<bool>> verticalLines;
  late List<List<int>> boxes;

  int currentPlayer = 1;
  int player1Score = 0;
  int player2Score = 0;

  @override
  void initState() {
    super.initState();
    _initializeGrid();
  }

  void _initializeGrid() {
    horizontalLines = List.generate(
      gridSize + 1,
      (_) => List.filled(gridSize, false),
    );

    verticalLines = List.generate(
      gridSize,
      (_) => List.filled(gridSize + 1, false),
    );

    boxes = List.generate(
      gridSize,
      (_) => List.filled(gridSize, 0),
    );
  }

  void _resetGame() {
    setState(() {
      currentPlayer = 1;
      player1Score = 0;
      player2Score = 0;
      _initializeGrid();
    });
  }

  void _handleTap(
    int row,
    int col,
    bool isHorizontal,
  ) {
    if (isHorizontal) {
      if (row < 0 ||
          row >= horizontalLines.length ||
          col < 0 ||
          col >= gridSize ||
          horizontalLines[row][col]) {
        return;
      }

      setState(() {
        horizontalLines[row][col] = true;

        final completed = _checkAndMarkBoxes();

        if (!completed) {
          _switchPlayer();
        }
      });
    } else {
      if (row < 0 ||
          row >= gridSize ||
          col < 0 ||
          col >= verticalLines[row].length ||
          verticalLines[row][col]) {
        return;
      }

      setState(() {
        verticalLines[row][col] = true;

        final completed = _checkAndMarkBoxes();

        if (!completed) {
          _switchPlayer();
        }
      });
    }
  }

  void _switchPlayer() {
    currentPlayer = currentPlayer == 1 ? 2 : 1;
  }

  bool _checkAndMarkBoxes() {
    bool boxCompleted = false;

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (boxes[r][c] != 0) continue;

        final completed = horizontalLines[r][c] &&
            horizontalLines[r + 1][c] &&
            verticalLines[r][c] &&
            verticalLines[r][c + 1];

        if (completed) {
          boxes[r][c] = currentPlayer;

          if (currentPlayer == 1) {
            player1Score++;
          } else {
            player2Score++;
          }

          boxCompleted = true;
        }
      }
    }

    return boxCompleted;
  }

  bool get _gameFinished =>
      player1Score + player2Score == gridSize * gridSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dots and Boxes'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Restart game',
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
        ],
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildScore(
                            context,
                            player: 1,
                            score: player1Score,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: colorScheme.outlineVariant,
                          ),
                          _buildScore(
                            context,
                            player: 2,
                            score: player2Score,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    _gameFinished
                        ? 'Game Complete!'
                        : 'Player $currentPlayer\'s Turn',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: _buildGameGrid(context),
                  ),

                  const SizedBox(height: 24),

                  if (_gameFinished)
                    FilledButton.icon(
                      onPressed: _resetGame,
                      icon: const Icon(Icons.replay),
                      label: const Text('Play Again'),
                    )
                  else
                    Text(
                      'Tap between dots to draw a line',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScore(
    BuildContext context, {
    required int player,
    required int score,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final color = player == 1
        ? colorScheme.primary
        : colorScheme.secondary;

    return Column(
      children: [
        Text(
          'Player $player',
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGameGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 340.0;

        final size = availableWidth.clamp(260.0, 360.0);

        return Semantics(
          label: 'Dots and Boxes game board',
          child: SizedBox(
            width: size,
            height: size,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                _handleGridTap(
                  details.localPosition,
                  size,
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  painter: DotsAndBoxesPainter(
                    horizontalLines: horizontalLines,
                    verticalLines: verticalLines,
                    boxes: boxes,
                    primaryColor: colorScheme.primary,
                    secondaryColor: colorScheme.secondary,
                    dotColor: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleGridTap(
    Offset position,
    double boardSize,
  ) {
    final cellSize = boardSize / gridSize;

    final x = position.dx;
    final y = position.dy;

    if (x < 0 ||
        y < 0 ||
        x > boardSize ||
        y > boardSize) {
      return;
    }

    // Find nearest grid intersection.
    final nearestCol = (x / cellSize).round();
    final nearestRow = (y / cellSize).round();

    final distanceX =
        (x - nearestCol * cellSize).abs();

    final distanceY =
        (y - nearestRow * cellSize).abs();

    const tapTolerance = 35.0;

    // Horizontal line.
    if (distanceY < tapTolerance &&
        nearestRow >= 0 &&
        nearestRow <= gridSize) {
      final col =
          (x / cellSize).floor().clamp(0, gridSize - 1);

      _handleTap(
        nearestRow,
        col,
        true,
      );

      return;
    }

    // Vertical line.
    if (distanceX < tapTolerance &&
        nearestCol >= 0 &&
        nearestCol <= gridSize) {
      final row =
          (y / cellSize).floor().clamp(0, gridSize - 1);

      _handleTap(
        row,
        nearestCol,
        false,
      );
    }
  }
}

class DotsAndBoxesPainter extends CustomPainter {
  final List<List<bool>> horizontalLines;
  final List<List<bool>> verticalLines;
  final List<List<int>> boxes;

  final Color primaryColor;
  final Color secondaryColor;
  final Color dotColor;

  DotsAndBoxesPainter({
    required this.horizontalLines,
    required this.verticalLines,
    required this.boxes,
    required this.primaryColor,
    required this.secondaryColor,
    required this.dotColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    const gridSize = 3;

    final cellSize = size.width / gridSize;

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final player1LinePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final player2LinePaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final player1BoxPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final player2BoxPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    // Boxes first so lines/dots stay visible.
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (boxes[r][c] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              c * cellSize,
              r * cellSize,
              cellSize,
              cellSize,
            ),
            player1BoxPaint,
          );
        } else if (boxes[r][c] == 2) {
          canvas.drawRect(
            Rect.fromLTWH(
              c * cellSize,
              r * cellSize,
              cellSize,
              cellSize,
            ),
            player2BoxPaint,
          );
        }
      }
    }

    // Horizontal lines.
    for (int r = 0; r <= gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (horizontalLines[r][c]) {
          canvas.drawLine(
            Offset(c * cellSize, r * cellSize),
            Offset(
              (c + 1) * cellSize,
              r * cellSize,
            ),
            player1LinePaint,
          );
        }
      }
    }

    // Vertical lines.
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c <= gridSize; c++) {
        if (verticalLines[r][c]) {
          canvas.drawLine(
            Offset(c * cellSize, r * cellSize),
            Offset(
              c * cellSize,
              (r + 1) * cellSize,
            ),
            player2LinePaint,
          );
        }
      }
    }

    // Dots.
    for (int r = 0; r <= gridSize; r++) {
      for (int c = 0; c <= gridSize; c++) {
        canvas.drawCircle(
          Offset(
            c * cellSize,
            r * cellSize,
          ),
          5,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant DotsAndBoxesPainter oldDelegate,
  ) {
    return true;
  }
}