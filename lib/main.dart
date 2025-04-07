import 'screens/settings/company_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/bottom_navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/account/account_screen.dart';
import 'screens/home_screen.dart';
import 'screens/journal/journal_screen.dart';
import 'screens/journal/add_journal_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/user_settings.dart';
import 'screens/login_screen.dart';
import 'widgets/drawer_menu.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'providers/info_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BottomNavigationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => InfoProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Initialize system navigation bar color
    themeProvider.updateSystemNavigationBarColor();

    return MaterialApp(
      theme: themeProvider.currentTheme, // Use the current theme
      home: const BottomNavigationApp(),

      // initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const BottomNavigationApp(),
        '/journal': (context) => const JournalScreen(),
        '/journal/add': (context) => const AddJournalScreen(),
        '/accounts': (context) => const AccountScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/settings': (context) => SettingsScreen(),
        '/user_settings': (context) => UserSettingsScreen(),
        '/company_info': (context) => CompanyInfoScreen(),
      },
      debugShowCheckedModeBanner: false, // Disable debug banner in release mode
      localizationsDelegates: const [
        AppLocalizations.delegate,
        DariMaterialLocalizations.delegate,
        DariCupertinoLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("fa", "AF"),
        Locale("en", "US"),
      ],
      locale: const Locale("fa", "AF"),
    );
  }
}

class BottomNavigationApp extends StatefulWidget {
  const BottomNavigationApp({super.key});

  @override
  _BottomNavigationAppState createState() => _BottomNavigationAppState();
}

class _BottomNavigationAppState extends State<BottomNavigationApp> {
  final List<Widget> _screens = const [
    HomeScreen(),
    JournalScreen(),
    AccountScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bottomNavProvider = Provider.of<BottomNavigationProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appTitle, style: TextStyle(fontSize: 24)),
      ),
      body: _screens[bottomNavProvider.currentIndex], // Controlled by provider
      drawer: const DrawerMenu(),
      drawerEnableOpenDragGesture: false,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomNavProvider.currentIndex,
        onTap: (index) {
          bottomNavProvider.updateIndex(index); // Update provider state
        },
        backgroundColor: themeProvider.bottomNavBackgroundColor,
        selectedItemColor: themeProvider.bottomNavSelectedItemColor,
        unselectedItemColor: themeProvider.bottomNavUnselectedItemColor,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: localizations.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: localizations.journal,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.supervisor_account_outlined),
            label: localizations.accounts,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined_rounded),
            label: localizations.reports,
          ),
        ],
      ),
    );
  }
}
