import 'package:flutter/material.dart';
import '../database/settings_db.dart';

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

  Future<void> _loadSettings() async {
    _defaultCurrency =
        await SettingsDBHelper().getSetting('default_currency') ?? 'USD';
    _themeMode = await SettingsDBHelper().getSetting('theme_mode') ?? 'light';
    _appLanguage = await SettingsDBHelper().getSetting('app_language') ?? 'en';
    _defaultTransaction =
        await SettingsDBHelper().getSetting('default_transaction') ?? 'credit';

    notifyListeners(); // Update UI when settings change
  }

  Future<void> setSetting(String key, String value) async {
    await SettingsDBHelper().saveSetting(key, value);
    await _loadSettings(); // Refresh after updating
  }

  Future<void> initializeSettings() async {
    await _loadSettings();
  }
}
