import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SettingsDBHelper {
  static final SettingsDBHelper _instance = SettingsDBHelper._internal();

  factory SettingsDBHelper() {
    return _instance;
  }

  SettingsDBHelper._internal();

  Future<Database> get database async {
    return await DatabaseHelper().database;
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace, // Updates if exists
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return result.isNotEmpty ? result.first['value'] as String : null;
  }
}
