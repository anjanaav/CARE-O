import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class LocalMusicPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  int currentIndex = 0;
  List<dynamic> songs = [];
  final VoidCallback onSongChanged; // Callback to update UI

  LocalMusicPlayerService({required this.onSongChanged}) {
    // Listen for song completion
    _audioPlayer.onPlayerComplete.listen((event) {
      if (isPlaying) {
        // Ensures nextSong() only triggers if music is playing
        nextSong();
      }
    });
  }

  AudioPlayer get audioPlayer => _audioPlayer;

  Future<void> playPauseMusic() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      String songPath = songs[currentIndex]['url'];
      await _audioPlayer.play(DeviceFileSource(songPath));
    }
    isPlaying = !isPlaying;
    onSongChanged(); // Notify UI
  }

  void nextSong() async {
    if (songs.isNotEmpty && isPlaying) {
      // Ensure a song is playing
      if (currentIndex < songs.length - 1) {
        isPlaying = false; // Prevent double-triggering
        await _audioPlayer.stop();

        currentIndex++; // Move to the next song
        await playCurrentSong();
      } else {
        stopMusic(); // Stop at the end of the playlist
      }
    }
  }

  void previousSong() async {
    if (songs.isNotEmpty) {
      currentIndex = (currentIndex - 1 + songs.length) % songs.length;
      await _audioPlayer.stop();
      await playCurrentSong();
    }
  }

  Future<void> playCurrentSong() async {
    String songPath = songs[currentIndex]['url'];
    await _audioPlayer.play(DeviceFileSource(songPath));
    isPlaying = true;
    onSongChanged(); // Update UI
  }

  void stopMusic() async {
    await _audioPlayer.stop();
    isPlaying = false;
    onSongChanged(); // Notify UI to update
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
