import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  List<dynamic> _quotes = [];
  List<dynamic> _favoriteQuotes = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _loadFavoriteQuotes();
  }

  Future<void> _loadQuotes() async {
    try {
      final String data =
          await rootBundle.loadString('assets/icon/quotes.json');

      if (!mounted) return;

      setState(() {
        _quotes = json.decode(data) as List<dynamic>;
      });
    } catch (e) {
      debugPrint('Error loading quotes: $e');

      if (!mounted) return;

      setState(() {
        _quotes = [];
      });
    }
  }

  Future<void> _loadFavoriteQuotes() async {
    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      final String? savedFavorites =
          prefs.getString('favoriteQuotes');

      if (!mounted || savedFavorites == null) return;

      try {
        final decoded = json.decode(savedFavorites);

        if (decoded is List) {
          setState(() {
            _favoriteQuotes = decoded;
          });
        }
      } catch (e) {
        debugPrint('Error loading favorite quotes: $e');
      }
    } catch (e) {
      debugPrint('Error accessing preferences: $e');
    }
  }

  Future<void> _saveFavoriteQuotes() async {
    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'favoriteQuotes',
        json.encode(_favoriteQuotes),
      );
    } catch (e) {
      debugPrint('Error saving favorite quotes: $e');
    }
  }

  void _nextQuote() {
    if (_quotes.isEmpty) return;

    setState(() {
      _currentIndex =
          (_currentIndex + 1) % _quotes.length;
    });
  }

  void _previousQuote() {
    if (_quotes.isEmpty) return;

    setState(() {
      _currentIndex =
          (_currentIndex - 1 + _quotes.length) %
              _quotes.length;
    });
  }

  void _toggleFavorite() {
    if (_quotes.isEmpty) return;

    final currentQuote = _quotes[_currentIndex];

    final quoteText = currentQuote['quote']?.toString() ?? '';

    setState(() {
      final alreadyFavorite = _favoriteQuotes.any(
        (q) => q['quote']?.toString() == quoteText,
      );

      if (alreadyFavorite) {
        _favoriteQuotes.removeWhere(
          (q) => q['quote']?.toString() == quoteText,
        );
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
        builder: (context) => FavoriteQuotesScreen(
          favoriteQuotes: _favoriteQuotes,
        ),
      ),
    );
  }

  void _showAddQuoteDialog() {
    final TextEditingController quoteController =
        TextEditingController();

    final TextEditingController authorController =
        TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          title: const Text('Add New Quote'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: quoteController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Quote',
                    hintText: 'Enter the quote',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Author',
                    hintText: 'Enter the author',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: () {
                final quote =
                    quoteController.text.trim();
                final author =
                    authorController.text.trim();

                if (quote.isEmpty) return;

                setState(() {
                  _quotes.add({
                    'quote': quote,
                    'author':
                        author.isEmpty ? 'Unknown' : author,
                  });

                  _currentIndex = _quotes.length - 1;
                });

                Navigator.of(dialogContext).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    ).then((_) {
      quoteController.dispose();
      authorController.dispose();
    });
  }

  bool _isCurrentQuoteFavorite() {
    if (_quotes.isEmpty) return false;

    final currentQuote =
        _quotes[_currentIndex]['quote']?.toString() ?? '';

    return _favoriteQuotes.any(
      (q) => q['quote']?.toString() == currentQuote,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes'),
        centerTitle: true,
      ),

      body: _quotes.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  8,
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Card(
                      color:
                          colorScheme.surfaceContainerHighest,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.format_quote,
                              size: 42,
                              color: colorScheme.primary,
                            ),

                            const SizedBox(height: 16),

                            Text(
                              _quotes[_currentIndex]['quote']
                                      ?.toString() ??
                                  '',
                              style: theme
                                  .textTheme.titleLarge
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    colorScheme.onSurface,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 14),

                            Text(
                              '- ${_quotes[_currentIndex]['author']?.toString() ?? 'Unknown'}',
                              style: theme
                                  .textTheme.bodyLarge
                                  ?.copyWith(
                                fontStyle:
                                    FontStyle.italic,
                                color: colorScheme
                                    .onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),

                            IconButton(
                              tooltip:
                                  _isCurrentQuoteFavorite()
                                      ? 'Remove from favorites'
                                      : 'Add to favorites',
                              icon: Icon(
                                _isCurrentQuoteFavorite()
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 30,
                              ),
                              color:
                                  _isCurrentQuoteFavorite()
                                      ? colorScheme.error
                                      : colorScheme
                                          .onSurfaceVariant,
                              onPressed: _toggleFavorite,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Previous quote',
                          icon: const Icon(
                            Icons.arrow_back,
                            size: 30,
                          ),
                          onPressed: _previousQuote,
                        ),

                        Text(
                          '${_currentIndex + 1} / ${_quotes.length}',
                          style: theme
                              .textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                colorScheme.onSurfaceVariant,
                          ),
                        ),

                        IconButton.filledTonal(
                          tooltip: 'Next quote',
                          icon: const Icon(
                            Icons.arrow_forward,
                            size: 30,
                          ),
                          onPressed: _nextQuote,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

      // IMPORTANT:
      // The buttons are placed in the bottomNavigationBar
      // instead of floatingActionButton.
      //
      // This keeps the + button and Favorites button
      // perfectly aligned on both sides.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            12,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: 'addQuote',
                tooltip: 'Add quote',
                backgroundColor: colorScheme.primary,
                foregroundColor:
                    colorScheme.onPrimary,
                onPressed: _showAddQuoteDialog,
                child: const Icon(Icons.add),
              ),

              FloatingActionButton(
                heroTag: 'favoriteQuotes',
                tooltip: 'Favorite quotes',
                backgroundColor:
                    colorScheme.secondary,
                foregroundColor:
                    colorScheme.onSecondary,
                onPressed: _showFavorites,
                child: const Icon(Icons.favorite),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FavoriteQuotesScreen extends StatelessWidget {
  final List<dynamic> favoriteQuotes;

  const FavoriteQuotesScreen({
    super.key,
    required this.favoriteQuotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Quotes'),
        centerTitle: true,
      ),

      body: favoriteQuotes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color:
                          colorScheme.onSurfaceVariant,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'No favorite quotes yet',
                      style: theme
                          .textTheme.titleMedium
                          ?.copyWith(
                        color:
                            colorScheme.onSurface,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Tap the heart icon on a quote to save it here.',
                      textAlign: TextAlign.center,
                      style: theme
                          .textTheme.bodyMedium
                          ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteQuotes.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final quote =
                    favoriteQuotes[index];

                return Card(
                  color: colorScheme.surface,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    side: BorderSide(
                      color:
                          colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: colorScheme.primary,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          quote['quote']?.toString() ??
                              '',
                          style: theme
                              .textTheme.bodyLarge
                              ?.copyWith(
                            color:
                                colorScheme.onSurface,
                            fontWeight:
                                FontWeight.w500,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '- ${quote['author']?.toString() ?? 'Unknown'}',
                          style: theme
                              .textTheme.bodyMedium
                              ?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant,
                            fontStyle:
                                FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}