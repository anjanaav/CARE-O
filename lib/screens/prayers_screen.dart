import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Prayer Model
class Prayer {
  String title;
  String content;

  Prayer({
    required this.title,
    required this.content,
  });

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(
      title: json['title'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}

/// Handles Local JSON Storage
class PrayerStorage {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/prayers.json');
  }

  /// Loads prayers from local file or assets if not found
  static Future<List<Prayer>> loadPrayers() async {
    try {
      final file = await _localFile;

      if (!await file.exists()) {
        final assetData =
            await rootBundle.loadString('assets/icon/prayers.json');

        final List<dynamic> jsonData = json.decode(assetData);

        return jsonData
            .map((data) => Prayer.fromJson(data))
            .toList();
      }

      final contents = await file.readAsString();

      if (contents.trim().isEmpty) {
        return [];
      }

      final List<dynamic> jsonData = json.decode(contents);

      return jsonData
          .map((data) => Prayer.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error loading prayers: $e');
      return [];
    }
  }

  /// Saves prayers to local JSON file
  static Future<void> savePrayers(List<Prayer> prayers) async {
    try {
      final file = await _localFile;

      final jsonData = prayers
          .map((prayer) => prayer.toJson())
          .toList();

      await file.writeAsString(
        json.encode(jsonData),
      );
    } catch (e) {
      debugPrint('Error saving prayers: $e');
    }
  }
}

class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  List<Prayer> prayers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrayers();
  }

  /// Loads prayers
  Future<void> _loadPrayers() async {
    setState(() {
      isLoading = true;
    });

    final loadedPrayers = await PrayerStorage.loadPrayers();

    if (!mounted) return;

    setState(() {
      prayers = loadedPrayers;
      isLoading = false;
    });
  }

  /// Adds a new prayer
  void _addPrayer() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Add Prayer',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  final updatedPrayers =
                      await PrayerStorage.loadPrayers();

                  updatedPrayers.add(
                    Prayer(
                      title: titleController.text,
                      content: contentController.text,
                    ),
                  );

                  await PrayerStorage.savePrayers(updatedPrayers);

                  if (!mounted) return;

                  await _loadPrayers();
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// Deletes a prayer
  Future<void> _deletePrayer(int index) async {
    setState(() {
      prayers.removeAt(index);
    });

    await PrayerStorage.savePrayers(prayers);

    if (mounted) {
      await _loadPrayers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : prayers.isEmpty
              ? Center(
                  child: Text(
                    'No prayers available. Add a new one!',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: prayers.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: colorScheme.surface,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        title: Text(
                          prayers[index].title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          prayers[index].content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () => _showPrayerDetail(
                          context,
                          prayers[index],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deletePrayer(index);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_vert,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPrayer,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Shows detailed prayer view
  void _showPrayerDetail(
    BuildContext context,
    Prayer prayer,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            prayer.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              prayer.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}