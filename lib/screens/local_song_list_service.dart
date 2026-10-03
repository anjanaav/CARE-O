import 'dart:convert';
// import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
import 'file_manager.dart';

class LocalSongListService {
  List<dynamic> songs = [];

  Future<void> loadSongs() async {
    try {
      final file = await FileManager.getLocalFile();
      if (await file.exists()) {
        String content = await file.readAsString();
        songs = json.decode(content);
      } else {
        songs = [];
      }
    } catch (e) {
      debugPrint("Error loading songs: $e");
    }
  }

  Future<void> saveSongs() async {
    final file = await FileManager.getLocalFile();
    await file.writeAsString(json.encode(songs));
  }

  Future<void> addNewSong(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      String filePath = result.files.single.path!;
      TextEditingController titleController = TextEditingController();
      TextEditingController artistController = TextEditingController();

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Add New Song"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: "Song Title"),
                ),
                TextField(
                  controller: artistController,
                  decoration: InputDecoration(labelText: "Artist Name"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty &&
                      artistController.text.isNotEmpty) {
                    songs.add({
                      "title": titleController.text,
                      "artist": artistController.text,
                      "url": filePath,
                    });

                    await saveSongs();
                    Navigator.pop(context);
                  }
                },
                child: Text("Add"),
              ),
            ],
          );
        },
      );
    }
  }
}
