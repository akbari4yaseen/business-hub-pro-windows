import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

// Bottom navigation bar colors
  Color get bottomNavBackgroundColor =>
      _isDarkMode ? Colors.grey[900]! : Colors.white;
  Color get bottomNavSelectedItemColor =>
      _isDarkMode ? Colors.white : Colors.blue;
  Color get bottomNavUnselectedItemColor =>
      _isDarkMode ? Colors.grey : Colors.black87.withOpacity(0.7);

  Color get appBarTextColor => _isDarkMode ? Colors.white : Colors.grey[900]!;
  Color get appBarBackgroundColor =>
      _isDarkMode ? Colors.grey[900]! : Colors.white;

  // System navigation bar color
  Color get systemNavBarColor => _isDarkMode ? Colors.grey[900]! : Colors.white;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    updateSystemNavigationBarColor(); // Update system navigation bar color
    notifyListeners();
  }

  void updateSystemNavigationBarColor() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor:
            systemNavBarColor, // Set system navigation bar color
        systemNavigationBarIconBrightness: _isDarkMode
            ? Brightness.light
            : Brightness.dark, // Set icon brightness
      ),
    );
  }

  static final ThemeData _lightTheme = ThemeData(
      primarySwatch: Colors.blue,
      cardTheme: CardTheme(color: Colors.white),
      brightness: Brightness.light,
      fontFamily: "Vazir",
      scaffoldBackgroundColor: Colors.white70,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          splashColor: Colors.blue[900],
          hoverColor: Colors.blue[300]),
      tabBarTheme: TabBarTheme(
        labelColor: Colors.blue,
        indicatorColor: Colors.blue,
      ),
      appBarTheme: AppBarTheme(
        color: Colors.white,
        iconTheme: IconThemeData(color: Colors.grey[900]),
        titleTextStyle: TextStyle(
            color: Colors.grey[900], fontFamily: "IRANSans", fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              elevation: WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(Colors.blue),
              foregroundColor: WidgetStatePropertyAll(Colors.white),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)))))));

  static final ThemeData _darkTheme = ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      fontFamily: "Vazir",
      tabBarTheme: TabBarTheme(
        labelColor: Colors.blue,
        indicatorColor: Colors.blue,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          splashColor: Colors.blue[900],
          hoverColor: Colors.blue[300]),
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        color: Colors.grey[900],
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
            color: Colors.white, fontFamily: "IRANSans", fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              elevation: WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(Colors.blue),
              foregroundColor: WidgetStatePropertyAll(Colors.white),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)))))));
}
