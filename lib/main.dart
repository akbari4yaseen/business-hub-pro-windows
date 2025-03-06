import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/profile_screen.dart';
import 'screens/school_screen.dart';
import 'screens/home_screen.dart';
import 'screens/journal_screen.dart';
import 'widgets/drawer_menu.dart';

void main() {
  runApp(MyApp());
  // Set status bar color here
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.blue, // Set your desired status bar color here
      statusBarBrightness:
          Brightness.light, // For iOS: Light or Dark status bar text
      statusBarIconBrightness:
          Brightness.light, // For Android: Light or Dark icons
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '#BusinessHub',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: "Vazir"),
      home: BottomNavigationApp(),
      debugShowCheckedModeBanner: true,
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("fa", "IR"),
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
  final List<Widget> _screens = [
    HomeScreen(),
    const JournalScreen(),
    SchoolScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('#بیزنیزهاب'),
      ),
      body: _screens[_currentIndex], // Display the selected screen
      drawer: DrawerMenu(),
      drawerEnableOpenDragGesture: false,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,

        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the selected index
          });
        },
        backgroundColor: Colors.white, // Background color of the bottom nav bar
        selectedItemColor: Colors.blue, // Color of the selected icon and text
        unselectedItemColor:
            Colors.black87.withOpacity(0.6), // Color of unselected items
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
