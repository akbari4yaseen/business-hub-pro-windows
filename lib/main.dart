import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import 'providers/theme_provider.dart';
import 'providers/bottom_navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/info_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/account_provider.dart';

import 'widgets/windows_drawer_menu.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/journal/journal_screen.dart';
import 'screens/account/account_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/user_settings.dart';
import 'screens/settings/company_info.dart';
import 'screens/notifications_screen.dart';
import 'screens/reminders/reminders_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/invoice/invoice_screen.dart';
import 'screens/help_screen.dart';
import 'screens/about_screen.dart';
import 'database/user_dao.dart';
import 'database/database_helper.dart';

// Global error handler
void _handleFlutterError(FlutterErrorDetails details) {
  FlutterError.dumpErrorToConsole(details);
  debugPrint('Flutter error caught by global handler: ${details.exception}');
}

void main() async {
  // Set up global error handling
  FlutterError.onError = _handleFlutterError;

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite_ffi for Windows
  if (Platform.isWindows) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize dates
  await initializeDateFormatting();

  // 1) Load user settings and info
  final settingsProvider = SettingsProvider();
  final infoProvider = InfoProvider();

  await settingsProvider.initializeSettings();
  await infoProvider.loadInfo();

  // 2) Open your app database
  final db = await DatabaseHelper().database;
  final userDao = UserDao(db);

  // 3) Check login state
  final loggedIn = await userDao.isLoggedIn();
  final initialRoute = loggedIn ? '/home' : '/login';

  // Initialize providers
  final inventoryProvider = InventoryProvider();
  try {
    await inventoryProvider.initialize();
  } catch (e) {
    debugPrint('Error initializing inventory provider: $e');
  }

  // 4) Launch the app with a dynamic initialRoute
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(settingsProvider)),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => BottomNavigationProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => InfoProvider()),
        ChangeNotifierProvider.value(value: inventoryProvider),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(
            create: (context) =>
                InvoiceProvider(context.read<InventoryProvider>())),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    themeProvider.updateSystemNavigationBarColor();

    return MaterialApp(
      theme: themeProvider.currentTheme,
      themeMode: settingsProvider.themeMode == 'light'
          ? ThemeMode.light
          : ThemeMode.dark,
      initialRoute: initialRoute,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const BottomNavigationApp(),
        '/accounts': (_) => const AccountScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/user_settings': (_) => const UserSettingsScreen(),
        '/company_info': (_) => const CompanyInfoScreen(),
        '/notifications': (_) => NotificationsScreen(),
        '/reminders': (_) => RemindersScreen(),
        '/inventory': (_) => const InventoryScreen(),
        '/reports': (_) => const ReportsScreen(),
        '/help': (_) => const HelpScreen(),
        '/about': (_) => const AboutScreen(),
      },

      // Error handling for the entire app
      builder: (context, child) {
        // Add error boundary for entire app
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Material(
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.summary.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (route) => false);
                      },
                      child: const Text('Return to Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        };

        // Add memory optimizations
        return MediaQuery(
          // Restrict image cache size
          data: MediaQuery.of(context).copyWith(
              devicePixelRatio: 1.0 // Reduce memory pressure for images
              ),
          child: child!,
        );
      },

      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        DariMaterialLocalizations.delegate,
        DariCupertinoLocalizations.delegate,
        PashtoMaterialLocalizations.delegate,
        PashtoCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa', 'AF'),
        Locale('ps', 'AF'),
        Locale('en', 'US'),
      ],
      locale: Locale(
        settingsProvider.appLanguage,
        settingsProvider.appLanguage == 'en' ? 'US' : 'AF',
      ),
    );
  }
}

class BottomNavigationApp extends StatefulWidget {
  const BottomNavigationApp({Key? key}) : super(key: key);

  @override
  _BottomNavigationAppState createState() => _BottomNavigationAppState();
}

class _BottomNavigationAppState extends State<BottomNavigationApp> {
  @override
  Widget build(BuildContext context) {
    final bottomNavProvider = Provider.of<BottomNavigationProvider>(context);

    final screens = <Widget>[
      const HomeScreen(),
      const JournalScreen(),
      const AccountScreen(),
      const InventoryScreen(),
      const InvoiceScreen(),
      const ReportsScreen(),
      const RemindersScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          const WindowsDrawerMenu(),

          // Main content
          Expanded(
            child: screens[bottomNavProvider.currentIndex],
          ),
        ],
      ),
    );
  }
}
