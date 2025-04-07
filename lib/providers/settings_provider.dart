import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SettingsProvider with ChangeNotifier {
  String _defaultCurrency = 'AFN';
  String _themeMode = 'light';
  String _appLanguage = 'fa';
  String _defaultTransaction = 'debit';
  String _defaultTrack = 'notTreasure';

  String get defaultCurrency => _defaultCurrency;
  String get themeMode => _themeMode;
  String get appLanguage => _appLanguage;
  String get defaultTransaction => _defaultTransaction;
  String get defaultTrack => _defaultTrack;

  // Available options
  final List<String> availableCurrencies = ['AFN', 'USD', 'EUR'];
  final List<String> availableLanguages = ['fa', 'en'];
  final List<String> availableTransactionTypes = ['credit', 'debit'];
  final List<String> availableTracks = ['treasure', 'notTreasure'];

  Future<Database> get database async {
    return openDatabase(
      join(await getDatabasesPath(), 'app_settings.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE settings (id INTEGER PRIMARY KEY, key TEXT UNIQUE, value TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> _loadSettings() async {
    _defaultCurrency = await _getSetting('default_currency') ?? 'AFN';
    _themeMode = await _getSetting('theme_mode') ?? 'light';
    _appLanguage = await _getSetting('app_language') ?? 'fa';
    _defaultTransaction = await _getSetting('default_transaction') ?? 'debit';
    _defaultTrack = await _getSetting('default_track') ?? 'notTreasure';

    notifyListeners(); // Update UI when settings change
  }

  Future<String?> _getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return result.isNotEmpty ? result.first['value'] as String : null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _loadSettings(); // Refresh after updating
  }

  Future<void> initializeSettings() async {
    await _loadSettings();
  }
}
