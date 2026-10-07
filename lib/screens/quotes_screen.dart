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
  static const String _favoritesKey = 'favoriteQuotes';
  static const String _customQuotesKey = 'customQuotes';

  List<Map<String, dynamic>> _quotes = [];
  List<Map<String, dynamic>> _favoriteQuotes = [];

  int _currentIndex = 0;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _initializeQuotes();
  }

  // ---------------------------------------------------------------------------
  // LOAD INITIAL DATA
  // ---------------------------------------------------------------------------

  Future<void> _initializeQuotes() async {
    await Future.wait([
      _loadQuotes(),
      _loadFavoriteQuotes(),
    ]);
  }

  Future<void> _loadQuotes() async {
    try {
      final data =
          await rootBundle.loadString('assets/icon/quotes.json');

      final decoded = json.decode(data);

      final loadedQuotes = <Map<String, dynamic>>[];

      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            final quoteText = item['quote']?.toString().trim() ?? '';

            if (quoteText.isEmpty) {
              continue;
            }

            loadedQuotes.add({
              'quote': quoteText,
              'author': item['author']?.toString().trim().isNotEmpty == true
                  ? item['author'].toString().trim()
                  : 'Unknown',
            });
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();

      final savedCustomQuotes =
          prefs.getString(_customQuotesKey);

      if (savedCustomQuotes != null) {
        try {
          final customDecoded = json.decode(savedCustomQuotes);

          if (customDecoded is List) {
            for (final item in customDecoded) {
              if (item is Map) {
                final quoteText =
                    item['quote']?.toString().trim() ?? '';

                if (quoteText.isEmpty) {
                  continue;
                }

                loadedQuotes.add({
                  'quote': quoteText,
                  'author':
                      item['author']?.toString().trim().isNotEmpty == true
                          ? item['author'].toString().trim()
                          : 'Unknown',
                });
              }
            }
          }
        } catch (e) {
          debugPrint(
            'Error loading custom quotes: $e',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _quotes = loadedQuotes;
        _isLoading = false;
        _loadError = null;

        if (_quotes.isEmpty) {
          _currentIndex = 0;
        } else if (_currentIndex >= _quotes.length) {
          _currentIndex = _quotes.length - 1;
        }
      });
    } catch (e) {
      debugPrint('Error loading quotes: $e');

      if (!mounted) return;

      setState(() {
        _quotes = [];
        _isLoading = false;
        _loadError = 'Unable to load quotes.';
      });
    }
  }

  Future<void> _loadFavoriteQuotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedFavorites =
          prefs.getString(_favoritesKey);

      if (savedFavorites == null) {
        return;
      }

      final decoded = json.decode(savedFavorites);

      if (decoded is! List) {
        return;
      }

      final favorites = <Map<String, dynamic>>[];

      for (final item in decoded) {
        if (item is Map) {
          final quoteText =
              item['quote']?.toString().trim() ?? '';

          if (quoteText.isEmpty) {
            continue;
          }

          favorites.add({
            'quote': quoteText,
            'author':
                item['author']?.toString().trim().isNotEmpty == true
                    ? item['author'].toString().trim()
                    : 'Unknown',
          });
        }
      }

      if (!mounted) return;

      setState(() {
        _favoriteQuotes = favorites;
      });
    } catch (e) {
      debugPrint(
        'Error loading favorite quotes: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SAVE DATA
  // ---------------------------------------------------------------------------

  Future<void> _saveFavoriteQuotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _favoritesKey,
        json.encode(_favoriteQuotes),
      );
    } catch (e) {
      debugPrint(
        'Error saving favorite quotes: $e',
      );
    }
  }

  Future<void> _saveCustomQuotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final customQuotes = _quotes.length > _originalQuoteCount
          ? _quotes.sublist(_originalQuoteCount)
          : <Map<String, dynamic>>[];

      await prefs.setString(
        _customQuotesKey,
        json.encode(customQuotes),
      );
    } catch (e) {
      debugPrint(
        'Error saving custom quotes: $e',
      );
    }
  }

  int get _originalQuoteCount {
    // quotes.json entries are the original quotes.
    // Custom quotes are stored separately.
    return _quotes.length -
        _customQuotesFromCurrentList.length;
  }

  List<Map<String, dynamic>> get _customQuotesFromCurrentList {
    // We identify custom quotes by checking against the original
    // asset list asynchronously elsewhere. To keep the runtime simple,
    // custom quotes are tracked explicitly below.
    return _customQuotes;
  }

  final List<Map<String, dynamic>> _customQuotes = [];

  // ---------------------------------------------------------------------------
  // QUOTE NAVIGATION
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // FAVORITES
  // ---------------------------------------------------------------------------

  void _toggleFavorite() {
    if (_quotes.isEmpty ||
        _currentIndex < 0 ||
        _currentIndex >= _quotes.length) {
      return;
    }

    final currentQuote = _quotes[_currentIndex];

    final quoteText =
        currentQuote['quote']?.toString() ?? '';

    if (quoteText.isEmpty) return;

    final alreadyFavorite = _favoriteQuotes.any(
      (quote) =>
          quote['quote']?.toString() == quoteText,
    );

    setState(() {
      if (alreadyFavorite) {
        _favoriteQuotes.removeWhere(
          (quote) =>
              quote['quote']?.toString() == quoteText,
        );
      } else {
        _favoriteQuotes.add(
          Map<String, dynamic>.from(currentQuote),
        );
      }
    });

    _saveFavoriteQuotes();
  }

  bool _isCurrentQuoteFavorite() {
    if (_quotes.isEmpty ||
        _currentIndex < 0 ||
        _currentIndex >= _quotes.length) {
      return false;
    }

    final currentQuote =
        _quotes[_currentIndex]['quote']?.toString() ?? '';

    return _favoriteQuotes.any(
      (quote) =>
          quote['quote']?.toString() == currentQuote,
    );
  }

  // ---------------------------------------------------------------------------
  // FAVORITES SCREEN
  // ---------------------------------------------------------------------------

  void _showFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FavoriteQuotesScreen(
          favoriteQuotes:
              List<Map<String, dynamic>>.from(
            _favoriteQuotes,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ADD QUOTE
  // ---------------------------------------------------------------------------

  Future<void> _showAddQuoteDialog() async {
    final quoteController = TextEditingController();
    final authorController = TextEditingController();

    try {
      final result =
          await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add New Quote'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: quoteController,
                    maxLines: 3,
                    textCapitalization:
                        TextCapitalization.sentences,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Quote',
                      hintText: 'Enter the quote',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: authorController,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Author',
                      hintText: 'Enter the author',
                      border: OutlineInputBorder(),
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
                onPressed: () {
                  final quote =
                      quoteController.text.trim();

                  final author =
                      authorController.text.trim();

                  if (quote.isEmpty) {
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please enter a quote.'),
                      ),
                    );
                    return;
                  }

                  // IMPORTANT:
                  // We only return the data here.
                  // We do NOT call setState while the dialog
                  // is closing.
                  Navigator.of(dialogContext).pop({
                    'quote': quote,
                    'author': author.isEmpty
                        ? 'Unknown'
                        : author,
                  });
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );

      // The dialog has completely finished closing at this point.

      if (!mounted || result == null) {
        return;
      }

      final quote = result['quote']?.trim() ?? '';
      final author =
          result['author']?.trim() ?? 'Unknown';

      if (quote.isEmpty) {
        return;
      }

      final newQuote = <String, dynamic>{
        'quote': quote,
        'author':
            author.isEmpty ? 'Unknown' : author,
      };

      setState(() {
        _customQuotes.add(newQuote);
        _quotes.add(newQuote);
        _currentIndex = _quotes.length - 1;
      });

      await _saveCustomQuotes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quote added successfully.'),
        ),
      );
    } finally {
      quoteController.dispose();
      authorController.dispose();
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes'),
        centerTitle: true,
      ),

      body: _buildBody(
        context,
        theme,
        colors,
      ),

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
            children: [
              FloatingActionButton(
                heroTag: 'addQuote',
                tooltip: 'Add quote',
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                onPressed: _showAddQuoteDialog,
                child: const Icon(Icons.add),
              ),

              FloatingActionButton(
                heroTag: 'favoriteQuotes',
                tooltip: 'Favorite quotes',
                backgroundColor: colors.secondary,
                foregroundColor: colors.onSecondary,
                onPressed: _showFavorites,
                child: const Icon(Icons.favorite),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
  ) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: colors.primary,
        ),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 56,
                color: colors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _loadError = null;
                  });

                  _loadQuotes();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_quotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.format_quote,
                size: 64,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No quotes available',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first quote using the + button.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentIndex >= _quotes.length) {
      _currentIndex = _quotes.length - 1;
    }

    final currentQuote = _quotes[_currentIndex];

    final quoteText =
        currentQuote['quote']?.toString() ?? '';

    final author =
        currentQuote['author']?.toString() ?? 'Unknown';

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isWide ? 40 : 20,
              20,
              isWide ? 40 : 20,
              8,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 800,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      color:
                          colors.surfaceContainerHighest,
                      elevation: 2,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              colors.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding:
                            EdgeInsets.all(
                          isWide ? 36 : 24,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.format_quote,
                              size: isWide ? 52 : 42,
                              color: colors.primary,
                            ),

                            const SizedBox(height: 16),

                            Text(
                              quoteText,
                              style: theme
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    colors.onSurface,
                                height: 1.4,
                              ),
                              textAlign:
                                  TextAlign.center,
                            ),

                            const SizedBox(height: 14),

                            Text(
                              '- $author',
                              style: theme
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                fontStyle:
                                    FontStyle.italic,
                                color: colors
                                    .onSurfaceVariant,
                              ),
                              textAlign:
                                  TextAlign.center,
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
                                      ? colors.error
                                      : colors
                                          .onSurfaceVariant,
                              onPressed:
                                  _toggleFavorite,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Previous quote',
                          icon: const Icon(
                            Icons.arrow_back,
                            size: 30,
                          ),
                          onPressed: _previousQuote,
                        ),

                        const SizedBox(width: 24),

                        Text(
                          '${_currentIndex + 1} / ${_quotes.length}',
                          style: theme
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight:
                                FontWeight.w600,
                            color:
                                colors.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(width: 24),

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
          );
        },
      ),
    );
  }
}

// ============================================================================
// FAVORITE QUOTES SCREEN
// ============================================================================

class FavoriteQuotesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favoriteQuotes;

  const FavoriteQuotesScreen({
    super.key,
    required this.favoriteQuotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No favorite quotes yet',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the heart icon on a quote to save it here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(
                        color:
                            colors.onSurfaceVariant,
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

                final quoteText =
                    quote['quote']?.toString() ?? '';

                final author =
                    quote['author']?.toString() ??
                        'Unknown';

                return Card(
                  color: colors.surface,
                  elevation: 1,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    side: BorderSide(
                      color:
                          colors.outlineVariant,
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
                          color: colors.primary,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          quoteText,
                          style: theme
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                            color:
                                colors.onSurface,
                            fontWeight:
                                FontWeight.w500,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '- $author',
                          style: theme
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: colors
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