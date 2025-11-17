import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'db_export_import.dart';
import 'db_init.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class DatabaseHelper {
  static const _databaseName = 'BusinessHubProDB.db';
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String dbPath;

      if (Platform.isWindows) {
        // Get the directory where the executable is located
        final exeDir = File(Platform.resolvedExecutable).parent;
        
        // Create a Database subdirectory
        final dbDir = Directory(join(exeDir.path, 'Database'));
        if (!await dbDir.exists()) {
          await dbDir.create(recursive: true);
        }
        
        // Create the database file path in the Database directory
        dbPath = join(dbDir.path, _databaseName);
      } else {
        // For other platforms, use the default database path
        dbPath = join(await getDatabasesPath(), _databaseName);
      }

      final db = await openDatabase(
        dbPath,
        version: 1,
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await DbInit.createTables(db);
          await DbInit.seedDefaults(db);
        },
        onOpen: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );

      return db;
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('Database connection closed');
    }
  }

  // Expose export/import utilities
  Future<bool> exportTo(String destinationPath) =>
      DbExportImport.exportDatabase(destinationPath, getDatabasePath);

  Future<bool> importFrom(String sourcePath) =>
      DbExportImport.importDatabase(sourcePath, getDatabasePath, _reopen);

  Future<void> _reopen() async {
    _database = null;
    await database;
  }

  /// Helper to get the database file path
  Future<String> getDatabasePath() async {
    if (Platform.isWindows) {
      final appDir = await getApplicationDocumentsDirectory();
      return join(appDir.path, 'BusinessHubPro', _databaseName);
    }
    return join(await getDatabasesPath(), _databaseName);
  }

  /// Returns a list of distinct currencies used in journal entries.
  Future<List<String>> getDistinctCurrencies() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT currency FROM account_details ORDER BY currency',
    );
    return result.map((row) => row['currency'] as String).toList();
  }
}
