import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Colors.blue;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: const Color.fromARGB(255, 187, 206, 255),
      onSecondary: Colors.black87,
      error: const Color.fromARGB(255, 239, 83, 80),
      onError: const Color.fromARGB(255, 183, 28, 28),
      surface: const Color.fromARGB(255, 255, 255, 255),
      onSurface: Colors.grey.shade800,
    ),
    primarySwatch: MaterialColor(primaryColor.toARGB32(), {
      50: primaryColor.withValues(alpha: 0.1),
      100: primaryColor.withValues(alpha: 0.2),
      200: primaryColor.withValues(alpha: 0.3),
      300: primaryColor.withValues(alpha: 0.4),
      400: primaryColor.withValues(alpha: 0.5),
      500: primaryColor.withValues(alpha: 0.6),
      600: primaryColor.withValues(alpha: 0.7),
      700: primaryColor.withValues(alpha: 0.8),
      800: primaryColor.withValues(alpha: 0.9),
      900: primaryColor,
    }),
    primaryColor: primaryColor,
    cardTheme: CardTheme(color: Colors.white),
    brightness: Brightness.light,
    drawerTheme: DrawerThemeData(backgroundColor: Colors.white),
    fontFamily: "Vazir",
    scaffoldBackgroundColor: Colors.grey[100],
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.white),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      splashColor: primaryColor.withValues(alpha: 0.9),
      hoverColor: primaryColor.withValues(alpha: 0.3),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: primaryColor,
      indicatorColor: primaryColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.grey[900]),
      titleTextStyle: TextStyle(
        color: Colors.grey[900],
        fontFamily: "VazirBold",
        fontSize: 20,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(primaryColor),
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
    primarySwatch: MaterialColor(primaryColor.toARGB32(), {
      50: primaryColor.withValues(alpha: 0.1),
      100: primaryColor.withValues(alpha: 0.2),
      200: primaryColor.withValues(alpha: 0.3),
      300: primaryColor.withValues(alpha: 0.4),
      400: primaryColor.withValues(alpha: 0.5),
      500: primaryColor.withValues(alpha: 0.6),
      600: primaryColor.withValues(alpha: 0.7),
      700: primaryColor.withValues(alpha: 0.8),
      800: primaryColor.withValues(alpha: 0.9),
      900: primaryColor,
    }),
    primaryColor: primaryColor,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: const Color.fromARGB(255, 128, 200, 255),
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
      labelColor: primaryColor,
      indicatorColor: primaryColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey.shade900,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontFamily: "VazirBold",
        fontSize: 20,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      splashColor: primaryColor.withValues(alpha: 0.9),
      hoverColor: primaryColor.withValues(alpha: 0.3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(primaryColor),
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
