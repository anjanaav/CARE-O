import 'package:flutter/material.dart';

class DotsAndBoxesScreen extends StatefulWidget {
  const DotsAndBoxesScreen({super.key});

  @override
  _DotsAndBoxesScreenState createState() => _DotsAndBoxesScreenState();
}

class _DotsAndBoxesScreenState extends State<DotsAndBoxesScreen> {
  final int gridSize = 3; // Grid Size (3x3)
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
    horizontalLines =
        List.generate(gridSize + 1, (_) => List.filled(gridSize, false));
    verticalLines =
        List.generate(gridSize, (_) => List.filled(gridSize + 1, false));
    boxes = List.generate(gridSize, (_) => List.filled(gridSize, 0));
  }

  void _handleTap(int row, int col, bool isHorizontal) {
    if (row >= gridSize + 1 || col >= gridSize + 1) return;

    setState(() {
      if (isHorizontal) {
        if (!horizontalLines[row][col]) {
          horizontalLines[row][col] = true;
        } else {
          return;
        }
      } else {
        if (!verticalLines[row][col]) {
          verticalLines[row][col] = true;
        } else {
          return;
        }
      }

      bool boxCompleted = _checkAndMarkBoxes();
      if (!boxCompleted) {
        currentPlayer = currentPlayer == 1 ? 2 : 1;
      }
    });
  }

  bool _checkAndMarkBoxes() {
    bool boxCompleted = false;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (r < gridSize &&
            c < gridSize &&
            boxes[r][c] == 0 &&
            horizontalLines[r][c] &&
            horizontalLines[r + 1][c] &&
            verticalLines[r][c] &&
            verticalLines[r][c + 1]) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dots and Boxes'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Player 1: $player1Score  |  Player 2: $player2Score",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Center(child: _buildGameGrid()),
          SizedBox(height: 20),
          Text(
            "Turn: Player $currentPlayer",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid() {
    return GestureDetector(
      onTapDown: (details) {
        RenderBox renderBox = context.findRenderObject() as RenderBox;
        Offset localPosition = renderBox.globalToLocal(details.globalPosition);
        _handleGridTap(localPosition);
      },
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: CustomPaint(
          painter: DotsAndBoxesPainter(horizontalLines, verticalLines, boxes),
        ),
      ),
    );
  }

  void _handleGridTap(Offset position) {
    double cellSize = 100.0;
    int row = (position.dy / cellSize).floor();
    int col = (position.dx / cellSize).floor();

    if (row >= gridSize + 1 || col >= gridSize + 1) return;

    double dx = position.dx % cellSize;
    double dy = position.dy % cellSize;

    if (dx < dy && dx + dy < cellSize) {
      _handleTap(row, col, true);
    } else if (dx > dy && dx + dy > cellSize) {
      _handleTap(row, col, true);
    } else {
      _handleTap(row, col, false);
    }
  }
}

class DotsAndBoxesPainter extends CustomPainter {
  final List<List<bool>> horizontalLines;
  final List<List<bool>> verticalLines;
  final List<List<int>> boxes;

  DotsAndBoxesPainter(this.horizontalLines, this.verticalLines, this.boxes);

  @override
  void paint(Canvas canvas, Size size) {
    double cellSize = size.width / 3;
    Paint dotPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 8;
    Paint linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4;
    Paint boxPaint1 = Paint()..color = Colors.blue.withOpacity(0.3);
    Paint boxPaint2 = Paint()..color = Colors.red.withOpacity(0.3);

    for (int r = 0; r <= 3; r++) {
      for (int c = 0; c <= 3; c++) {
        canvas.drawCircle(Offset(c * cellSize, r * cellSize), 5, dotPaint);
      }
    }

    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        if (horizontalLines[r][c]) {
          canvas.drawLine(
            Offset(c * cellSize, r * cellSize),
            Offset((c + 1) * cellSize, r * cellSize),
            linePaint,
          );
        }
        if (horizontalLines[r + 1][c]) {
          canvas.drawLine(
            Offset(c * cellSize, (r + 1) * cellSize),
            Offset((c + 1) * cellSize, (r + 1) * cellSize),
            linePaint,
          );
        }
        if (verticalLines[r][c]) {
          canvas.drawLine(
            Offset(c * cellSize, r * cellSize),
            Offset(c * cellSize, (r + 1) * cellSize),
            linePaint,
          );
        }
        if (boxes[r][c] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
            boxPaint1,
          );
        } else if (boxes[r][c] == 2) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
            boxPaint2,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
