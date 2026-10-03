import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'local_music_player_service.dart';
import 'local_song_list_service.dart';

class DevotionalMusicScreen extends StatefulWidget {
  const DevotionalMusicScreen({super.key});

  @override
  State<DevotionalMusicScreen> createState() =>
      _DevotionalMusicScreenState();
}

class _DevotionalMusicScreenState extends State<DevotionalMusicScreen> {
  final LocalSongListService _songList = LocalSongListService();

  late final LocalMusicPlayerService _musicPlayer;

  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _searchResults = [];

  bool _isSearching = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _musicPlayer = LocalMusicPlayerService(
      onSongChanged: () {
        if (mounted) {
          setState(() {
            _currentPosition = Duration.zero;
            _totalDuration = Duration.zero;
          });
        }
      },
    );

    _loadSongs();

    _musicPlayer.audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        _playNextSong();
      }
    });

    _musicPlayer.audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;

      setState(() {
        _totalDuration = duration;
      });
    });

    _musicPlayer.audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;

      setState(() {
        _currentPosition = position;
      });
    });
  }

  Future<void> _loadSongs() async {
    try {
      await _songList.loadSongs();

      if (!mounted) return;

      setState(() {
        _musicPlayer.songs = List<dynamic>.from(_songList.songs);
      });
    } catch (e) {
      debugPrint('Error loading devotional songs: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load devotional songs.'),
        ),
      );
    }
  }

  void _playNextSong() {
    if (_musicPlayer.songs.isEmpty) return;

    if (_musicPlayer.currentIndex <
        _musicPlayer.songs.length - 1) {
      _musicPlayer.nextSong();
    } else {
      _musicPlayer.stopMusic();

      if (mounted) {
        setState(() {
          _currentPosition = Duration.zero;
        });
      }
    }
  }

  void _searchSongs(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    final results = _songList.songs.where((song) {
      if (song is! Map) return false;

      final title = song['title']?.toString().toLowerCase() ?? '';
      final artist = song['artist']?.toString().toLowerCase() ?? '';

      return title.contains(normalizedQuery) ||
          artist.contains(normalizedQuery);
    }).toList();

    setState(() {
      _isSearching = true;
      _searchResults = results;
    });
  }

  Future<void> _playSearchResult(dynamic song) async {
    if (song is! Map) return;

    final url = song['url']?.toString();

    if (url == null || url.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This song does not have a valid audio file.'),
        ),
      );
      return;
    }

    try {
      await _musicPlayer.audioPlayer.play(
        UrlSource(url),
      );
    } catch (e) {
      debugPrint('Error playing search result: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to play this song.'),
        ),
      );
    }
  }

  Future<void> _seekTo(double value) async {
    final seconds = value.toInt();

    await _musicPlayer.audioPlayer.seek(
      Duration(seconds: seconds),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes =
        duration.inMinutes.toString().padLeft(2, '0');

    final seconds =
        (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  dynamic _currentSong() {
    if (_musicPlayer.songs.isEmpty) {
      return null;
    }

    final index = _musicPlayer.currentIndex;

    if (index < 0 || index >= _musicPlayer.songs.length) {
      return _musicPlayer.songs.first;
    }

    return _musicPlayer.songs[index];
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search devotional songs...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colorScheme.onSurfaceVariant,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _searchSongs('');
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: _searchSongs,
        ),
      ),
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add devotional song',
        onPressed: () async {
          await _songList.addNewSong(context);

          if (!mounted) return;

          setState(() {
            _musicPlayer.songs =
                List<dynamic>.from(_songList.songs);
          });
        },
        child: Icon(
          Icons.add,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isSearching) {
      return _buildSearchResults(context);
    }

    if (_musicPlayer.songs.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildPlayer(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 56,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No songs found',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching with a different title or artist.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final song = _searchResults[index];

        final title =
            song is Map ? song['title']?.toString() ?? 'Unknown song' : 'Unknown song';

        final artist =
            song is Map ? song['artist']?.toString() ?? 'Unknown artist' : 'Unknown artist';

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.music_note,
                color:
                    Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: 'Play $title',
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _playSearchResult(song),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'No devotional songs yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a devotional song.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final song = _currentSong();

    if (song is! Map) {
      return _buildEmptyState(context);
    }

    final title =
        song['title']?.toString() ?? 'Unknown song';

    final artist =
        song['artist']?.toString() ?? 'Unknown artist';

    final totalSeconds =
        _totalDuration.inSeconds.toDouble();

    final currentSeconds =
        _currentPosition.inSeconds
            .toDouble()
            .clamp(
              0.0,
              totalSeconds > 0 ? totalSeconds : 1.0,
            );

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 560,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.music_note,
                    size: 72,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  artist,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 28),

                Slider(
                  value: currentSeconds,
                  max: totalSeconds > 0 ? totalSeconds : 1.0,
                  onChanged: totalSeconds <= 0
                      ? null
                      : (value) {
                          _seekTo(value);
                        },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_currentPosition),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatDuration(_totalDuration),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Previous song',
                      iconSize: 34,
                      onPressed: _musicPlayer.songs.length > 1
                          ? _musicPlayer.previousSong
                          : null,
                      icon: const Icon(
                        Icons.skip_previous,
                      ),
                    ),

                    const SizedBox(width: 12),

                    FilledButton(
                      onPressed: _musicPlayer.songs.isEmpty
                          ? null
                          : _musicPlayer.playPauseMusic,
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(18),
                      ),
                      child: Icon(
                        _musicPlayer.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 34,
                      ),
                    ),

                    const SizedBox(width: 12),

                    IconButton(
                      tooltip: 'Next song',
                      iconSize: 34,
                      onPressed: _musicPlayer.songs.length > 1
                          ? _playNextSong
                          : null,
                      icon: const Icon(
                        Icons.skip_next,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}