import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'local_song_list_service.dart';
import 'local_music_player_service.dart';

class DevotionalMusicScreen extends StatefulWidget {
  const DevotionalMusicScreen({super.key});

  @override
  _DevotionalMusicScreenState createState() => _DevotionalMusicScreenState();
}

class _DevotionalMusicScreenState extends State<DevotionalMusicScreen> {
  final LocalSongListService _songList = LocalSongListService();
  late LocalMusicPlayerService _musicPlayer;
  List<dynamic> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _musicPlayer = LocalMusicPlayerService(
      onSongChanged: () {
        setState(() {}); // Update UI when song changes
      },
    );
    _loadSongs();

    // Listen for song completion and play next song
    _musicPlayer.audioPlayer.onPlayerComplete.listen((event) {
      _playNextSong();
    });

    // Listen for progress updates
    _musicPlayer.audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    _musicPlayer.audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });
  }

  Future<void> _loadSongs() async {
    await _songList.loadSongs();
    setState(() {
      _musicPlayer.songs = _songList.songs;
    });
  }

  void _playNextSong() {
    if (_musicPlayer.currentIndex < _musicPlayer.songs.length - 1) {
      _musicPlayer.nextSong();
    } else {
      // Stop playback at end of playlist
      _musicPlayer.stopMusic();
    }
  }

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Filter local songs first
    List<dynamic> localResults = _songList.songs
        .where((song) =>
            song['title'].toLowerCase().contains(query.toLowerCase()) ||
            song['artist'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      _searchResults = localResults;
    });

    // Fetch online results (optional)
    try {
      final response = await http
          .get(Uri.parse('https://api.example.com/search?query=$query'));

      if (response.statusCode == 200) {
        List<dynamic> onlineResults = json.decode(response.body);
        setState(() {
          _searchResults.addAll(onlineResults);
        });
      }
    } catch (e) {
      debugPrint("Error fetching songs: $e");
    }
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 222, 219, 219),
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(hintText: "Search Devotional Songs..."),
          onChanged: _searchSongs,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isSearching
                ? _searchResults.isNotEmpty
                    ? ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_searchResults[index]['title']),
                            subtitle: Text(_searchResults[index]['artist']),
                            trailing: IconButton(
                              icon: Icon(Icons.play_arrow),
                              onPressed: () async {
                                await _musicPlayer.audioPlayer.play(
                                    UrlSource(_searchResults[index]['url']));
                              },
                            ),
                          );
                        },
                      )
                    : Center(
                        child:
                            Text("No results found. Try a different search."))
                : _musicPlayer.songs.isEmpty
                    ? Center(child: Text("No songs added. Tap + to add songs."))
                    : Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _musicPlayer.songs[_musicPlayer.currentIndex]
                                  ['title'],
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              _musicPlayer.songs[_musicPlayer.currentIndex]
                                  ['artist'],
                              style: TextStyle(
                                  fontSize: 18, fontStyle: FontStyle.italic),
                            ),
                            SizedBox(height: 20),

                            // Progress Bar
                            Slider(
                              value: _currentPosition.inSeconds.toDouble(),
                              max: _totalDuration.inSeconds.toDouble(),
                              onChanged: (value) async {
                                Duration newPosition =
                                    Duration(seconds: value.toInt());
                                await _musicPlayer.audioPlayer
                                    .seek(newPosition);
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(_currentPosition)),
                                Text(_formatDuration(_totalDuration)),
                              ],
                            ),

                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.skip_previous, size: 30),
                                  onPressed: _musicPlayer.previousSong,
                                ),
                                IconButton(
                                  icon: Icon(
                                      _musicPlayer.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 30),
                                  onPressed: _musicPlayer.playPauseMusic,
                                ),
                                IconButton(
                                  icon: Icon(Icons.skip_next, size: 30),
                                  onPressed: _playNextSong,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _songList.addNewSong(context),
        child: Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
