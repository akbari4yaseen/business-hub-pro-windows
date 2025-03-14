import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue,
    cardTheme: CardTheme(color: Colors.white),
    brightness: Brightness.light,
    fontFamily: "Vazir",
    scaffoldBackgroundColor: Colors.white70,
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.white),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      splashColor: Colors.blue[900],
      hoverColor: Colors.blue[300],
    ),
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
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6))),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue,
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
      hoverColor: Colors.blue[300],
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      color: Colors.grey[900],
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle:
          TextStyle(color: Colors.white, fontFamily: "IRANSans", fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(Colors.blue),
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6))),
        ),
      ),
    ),
  );
}
