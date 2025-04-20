import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Colors.blue,
      onPrimary: Colors.white, // Ensures text on blue is readable
      secondary: const Color.fromARGB(255, 187, 222, 251),
      onSecondary: Colors.black87, // Ensures contrast on secondary color
      error: const Color.fromARGB(255, 239, 83, 80),
      onError: const Color.fromARGB(255, 183, 28, 28),
      surface: const Color.fromARGB(255, 255, 255, 255),
      onSurface: Colors.grey.shade800,
    ),
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue,
    cardTheme: CardTheme(color: Colors.white),
    brightness: Brightness.light,
    drawerTheme: DrawerThemeData(backgroundColor: Colors.white),
    fontFamily: "Vazir",
    scaffoldBackgroundColor: Colors.grey[100],
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
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.grey[900]),
      titleTextStyle: TextStyle(
        color: Colors.grey[900],
        fontFamily: "IRANSans",
        fontSize: 20,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(Colors.blue),
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: "Vazir",
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.blue,
      onPrimary: Colors.white,
      secondary: const Color.fromARGB(
          255, 40, 147, 235), // A lighter blue accent for dark mode
      onSecondary: Colors.white,
      error: const Color.fromRGBO(239, 83, 80, 1),
      onError: Colors.black,
      surface: Colors.grey.shade800,
      onSurface: Colors.white70,
    ),
    cardTheme: CardTheme(color: Colors.grey.shade800),
    drawerTheme:
        DrawerThemeData(backgroundColor: Color.fromRGBO(48, 48, 48, 1)),
    scaffoldBackgroundColor: Colors.grey.shade900,
    bottomSheetTheme:
        BottomSheetThemeData(backgroundColor: Color.fromRGBO(48, 48, 48, 1)),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.blue,
      indicatorColor: Colors.blue,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey.shade900,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontFamily: "IRANSans",
        fontSize: 20,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      splashColor: Colors.blue[900],
      hoverColor: Colors.blue[300],
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(Colors.blue),
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
      ),
    ),
  );
}
