import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'db_export_import.dart';
import 'db_init.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static const _databaseName = 'BusinessHubPro.db';
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
    debugPrint('Initializing database...');
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);
      debugPrint('Database path: $path');

      final db = await openDatabase(
        path,
        version: 1,
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          debugPrint('Creating database tables...');
          await DbInit.createTables(db);
          await DbInit.seedDefaults(db);
          debugPrint('Database tables created successfully');
        },
        onOpen: (Database db) async {
          debugPrint('Database opened');
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
      
      debugPrint('Database initialized successfully');
      return db;
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    if (_database != null) {
      debugPrint('Closing database connection...');
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
