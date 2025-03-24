import 'package:flutter/material.dart';
import '../screens/settings/settings_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../database/database_helper.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'بیزنیزهاب',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('تنظیمات'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('کمک'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Navigate to the Help screen (if needed)
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('درباره'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Navigate to the About screen (if needed)
            },
          ),
          ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('قفل'),
            onTap: () async {
              Navigator.pop(context); // Close the drawer
              // Handle logout logic
              await _handleLogout(context);
            },
          ),
          SwitchListTile(
            title: Text('حالت تاریک'),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(); // Toggle theme
            },
          ),
        ],
      ),
    );
  }

  // Handle logout logic
  Future<void> _handleLogout(BuildContext context) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.logoutUser(); // Update is_logged_in to false

    // Navigate to the login screen or perform other actions
    Navigator.pushReplacementNamed(
        context, '/login'); // Replace with your login route
  }
}
