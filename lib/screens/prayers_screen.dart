import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Prayer Model
class Prayer {
  String title;
  String content;

  Prayer({required this.title, required this.content});

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(title: json['title'], content: json['content']);
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'content': content};
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
        String assetData =
            await rootBundle.loadString('assets/icon/prayers.json');
        List<dynamic> jsonData = json.decode(assetData);
        return jsonData.map((data) => Prayer.fromJson(data)).toList();
      }
      String contents = await file.readAsString();
      if (contents.trim().isEmpty) return []; // ✅ Handle empty file case
      List<dynamic> jsonData = json.decode(contents);
      return jsonData.map((data) => Prayer.fromJson(data)).toList();
    } catch (e) {
      debugPrint("❌ Error loading prayers: $e");
      return [];
    }
  }

  /// Saves prayers to JSON file
  static Future<void> savePrayers(List<Prayer> prayers) async {
    final file = await _localFile;
    if (prayers.isEmpty) {
      await file.writeAsString("[]"); // ✅ Save empty array if no prayers left
    } else {
      String jsonString = json.encode(prayers.map((p) => p.toJson()).toList());
      await file.writeAsString(jsonString);
    }
  }
}

/// Prayers Screen UI
class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key});

  @override
  _PrayersScreenState createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  List<Prayer> prayers = [];
  bool isLoading = true; // ✅ Added loading state

  @override
  void initState() {
    super.initState();
    _loadPrayers();
  }

  /// Loads prayers from JSON and updates UI
  Future<void> _loadPrayers() async {
    List<Prayer> loadedPrayers = await PrayerStorage.loadPrayers();
    setState(() {
      prayers = loadedPrayers;
      isLoading = false; // ✅ Stop buffering once loaded
    });
  }

  /// Adds a new prayer
  Future<void> _addPrayer() async {
    TextEditingController titleController = TextEditingController();
    TextEditingController contentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title:
              Text("Add Prayer", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Title"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: contentController,
                decoration: InputDecoration(labelText: "Content"),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  List<Prayer> updatedPrayers =
                      await PrayerStorage.loadPrayers();

                  updatedPrayers.add(Prayer(
                      title: titleController.text,
                      content: contentController.text));

                  await PrayerStorage.savePrayers(updatedPrayers);
                  _loadPrayers();
                }
                Navigator.pop(context);
              },
              child: Text("Add", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  /// Deletes a prayer
  void _deletePrayer(int index) async {
    setState(() {
      prayers.removeAt(index);
    });
    await PrayerStorage.savePrayers(prayers);
    _loadPrayers(); // ✅ Reload after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // ✅ Show loader while fetching
          : prayers.isEmpty
              ? Center(
                  child: Text(
                    "No prayers available. Add a new one!",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(15),
                  itemCount: prayers.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(15),
                        title: Text(
                          prayers[index].title,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          prayers[index].content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        onTap: () => _showPrayerDetail(context, prayers[index]),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == "delete") {
                              _deletePrayer(index);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: "delete",
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text("Delete"),
                                ],
                              ),
                            ),
                          ],
                          icon: Icon(Icons.more_vert), // Three-dotted menu icon
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPrayer,
        child: Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  /// Shows detailed prayer view
  void _showPrayerDetail(BuildContext context, Prayer prayer) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title:
              Text(prayer.title, style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(prayer.content, style: TextStyle(fontSize: 16)),
          ),
          actions: [
            TextButton(
              child: Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
