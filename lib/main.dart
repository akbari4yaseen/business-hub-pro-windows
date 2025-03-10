import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/reports_screen.dart';
import 'screens/account_screen.dart';
import 'screens/home_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/drawer_menu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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
        '/accounts': (context) => const AccountScreen(),
        '/reports': (context) => const ReportsScreen(),
      },
      debugShowCheckedModeBanner: false, // Disable debug banner in release mode
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("fa", "IR"),
        Locale("en", "US"),
      ],
      locale: const Locale("fa", "IR"),
    );
  }
}

class BottomNavigationApp extends StatefulWidget {
  const BottomNavigationApp({super.key});

  @override
  _BottomNavigationAppState createState() => _BottomNavigationAppState();
}

class _BottomNavigationAppState extends State<BottomNavigationApp> {
  int _currentIndex = 0;

  // List of screens corresponding to each navigation item
  final List<Widget> _screens = const [
    HomeScreen(),
    JournalScreen(),
    AccountScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.appTitle,
          style: TextStyle(
            fontFamily: "IRANSans",
            fontSize: 24,
          ), // Use a fixed color or theme-based color
        ),
      ),
      body: _screens[_currentIndex], // Display the selected screen
      drawer: const DrawerMenu(),
      drawerEnableOpenDragGesture: false,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the selected index
          });
        },
        backgroundColor: themeProvider.bottomNavBackgroundColor,
        selectedItemColor: themeProvider.bottomNavSelectedItemColor,
        unselectedItemColor: themeProvider.bottomNavUnselectedItemColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'صفحه اصلی',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'روزنامچه',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.supervisor_account_outlined),
            label: 'حساب‌ها',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined_rounded),
            label: 'گزارشات',
          ),
        ],
      ),
    );
  }
}
