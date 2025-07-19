import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:badges/badges.dart' as badges;
import '../themes/app_theme.dart';

import '../providers/notification_provider.dart';
import '../database/account_db.dart';
import '../database/settings_db.dart';
import '../widgets/backup_card.dart';
import '../widgets/transaction/recent_transaction_list.dart';
import '../widgets/account/account_type_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = AccountDBHelper().getRecentTransactions(10);

    Future.microtask(() async {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.checkBackupNotifications(context);

      final intervalStr = await SettingsDBHelper().getSetting('inactivityDays');
      final days = int.tryParse(intervalStr ?? '30') ?? 30;

      context.read<NotificationProvider>().checkInactiveAccountNotifications(
            context,
            days: days,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Define all your actions here
    final actions = <_ActionData>[
      // _ActionData(
      //   label: loc.newTransaction,
      //   icon: Icons.add,
      //   onPressed: () => Navigator.pushNamed(context, '/journal/add'),
      // ),
      _ActionData(
        label: loc.accounts,
        icon: Icons.supervisor_account_outlined,
        onPressed: () => Navigator.pushNamed(context, '/accounts'),
      ),
      _ActionData(
        label: loc.reports,
        icon: Icons.bar_chart,
        onPressed: () => Navigator.pushNamed(context, '/reports'),
      ),
      _ActionData(
        label: loc.inventory,
        icon: Icons.inventory_2,
        onPressed: () => Navigator.pushNamed(context, '/inventory'),
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
      _ActionData(
        label: loc.help,
        icon: Icons.help_outline,
        onPressed: () => Navigator.pushNamed(context, '/help'),
      ),
      _ActionData(
        label: loc.about,
        icon: Icons.info_outline,
        onPressed: () => Navigator.pushNamed(context, '/about'),
      ),
      // add more here as needed
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appName),
        actions: [
          _buildNotificationIcon(context),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  flex: 2,
                  child: AccountTypeChart(),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: BackupCard(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ActionButtonsSection(actions: actions),
            const SizedBox(height: 16),
            RecentTransactionList(
              transactionsFuture: _transactionsFuture,
            ),
          ],
        ),
      ),
    );
  }

  /// Bell icon with badge for unread notifications
  Widget _buildNotificationIcon(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (_, notifier, __) => IconButton(
        icon: badges.Badge(
          badgeContent: Text(
            notifier.unreadCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          showBadge: notifier.unreadCount > 0,
          child: const Icon(Icons.notifications),
        ),
        onPressed: () => Navigator.pushNamed(context, '/notifications'),
      ),
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
            id: index.toString(),
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
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.id,
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
          backgroundColor: AppTheme.primaryColor,
          child: Icon(icon, color: Colors.white),
          heroTag: 'actionButton_$id',
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 70,
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
