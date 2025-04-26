import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/bottom_navigation_provider.dart';
import '../database/account_db.dart';
import '../database/database_helper.dart';
import '../database/user_dao.dart';
import '../widgets/backup_restore_card.dart';
import '../widgets/recent_transaction_list.dart';
import '../widgets/account_type_chart.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback openDrawer;
  const HomeScreen({Key? key, required this.openDrawer}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = AccountDBHelper().getRecentTransactions(5);
  }

  Future<void> _handleLogout(BuildContext context) async {
    final db = await DatabaseHelper().database;
    await UserDao(db).logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final nav = Provider.of<BottomNavigationProvider>(context, listen: false);

    // Define all your actions here
    final actions = <_ActionData>[
      _ActionData(
        label: loc.newTransaction,
        icon: Icons.add,
        onPressed: () => Navigator.pushNamed(context, '/journal/add'),
      ),
      _ActionData(
        label: loc.accounts,
        icon: Icons.supervisor_account_outlined,
        onPressed: () => nav.updateIndex(2),
      ),
      _ActionData(
        label: loc.reports,
        icon: Icons.bar_chart,
        onPressed: () => nav.updateIndex(3),
      ),
      _ActionData(
        label: loc.settings,
        icon: Icons.settings,
        onPressed: () => Navigator.pushNamed(context, '/settings'),
      ),
      _ActionData(
        label: loc.reminders,
        icon: Icons.alarm,
        onPressed: () => Navigator.pushNamed(context, '/reminders'),
      ),
      // add more here as needed
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appName),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.openDrawer,
        ),
        actions: [_buildPopupMenu(context, loc)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AccountTypeChart(),
            const SizedBox(height: 16),
            ActionButtonsSection(actions: actions),
            const SizedBox(height: 16),
            const BackupRestoreCard(),
            const SizedBox(height: 20),
            Text(
              loc.recentTransactions,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            RecentTransactionList(
              transactionsFuture: _transactionsFuture,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, AppLocalizations loc) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'profile':
            Navigator.pushNamed(context, '/profile');
            break;
          case 'notifications':
            Navigator.pushNamed(context, '/notifications');
            break;
          case 'logout':
            _handleLogout(context);
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'profile', child: Text(loc.profile)),
        PopupMenuItem(value: 'notifications', child: Text(loc.notifications)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'logout', child: Text(loc.logout)),
      ],
    );
  }
}

// Data class for actions
class _ActionData {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  _ActionData({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

class ActionButtonsSection extends StatelessWidget {
  final List<_ActionData> actions;
  const ActionButtonsSection({Key? key, required this.actions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92, // enough room for FAB + label
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _ActionButton(
            label: action.label,
            icon: action.icon,
            onPressed: action.onPressed,
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: Colors.blueAccent,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        // Constrain the width so that long labels get ellipsized
        SizedBox(
          width: 70, // pick a width that fits your layout
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
