import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../database/user_dao.dart';
import '../providers/theme_provider.dart';
import '../providers/bottom_navigation_provider.dart';

class WindowsDrawerMenu extends StatefulWidget {
  const WindowsDrawerMenu({Key? key}) : super(key: key);

  @override
  State<WindowsDrawerMenu> createState() => _WindowsDrawerMenuState();
}

class _WindowsDrawerMenuState extends State<WindowsDrawerMenu> {
  bool _isExpanded = true;
  static const double _collapsedWidth = 52;
  static const double _expandedWidth = 170;
  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 16.0);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final bottomNavProvider = context.watch<BottomNavigationProvider>();
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? _expandedWidth : _collapsedWidth,
      color: scheme.surface,
      child: Column(
        children: [
          _buildHeader(loc, scheme),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  icon: Icons.dashboard,
                  label: loc.home,
                  isSelected: bottomNavProvider.currentIndex == 0,
                  onTap: () => bottomNavProvider.updateIndex(0),
                  themeProvider: themeProvider,
                ),
                _buildNavItem(
                  icon: Icons.book_outlined,
                  label: loc.journal,
                  isSelected: bottomNavProvider.currentIndex == 1,
                  onTap: () => bottomNavProvider.updateIndex(1),
                  themeProvider: themeProvider,
                ),
                _buildNavItem(
                  icon: Icons.supervisor_account_outlined,
                  label: loc.accounts,
                  isSelected: bottomNavProvider.currentIndex == 2,
                  onTap: () => bottomNavProvider.updateIndex(2),
                  themeProvider: themeProvider,
                ),
                _buildNavItem(
                  icon: Icons.currency_exchange,
                  label: loc.exchange,
                  isSelected: bottomNavProvider.currentIndex == 3,
                  onTap: () => bottomNavProvider.updateIndex(3),
                  themeProvider: themeProvider,
                ),
                _buildNavItem(
                  icon: Icons.receipt_long_outlined,
                  label: loc.inventory,
                  isSelected: bottomNavProvider.currentIndex == 4,
                  onTap: () => bottomNavProvider.updateIndex(4),
                  themeProvider: themeProvider,
                ),
                _buildNavItem(
                  icon: Icons.shopping_cart_outlined,
                  label: loc.purchases,
                  isSelected: bottomNavProvider.currentIndex == 5,
                  onTap: () => bottomNavProvider.updateIndex(5),
                  themeProvider: themeProvider,
                ),
                _buildNavItem(
                  icon: Icons.inventory_2,
                  label: loc.sales,
                  isSelected: bottomNavProvider.currentIndex == 6,
                  onTap: () => bottomNavProvider.updateIndex(6),
                  themeProvider: themeProvider,
                ),
                _buildNavItem(
                  icon: Icons.bar_chart,
                  label: loc.reports,
                  isSelected: bottomNavProvider.currentIndex == 7,
                  onTap: () => bottomNavProvider.updateIndex(7),
                  themeProvider: themeProvider,
                ),
                _buildNavItem(
                  icon: Icons.alarm,
                  label: loc.reminders,
                  isSelected: bottomNavProvider.currentIndex == 8,
                  onTap: () => bottomNavProvider.updateIndex(8),
                  themeProvider: themeProvider,
                ),
                const Divider(height: 1),
                _buildNavItem(
                  icon: Icons.settings,
                  label: loc.settings,
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                  themeProvider: themeProvider,
                ),
                const Divider(height: 1),
                _buildLogoutItem(loc, scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc, ColorScheme scheme) {
    return Container(
      height: 60,
      padding:
          _isExpanded ? _padding : const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        mainAxisAlignment: _isExpanded
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.center,
        children: [
          if (_isExpanded)
            Row(
              children: [
                Image.asset('assets/images/app_logo.png', height: 32),
              ],
            ),
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.chevron_left : Icons.chevron_right,
              color: scheme.onSurface,
            ),
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? themeProvider.bottomNavSelectedItemColor
            : themeProvider.bottomNavUnselectedItemColor,
      ),
      title: _isExpanded ? Text(label) : null,
      selected: isSelected,
      selectedTileColor: Colors.blue,
      onTap: onTap,
      contentPadding:
          _isExpanded ? _padding : const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildLogoutItem(AppLocalizations loc, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: ListTile(
        leading: Icon(Icons.logout, color: scheme.error),
        title: _isExpanded
            ? Text(loc.logout, style: TextStyle(color: scheme.error))
            : null,
        onTap: () => _handleLogout(context),
        hoverColor: scheme.error.withOpacity(0.1),
        contentPadding:
            _isExpanded ? _padding : const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final db = await DatabaseHelper().database;
    await UserDao(db).logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }
}
