import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'file_manager.dart';

class LocalSongListService {
  List<dynamic> songs = [];

  Future<void> loadSongs() async {
    try {
      final file = await FileManager.getLocalFile();

      if (await file.exists()) {
        final content = await file.readAsString();

        final decoded = json.decode(content);

        if (decoded is List) {
          songs = decoded;
        } else {
          songs = [];
        }
      } else {
        songs = [];
      }
    } catch (e) {
      songs = [];
      debugPrint('Error loading songs: $e');
    }
  }

  Future<void> saveSongs() async {
    try {
      final file = await FileManager.getLocalFile();

      await file.writeAsString(
        json.encode(songs),
      );
    } catch (e) {
      debugPrint('Error saving songs: $e');
      rethrow;
    }
  }

  Future<void> addNewSong(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result == null ||
        result.files.isEmpty ||
        result.files.single.path == null) {
      return;
    }

    final filePath = result.files.single.path!;

    final titleController = TextEditingController();
    final artistController = TextEditingController();

    try {
      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          final colorScheme = theme.colorScheme;

          return AlertDialog(
            title: const Text('Add New Song'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Song Title',
                      prefixIcon: Icon(Icons.music_note),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: artistController,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Artist Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final title =
                      titleController.text.trim();
                  final artist =
                      artistController.text.trim();

                  if (title.isEmpty || artist.isEmpty) {
                    ScaffoldMessenger.of(dialogContext)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter both song title and artist name.',
                        ),
                      ),
                    );
                    return;
                  }

                  songs.add({
                    'title': title,
                    'artist': artist,
                    'url': filePath,
                  });

                  try {
                    await saveSongs();

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Song added successfully.',
                        ),
                        backgroundColor:
                            colorScheme.primary,
                      ),
                    );
                  } catch (e) {
                    if (!dialogContext.mounted) return;

                    ScaffoldMessenger.of(dialogContext)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Unable to save the song.',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    } finally {
      titleController.dispose();
      artistController.dispose();
    }
  }
}