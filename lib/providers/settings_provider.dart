import '../constants/currencies.dart';
import 'package:flutter/material.dart';
import '../database/settings_db.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsDBHelper _dbHelper = SettingsDBHelper();

  // Defaults
  String _defaultCurrency = 'AFN';
  String _themeMode = 'light';
  String _appLanguage = 'fa';
  String _defaultTransaction = 'debit';
  String _defaultTrackOption = 'noTreasure';
  int _defaultTrack = 2;
  int _defaultInactivityDays = 30;
  bool _defaultUseFingerprint = false;

  // Getters
  String get defaultCurrency => _defaultCurrency;
  String get themeMode => _themeMode;
  String get appLanguage => _appLanguage;
  String get defaultTransaction => _defaultTransaction;
  String get defaultTrackOption => _defaultTrackOption;
  int get defaultTrack => _defaultTrack;
  int get inactivityDays => _defaultInactivityDays;
  bool get useFingerprint => _defaultUseFingerprint;

  // Available options
  static const List<String> availableCurrencies = currencies;
  static const List<String> availableLanguages = ['fa', 'ps', 'en'];
  static const List<String> availableTransactionTypes = ['credit', 'debit'];
  static const List<String> availableTrackOptions = ['treasure', 'noTreasure'];
  static const List<int> availableTracks = [1, 2];
  static const availableInactivityDays = ['7', '15', '30', '60', '90'];

  // Load all settings at once
  Future<void> _loadSettings() async {
    final settings = await _dbHelper.getAllSettings();

    _defaultCurrency = settings['default_currency'] ?? _defaultCurrency;
    _themeMode = settings['theme_mode'] ?? _themeMode;
    _appLanguage = settings['app_language'] ?? _appLanguage;
    _defaultTransaction =
        settings['default_transaction'] ?? _defaultTransaction;
    _defaultTrackOption =
        settings['default_track_option'] ?? _defaultTrackOption;
    _defaultTrack =
        _parseIntOrDefault(settings['default_track'], _defaultTrack);
    _defaultInactivityDays = int.parse(
        settings['inactivity_days'] ?? _defaultInactivityDays.toString());
    _defaultUseFingerprint = bool.parse(
        (settings['use_fingerprint'] ?? _defaultUseFingerprint).toString());

    notifyListeners();
  }

  Future<void> setSetting(String key, String value) async {
    await _dbHelper.saveSetting(key, value);
    await _loadSettings();
  }

  Future<void> initializeSettings() async {
    await _loadSettings();
  }

  int _parseIntOrDefault(String? value, int fallback) {
    return int.tryParse(value ?? '') ?? fallback;
  }
}
