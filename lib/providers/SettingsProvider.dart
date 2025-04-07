import 'package:flutter/material.dart';
import '../database/settings_db.dart';

class SettingsProvider with ChangeNotifier {
  String _defaultCurrency = 'USD';
  String _themeMode = 'light';
  String _appLanguage = 'en';
  String _defaultTransaction = 'credit';

  String get defaultCurrency => _defaultCurrency;
  String get themeMode => _themeMode;
  String get appLanguage => _appLanguage;
  String get defaultTransaction => _defaultTransaction;

  Future<void> _loadSettings() async {
    _defaultCurrency = await SettingsDBHelper().getSetting('default_currency') ?? 'USD';
    _themeMode = await SettingsDBHelper().getSetting('theme_mode') ?? 'light';
    _appLanguage = await SettingsDBHelper().getSetting('app_language') ?? 'en';
    _defaultTransaction = await SettingsDBHelper().getSetting('default_transaction') ?? 'credit';

    notifyListeners(); // Update UI when settings change
  }

  Future<void> initializeSettings() async {
    await _loadSettings();
  }
}
