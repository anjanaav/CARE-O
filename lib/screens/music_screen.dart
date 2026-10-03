import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<File> songs = [];
  File? currentSong;
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _loadSavedSongs();

    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          currentPosition = position;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          totalDuration = duration;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      _playNextSong();
    });
  }

  Future<void> pickMusicFiles() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        for (final String path in result.paths.whereType<String>()) {
          final File newSong = File(path);

          if (!songs.any((song) => song.path == newSong.path)) {
            songs.add(newSong);
          }
        }
      });

      await _saveSongs();
    }
  }

  Future<void> _saveSongs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'saved_songs',
      songs.map((song) => song.path).toList(),
    );
  }

  Future<void> _loadSavedSongs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final List<String>? savedPaths =
        prefs.getStringList('saved_songs');

    if (savedPaths != null && mounted) {
      setState(() {
        songs = savedPaths.map((path) => File(path)).toList();
      });
    }
  }

  Future<void> _playPauseSong(File song) async {
    if (currentSong?.path == song.path && isPlaying) {
      await _audioPlayer.pause();

      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    } else {
      await _audioPlayer.play(
        DeviceFileSource(song.path),
      );

      if (mounted) {
        setState(() {
          currentSong = song;
          isPlaying = true;
        });
      }
    }
  }

  void _playNextSong() {
    if (currentSong != null) {
      final int currentIndex = songs.indexOf(currentSong!);

      if (currentIndex != -1 &&
          currentIndex < songs.length - 1) {
        _playPauseSong(songs[currentIndex + 1]);
      } else {
        _audioPlayer.stop();

        if (mounted) {
          setState(() {
            isPlaying = false;
            currentSong = null;
            currentPosition = Duration.zero;
            totalDuration = Duration.zero;
          });
        }
      }
    }
  }

  void _playPreviousSong() {
    if (currentSong != null) {
      final int currentIndex = songs.indexOf(currentSong!);

      if (currentIndex > 0) {
        _playPauseSong(songs[currentIndex - 1]);
      }
    }
  }

  void _seekTo(double value) {
    _audioPlayer.seek(
      Duration(milliseconds: value.toInt()),
    );
  }

  void _deleteSong(File song) {
    setState(() {
      songs.remove(song);

      if (currentSong?.path == song.path) {
        _audioPlayer.stop();
        currentSong = null;
        isPlaying = false;
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
      }
    });

    _saveSongs();
  }

  String _fileName(File file) {
    return file.path.split(Platform.pathSeparator).last;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Theme-aware colors.
    final Color cardStartColor = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.10),
      colorScheme.surface,
    );

    final Color cardEndColor = Color.alphaBlend(
      colorScheme.secondary.withValues(alpha: 0.10),
      colorScheme.surface,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Music Player',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 14),

              Expanded(
                child: songs.isEmpty
                    ? Center(
                        child: Text(
                          'No songs selected',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: 90,
                        ),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final File song = songs[index];

                          final bool isCurrentSong =
                              currentSong?.path == song.path;

                          final double sliderMax =
                              totalDuration.inMilliseconds > 0
                                  ? totalDuration.inMilliseconds.toDouble()
                                  : 1;

                          final double sliderValue =
                              isCurrentSong
                                  ? currentPosition.inMilliseconds
                                      .clamp(
                                        0,
                                        totalDuration.inMilliseconds,
                                      )
                                      .toDouble()
                                  : 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    cardStartColor,
                                    cardEndColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow
                                        .withValues(alpha: 0.10),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.music_note,
                                    color: colorScheme.primary,
                                    size: 35,
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _fileName(song),
                                          style: theme
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurface,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              tooltip:
                                                  'Previous song',
                                              icon: Icon(
                                                Icons.skip_previous,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                size: 22,
                                              ),
                                              onPressed:
                                                  _playPreviousSong,
                                            ),

                                            IconButton(
                                              tooltip: isCurrentSong &&
                                                      isPlaying
                                                  ? 'Pause'
                                                  : 'Play',
                                              icon: Icon(
                                                isCurrentSong &&
                                                        isPlaying
                                                    ? Icons
                                                        .pause_circle
                                                    : Icons
                                                        .play_circle,
                                                color: colorScheme
                                                    .primary,
                                                size: 38,
                                              ),
                                              onPressed: () =>
                                                  _playPauseSong(song),
                                            ),

                                            IconButton(
                                              tooltip: 'Next song',
                                              icon: Icon(
                                                Icons.skip_next,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                size: 22,
                                              ),
                                              onPressed:
                                                  _playNextSong,
                                            ),
                                          ],
                                        ),

                                        Slider(
                                          value: sliderValue,
                                          max: sliderMax,
                                          activeColor:
                                              colorScheme.primary,
                                          inactiveColor: colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.25),
                                          onChanged:
                                              isCurrentSong
                                                  ? _seekTo
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),

                                  PopupMenuButton<String>(
                                    tooltip: 'More options',
                                    icon: Icon(
                                      Icons.more_vert,
                                      color:
                                          colorScheme.onSurfaceVariant,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _deleteSong(song);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              color:
                                                  colorScheme.error,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              tooltip: 'Add music',
              onPressed: pickMusicFiles,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 6,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}