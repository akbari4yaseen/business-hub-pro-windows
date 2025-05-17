import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/help_screen.dart';
import '../screens/about_screen.dart';
import '../database/database_helper.dart';
import '../database/user_dao.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({Key? key}) : super(key: key);

  static const _iconSize = 24.0;
  static const _headerHeight = 180.0;
  static const _padding = EdgeInsets.symmetric(horizontal: 16);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface;
    final iconColor = scheme.onSurfaceVariant;

    final menuItems = <_MenuItem>[
      _MenuItem(
        icon: Icons.inventory_2_outlined,
        title: 'Inventory',
        onTap: () => Navigator.of(context).pushNamed('/inventory'),
      ),
      _MenuItem(
        icon: Icons.receipt_long_outlined,
        title: 'Invoices',
        onTap: () => Navigator.of(context).pushNamed('/invoices'),
      ),
      _MenuItem(
        icon: Icons.settings_outlined,
        title: loc.settings,
        onTap: () => _goTo(context, const SettingsScreen()),
      ),
      _MenuItem(
        icon: Icons.help_outline,
        title: loc.help,
        onTap: () => _goTo(context, const HelpScreen()),
      ),
      _MenuItem(
        icon: Icons.info_outline,
        title: loc.about,
        onTap: () => _goTo(context, const AboutScreen()),
      ),
    ];

    return Drawer(
      child: SafeArea(
        // allow content to bleed into the status‐bar/notch area
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER in "unsafe" area now ---
            Container(
              height: _headerHeight,
              color: scheme.primary,
              padding: _padding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/app_logo_white.png',
                      height: 64,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),

            // --- REST OF MENU (still respects bottom safe area) ---
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: menuItems.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: scheme.surfaceContainerHigh),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return ListTile(
                    leading: Icon(item.icon, size: _iconSize, color: iconColor),
                    title: Text(item.title, style: TextStyle(color: textColor)),
                    contentPadding: _padding,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    hoverColor: scheme.primary.withValues(alpha: 0.1),
                    onTap: () {
                      Navigator.pop(context);
                      item.onTap();
                    },
                  );
                },
              ),
            ),

            Divider(height: 1, color: scheme.surfaceContainerHigh),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading:
                    Icon(Icons.logout, size: _iconSize, color: scheme.error),
                title: Text(loc.logout, style: TextStyle(color: scheme.error)),
                contentPadding: _padding,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                hoverColor: scheme.error.withValues(alpha: 0.1),
                onTap: () {
                  Navigator.pop(context);
                  _handleLogout(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon, required this.title, required this.onTap});
}

Future<void> _handleLogout(BuildContext context) async {
  final db = await DatabaseHelper().database;
  await UserDao(db).logout();
  Navigator.pushReplacementNamed(context, '/login');
}
