import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'db_export_import.dart';
import 'db_init.dart';

class DatabaseHelper {
  static const _databaseName = 'BusinessHub.db';
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
    final path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onCreate: onCreate,
    );
  }

  Future<void> onCreate(Database db, int version) async {
    await DbInit.createTables(db);
    await DbInit.seedDefaults(db);
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
