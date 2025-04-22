import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/bottom_navigation_provider.dart';
import '../database/account_db.dart';
import '../database/database_helper.dart';
import '../database/user_dao.dart';
import '../widgets/backup_restore_card.dart';
import '../widgets/recent_transaction_list.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback openDrawer;
  const HomeScreen({Key? key, required this.openDrawer}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, int>> _statsFuture;
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = AccountDBHelper().getAccountCounts();
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
            const SizedBox(height: 8),
            AccountStateSection(future: _statsFuture),
            const SizedBox(height: 16),
            ActionButtonsSection(loc: loc),
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

class AccountStateSection extends StatelessWidget {
  final Future<Map<String, int>> future;
  const AccountStateSection({Key? key, required this.future}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, int>>(
      future: future,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text(loc.statsLoadError));
        }
        final data = snapshot.data!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AccountCard(
              title: loc.allAccounts,
              value: _formatCompact(data['total_accounts']!),
              icon: FontAwesomeIcons.users,
            ),
            _AccountCard(
              title: loc.activeAccountsShort,
              value: _formatCompact(data['activated_accounts']!),
              icon: FontAwesomeIcons.userCheck,
            ),
            _AccountCard(
              title: loc.deactivatedAccountsShort,
              value: _formatCompact(data['deactivated_accounts']!),
              icon: FontAwesomeIcons.userSlash,
            ),
          ],
        );
      },
    );
  }

  static String _formatCompact(int number) =>
      NumberFormat.compact().format(number);
}

class _AccountCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _AccountCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 22, color: Colors.blueAccent),
              const SizedBox(height: 8),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionButtonsSection extends StatelessWidget {
  final AppLocalizations loc;
  const ActionButtonsSection({Key? key, required this.loc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<BottomNavigationProvider>(context, listen: false);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          label: loc.newTransaction,
          icon: Icons.add,
          onPressed: () => Navigator.pushNamed(context, '/journal/add'),
        ),
        _ActionButton(
          label: loc.accounts,
          icon: Icons.supervisor_account_outlined,
          onPressed: () => nav.updateIndex(2),
        ),
        _ActionButton(
          label: loc.reports,
          icon: Icons.bar_chart,
          onPressed: () => nav.updateIndex(3),
        ),
        _ActionButton(
          label: loc.settings,
          icon: Icons.settings,
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
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
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
