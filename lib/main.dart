import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import 'providers/theme_provider.dart';
import 'providers/bottom_navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/info_provider.dart';
import 'providers/notification_provider.dart';

import 'widgets/drawer_menu.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/journal/journal_screen.dart';
import 'screens/journal/add_journal_screen.dart';
import 'screens/account/account_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/user_settings.dart';
import 'screens/settings/company_info.dart';
import 'screens/notifications_screen.dart';
import 'screens/reminders/reminders_screen.dart';

import 'database/user_dao.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Load user settings
  final settingsProvider = SettingsProvider();
  await settingsProvider.initializeSettings();

  // 2) Open your app database
  final db = await DatabaseHelper().database;
  final userDao = UserDao(db);

  // 3) Check login state
  final loggedIn = await userDao.isLoggedIn();
  final initialRoute = loggedIn ? '/home' : '/login';

  // 4) Launch the app with a dynamic initialRoute
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(settingsProvider)),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => BottomNavigationProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => InfoProvider()),
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
      home: const BottomNavigationApp(),
      initialRoute: initialRoute,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const BottomNavigationApp(),
        '/journal/add': (_) => const AddJournalScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/user_settings': (_) => const UserSettingsScreen(),
        '/company_info': (_) => const CompanyInfoScreen(),
        '/notifications': (_) => NotificationsScreen(),
        '/reminders': (_) => RemindersScreen(),
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
            icon: const Icon(Icons.dashboard),
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
