import 'package:flutter/material.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/about_screen.dart';
import '../database/database_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
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
                  localizations.appName,
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
                  title: localizations.settings,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                _buildListTile(
                  context,
                  icon: Icons.help_outline,
                  title: localizations.help,
                  onTap: () {
                    // TODO: Navigate to Help screen
                  },
                ),
                _buildListTile(
                  context,
                  icon: Icons.info_outline,
                  title: localizations.about,
                  onTap: () {
                    Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const AboutScreen()),
);
                  },
                ),
                const Divider(),
                _buildListTile(
                  context,
                  icon: Icons.logout,
                  title: localizations.logout,
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

  Widget _buildListTile(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
            color: color ?? Theme.of(context).textTheme.bodyLarge?.color),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
    );
  }

  void _handleLogout(BuildContext context) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.logoutUser();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
