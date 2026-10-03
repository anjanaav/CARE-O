import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  _MusicScreenState createState() => _MusicScreenState();
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
      setState(() => currentPosition = position);
    });
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() => totalDuration = duration);
    });
    _audioPlayer.onPlayerComplete.listen((event) => _playNextSong());
  }

  Future<void> pickMusicFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        for (String path in result.paths.whereType<String>()) {
          File newSong = File(path);
          if (!songs.any((song) => song.path == newSong.path)) {
            songs.add(newSong); // Only add if it's not already in the list
          }
        }
      });
      _saveSongs();
    }
  }

  Future<void> _saveSongs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'saved_songs', songs.map((song) => song.path).toList());
  }

  Future<void> _loadSavedSongs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedPaths = prefs.getStringList('saved_songs');
    if (savedPaths != null) {
      setState(() => songs = savedPaths.map((path) => File(path)).toList());
    }
  }

  void _playPauseSong(File song) async {
    if (currentSong == song && isPlaying) {
      await _audioPlayer.pause();
      setState(() => isPlaying = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(song.path));
      setState(() {
        currentSong = song;
        isPlaying = true;
      });
    }
  }

  void _playNextSong() {
    if (currentSong != null) {
      int currentIndex = songs.indexOf(currentSong!);
      if (currentIndex != -1 && currentIndex < songs.length - 1) {
        _playPauseSong(songs[currentIndex + 1]);
      } else {
        _audioPlayer.stop();
        setState(() {
          isPlaying = false;
          currentSong = null;
        });
      }
    }
  }

  void _playPreviousSong() {
    if (currentSong != null) {
      int currentIndex = songs.indexOf(currentSong!);
      if (currentIndex > 0) {
        _playPauseSong(songs[currentIndex - 1]);
      }
    }
  }

  void _seekTo(double value) {
    _audioPlayer.seek(Duration(milliseconds: value.toInt()));
  }

  void _deleteSong(File song) {
    setState(() {
      songs.remove(song);
      if (currentSong == song) {
        _audioPlayer.stop();
        currentSong = null;
        isPlaying = false;
      }
    });
    _saveSongs();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Music Player'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding:
                    EdgeInsets.only(top: 14), // Adjust this value as needed
              ),
              Expanded(
                child: songs.isEmpty
                    ? Center(child: Text("No songs selected"))
                    : ListView.builder(
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Container(
                              padding: EdgeInsets.all(8), // Reduced size
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromARGB(
                                        255, 255, 223, 88), // Light Yellow
                                    Color.fromARGB(
                                        255, 255, 153, 51), // Orange-Gold
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),

                              child: Row(
                                children: [
                                  Icon(Icons.music_note,
                                      color: Colors.grey[800], size: 35),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          songs[index].path.split('/').last,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.skip_previous,
                                                  color: Colors.grey[800],
                                                  size: 20),
                                              onPressed: _playPreviousSong,
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                currentSong == songs[index] &&
                                                        isPlaying
                                                    ? Icons.pause_circle
                                                    : Icons.play_circle,
                                                color: Colors.grey[800],
                                                size: 35,
                                              ),
                                              onPressed: () =>
                                                  _playPauseSong(songs[index]),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.skip_next,
                                                  color: Colors.grey[800],
                                                  size: 20),
                                              onPressed: _playNextSong,
                                            ),
                                          ],
                                        ),
                                        Slider(
                                          value: currentSong == songs[index]
                                              ? currentPosition.inMilliseconds
                                                  .clamp(
                                                      0,
                                                      totalDuration
                                                          .inMilliseconds)
                                                  .toDouble()
                                              : 0,
                                          max: totalDuration.inMilliseconds
                                                      .toDouble() >
                                                  0
                                              ? totalDuration.inMilliseconds
                                                  .toDouble()
                                              : 1, // Prevents division by zero
                                          activeColor: Colors.grey[800],
                                          inactiveColor: Colors.grey[300],
                                          onChanged: (value) => _seekTo(value),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Three-Dotted Menu Button
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _deleteSong(
                                            songs[index]); // Delete song action
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete,
                                                color: Colors.red),
                                            SizedBox(width: 10),
                                            Text("Delete"),
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
            bottom: 10,
            left: 10,
            child: FloatingActionButton(
              onPressed: pickMusicFiles,
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 6,
              child: Icon(Icons.add, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}
