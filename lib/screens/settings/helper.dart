import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "BusinessHub.db";
  static const _databaseVersion = 1;

  // Singleton instance
  static Database? _database;
  
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    // Your table creation code here
    // await db.execute('''
    //   CREATE TABLE your_table (
    //     id INTEGER PRIMARY KEY,
    //     name TEXT NOT NULL
    //   )
    // ''');
  }

  // Get the database path
  Future<String> getDatabasePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _databaseName);
  }

  // Export database to a file
  Future<bool> exportDatabase(String destinationPath) async {
    try {
      String dbPath = await getDatabasePath();
      File dbFile = File(dbPath);
      
      if (await dbFile.exists()) {
        await dbFile.copy(destinationPath);
        return true;
      }
      return false;
    } catch (e) {
      print("Export error: $e");
      return false;
    }
  }

  // Import database from a file
  Future<bool> importDatabase(String sourcePath) async {
    try {
      String dbPath = await getDatabasePath();
      File dbFile = File(dbPath);
      
      // Close the database if it's open
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Delete the existing database
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      
      // Copy the new database
      File sourceFile = File(sourcePath);
      await sourceFile.copy(dbPath);
      
      // Reopen the database
      _database = await _initDatabase();
      
      return true;
    } catch (e) {
      print("Import error: $e");
      return false;
    }
  }
}