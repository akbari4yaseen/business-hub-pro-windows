import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../themes/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false; // Stores the current theme mode

  // Getter to check if dark mode is enabled
  bool get isDarkMode => _isDarkMode;

  // Returns the appropriate theme based on the current mode
  ThemeData get currentTheme =>
      _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  // Bottom navigation bar colors
  Color get bottomNavBackgroundColor =>
      _isDarkMode ? Colors.grey[900]! : Colors.white;
  Color get bottomNavSelectedItemColor =>
      _isDarkMode ? Colors.white : Colors.blue;
  Color get bottomNavUnselectedItemColor =>
      _isDarkMode ? Colors.grey : Colors.black87.withOpacity(0.7);

  // AppBar Colors
  Color get appBarTextColor => _isDarkMode ? Colors.white : Colors.grey[900]!;
  Color get appBarBackgroundColor =>
      _isDarkMode ? Colors.grey[900]! : Colors.white;

  // System navigation bar color (used for Android system UI customization)
  Color get systemNavBarColor => _isDarkMode ? Colors.grey[900]! : Colors.white;

  // Toggles between dark and light mode
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    updateSystemNavigationBarColor(); // Update system UI colors accordingly
    notifyListeners(); // Notify all listeners about the theme change
  }

  // Updates the system navigation bar color to match the theme
  void updateSystemNavigationBarColor() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: systemNavBarColor, // Change the nav bar color
        systemNavigationBarIconBrightness: _isDarkMode
            ? Brightness.light
            : Brightness.dark, // Adjust icon brightness
      ),
    );
  }
}
