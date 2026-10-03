import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileManager {
  static Future<File> getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/devotional_songs.json');
  }
}
