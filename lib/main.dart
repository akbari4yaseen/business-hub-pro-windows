// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'providers/theme_provider.dart';
import 'providers/bottom_navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/info_provider.dart';

import 'widgets/drawer_menu.dart';

import 'screens/home_screen.dart';
import 'screens/journal/journal_screen.dart';
import 'screens/journal/add_journal_screen.dart';
import 'screens/account/account_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/user_settings.dart';
import 'screens/settings/company_info.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsProvider = SettingsProvider();
  await settingsProvider.initializeSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(settingsProvider)),
        ChangeNotifierProvider(create: (_) => BottomNavigationProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => InfoProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
      home: const BottomNavigationApp(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const BottomNavigationApp(),
        '/journal/add': (_) => const AddJournalScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/user_settings': (_) => const UserSettingsScreen(),
        '/company_info': (_) => const CompanyInfoScreen(),
      },
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        DariMaterialLocalizations.delegate,
        DariCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa', 'AF'),
        Locale('en', 'US'),
      ],
      locale: Locale(
        settingsProvider.appLanguage,
        settingsProvider.appLanguage == 'fa' ? 'AF' : 'US',
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bottomNavProvider = Provider.of<BottomNavigationProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    final screens = <Widget>[
      HomeScreen(openDrawer: _openDrawer),
      JournalScreen(openDrawer: _openDrawer),
      AccountScreen(openDrawer: _openDrawer),
      ReportsScreen(openDrawer: _openDrawer),
    ];

    return Scaffold(
      key: _scaffoldKey,
      // appBar: AppBar(
      //   title:
      //       Text(localizations.appTitle, style: const TextStyle(fontSize: 24)),
      //   leading: IconButton(
      //     icon: const Icon(Icons.menu),
      //     onPressed: _openDrawer,
      //   ),
      // ),
      drawer: const DrawerMenu(),
      drawerEnableOpenDragGesture: false,
      body: screens[bottomNavProvider.currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomNavProvider.currentIndex,
        onTap: (i) => bottomNavProvider.updateIndex(i),
        backgroundColor: themeProvider.bottomNavBackgroundColor,
        selectedItemColor: themeProvider.bottomNavSelectedItemColor,
        unselectedItemColor: themeProvider.bottomNavUnselectedItemColor,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: localizations.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_outlined),
            label: localizations.journal,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.supervisor_account_outlined),
            label: localizations.accounts,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.insert_chart_outlined_rounded),
            label: localizations.reports,
          ),
        ],
      ),
    );
  }
}

// Note: Removed const constructors with null openDrawer and updated routes accordingly.
