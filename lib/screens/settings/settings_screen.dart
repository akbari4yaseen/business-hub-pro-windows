import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تنظیمات',
        ),
        backgroundColor: themeProvider.appBarBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.appBarTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildSettingsOption(
                    context,
                    icon: Icons.lock,
                    text: 'رمز عبور',
                    onTap: () => Navigator.pushNamed(context, '/user_settings'),
                  ),
                  _buildSettingsOption(
                    context,
                    icon: Icons.currency_exchange,
                    text: 'ارز و واحدات',
                    onTap: () =>
                        Navigator.pushNamed(context, '/currency_settings'),
                  ),
                  _buildSettingsOption(
                    context,
                    icon: Icons.filter_alt,
                    text: 'فیلترهای پیش فرض',
                    onTap: () =>
                        Navigator.pushNamed(context, '/default_filters'),
                  ),
                  _buildSettingsOption(
                    context,
                    icon: Icons.business,
                    text: 'معلومات شرکت',
                    onTap: () => Navigator.pushNamed(context, '/company_info'),
                  ),
                  _buildThemeSwitch(context, themeProvider),
                  _buildSettingsOption(
                    context,
                    icon: Icons.logout,
                    text: 'خارج شدن',
                    color: Colors.red,
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(BuildContext context,
      {required IconData icon,
      required String text,
      required VoidCallback onTap,
      Color color = Colors.black}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(text,
            style: TextStyle(
              color: color,
              fontSize: 16,
            )),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildThemeSwitch(BuildContext context, ThemeProvider themeProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: themeProvider.isDarkMode
              ? const Icon(Icons.dark_mode,
                  key: ValueKey('dark_mode'), size: 28, color: Colors.amber)
              : const Icon(Icons.light_mode,
                  key: ValueKey('light_mode'), size: 28, color: Colors.blue),
        ),
        title: Text(
          'حالت ${themeProvider.isDarkMode ? "تاریک" : "روشن"}',
          style: TextStyle(
              fontSize: 16,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black),
        ),
        trailing: Switch.adaptive(
          value: themeProvider.isDarkMode,
          activeColor: Colors.amber,
          inactiveThumbColor: Colors.blue,
          onChanged: (value) => themeProvider.toggleTheme(),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    // Handle logout logic here
    Navigator.pushReplacementNamed(context, '/login');
  }
}
