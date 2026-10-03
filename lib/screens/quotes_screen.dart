import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  _QuotesScreenState createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  List<dynamic> _quotes = [];
  List<dynamic> _favoriteQuotes = [];
  int _currentIndex = 0;
  final List<Color> _quoteColors = [
    Colors.blue.shade100.withOpacity(0.6),
    Colors.green.shade100.withOpacity(0.6),
    Colors.orange.shade100.withOpacity(0.6),
    Colors.purple.shade100.withOpacity(0.6),
    Colors.red.shade100.withOpacity(0.6),
  ];

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _loadFavoriteQuotes();
  }

  Future<void> _loadQuotes() async {
    String data = await rootBundle.loadString('assets/icon/quotes.json');
    setState(() {
      _quotes = json.decode(data);
    });
  }

  Future<void> _loadFavoriteQuotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedFavorites = prefs.getString('favoriteQuotes');
    if (savedFavorites != null) {
      setState(() {
        _favoriteQuotes = json.decode(savedFavorites);
      });
    }
  }

  Future<void> _saveFavoriteQuotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('favoriteQuotes', json.encode(_favoriteQuotes));
  }

  void _nextQuote() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _quotes.length;
    });
  }

  void _previousQuote() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _quotes.length) % _quotes.length;
    });
  }

  void _toggleFavorite() {
    var currentQuote = _quotes[_currentIndex];
    setState(() {
      if (_favoriteQuotes.any((q) => q['quote'] == currentQuote['quote'])) {
        _favoriteQuotes.removeWhere((q) => q['quote'] == currentQuote['quote']);
      } else {
        _favoriteQuotes.add(currentQuote);
      }
    });
    _saveFavoriteQuotes();
  }

  void _showFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FavoriteQuotesScreen(favoriteQuotes: _favoriteQuotes),
      ),
    );
  }

  void _showAddQuoteDialog() {
    TextEditingController quoteController = TextEditingController();
    TextEditingController authorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Quote"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quoteController,
              decoration: InputDecoration(labelText: "Quote"),
            ),
            TextField(
              controller: authorController,
              decoration: InputDecoration(labelText: "Author"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _quotes.add({
                  "quote": quoteController.text,
                  "author": authorController.text
                });
              });
              Navigator.of(context).pop();
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _quotes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    color: _quoteColors[_currentIndex % _quoteColors.length],
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _quotes[_currentIndex]['quote'],
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "- " + _quotes[_currentIndex]['author'],
                            style: TextStyle(
                                fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                          IconButton(
                            icon: Icon(
                              _favoriteQuotes.any((q) =>
                                      q['quote'] ==
                                      _quotes[_currentIndex]['quote'])
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            onPressed: _toggleFavorite,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                          icon: Icon(Icons.arrow_back, size: 30),
                          onPressed: _previousQuote),
                      IconButton(
                          icon: Icon(Icons.arrow_forward, size: 30),
                          onPressed: _nextQuote),
                    ],
                  ),
                ],
              ),
            ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            left: 30, // Moves the Add button to the left corner
            bottom: 20, // Adjusts vertical positioning
            child: FloatingActionButton(
              onPressed: _showAddQuoteDialog,
              backgroundColor: Colors.orange.shade400,
              heroTag: "addQuote",
              child: Icon(Icons.add),
            ),
          ),
          Positioned(
            right: 20, // Keeps the Favorite button on the right
            bottom: 20,
            child: FloatingActionButton(
              onPressed: _showFavorites,
              backgroundColor: Colors.orange.shade400,
              heroTag: "favoriteQuotes",
              child: Icon(Icons.favorite),
            ),
          ),
        ],
      ),
    );
  }
}

class FavoriteQuotesScreen extends StatelessWidget {
  final List<dynamic> favoriteQuotes;
  const FavoriteQuotesScreen({super.key, required this.favoriteQuotes});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favorite Quotes"),
      ),
      body: ListView.builder(
        itemCount: favoriteQuotes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(favoriteQuotes[index]['quote']),
            subtitle: Text("- " + favoriteQuotes[index]['author']),
          );
        },
      ),
    );
  }
}
