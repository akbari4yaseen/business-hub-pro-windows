import 'dart:io';
import 'package:path/path.dart' as path;

class DbExportImport {
  /// Export (backup) the database
  static Future<bool> exportDatabase(
      String destinationPath, Future<String> Function() getPath) async {
    try {
      final dbPath = await getPath();
      // Ensure DB is closed
      await _closeOpenDb();
      final sourceFile = File(dbPath);
      if (!await sourceFile.exists()) return false;

      // For Windows, ensure the destination directory exists
      if (Platform.isWindows) {
        final destDir = path.dirname(destinationPath);
        if (!await Directory(destDir).exists()) {
          await Directory(destDir).create(recursive: true);
        }
      }

      await sourceFile.copy(destinationPath);
      return true;
    } catch (e) {
      print('Export error: $e');
      return false;
    }
  }

  /// Import (restore) the database
  static Future<bool> importDatabase(
    String sourcePath,
    Future<String> Function() getPath,
    Future<void> Function() reopen,
  ) async {
    try {
      final dbPath = await getPath();
      final dbFile = File(dbPath);

      // For Windows, ensure the target directory exists
      if (Platform.isWindows) {
        final targetDir = path.dirname(dbPath);
        if (!await Directory(targetDir).exists()) {
          await Directory(targetDir).create(recursive: true);
        }
      }

      // Close and delete existing
      await _closeOpenDb();
      if (await dbFile.exists()) await dbFile.delete();
      await File(sourcePath).copy(dbPath);
      await reopen();
      return true;
    } catch (e) {
      print('Import error: $e');
      return false;
    }
  }

  static Future<void> _closeOpenDb() async {
    // Implement logic to close any open Database instance if needed
  }
}
