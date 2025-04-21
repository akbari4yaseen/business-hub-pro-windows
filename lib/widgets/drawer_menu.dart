import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../database/database_helper.dart';
import '../database/user_dao.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/help_screen.dart';
import '../screens/about_screen.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    "assets/images/app_logo_white.png",
                    height: 72,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  loc.appName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontFamily: "IRANSans",
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildListTile(
                  context,
                  icon: Icons.settings_outlined,
                  title: loc.settings,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
                _buildListTile(
                  context,
                  icon: Icons.help_outline,
                  title: loc.help,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelpScreen(),
                    ),
                  ),
                ),
                _buildListTile(
                  context,
                  icon: Icons.info_outline,
                  title: loc.about,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AboutScreen(),
                    ),
                  ),
                ),
                const Divider(),
                _buildListTile(
                  context,
                  icon: Icons.logout,
                  title: loc.logout,
                  color: Colors.red,
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final defaultColor = Theme.of(context).textTheme.bodyLarge?.color;
    return ListTile(
      leading: Icon(icon, color: color ?? defaultColor),
      title: Text(
        title,
        style: TextStyle(color: color ?? defaultColor),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Fetch DB and logout via UserDao
    final db = await DatabaseHelper().database;
    await UserDao(db).logout();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
