import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/reports_db.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountReportsScreen extends StatefulWidget {
  const AccountReportsScreen({Key? key}) : super(key: key);

  @override
  _AccountReportsScreenState createState() => _AccountReportsScreenState();
}

class _AccountReportsScreenState extends State<AccountReportsScreen> {
  final ReportsDBHelper _dbHelper = ReportsDBHelper();
  late Future<List<Map<String, dynamic>>> _futureBalances;
  late Future<Map<String, int>> _futureCount;

  static const Map<String, AccountMeta> _accountMeta = {
    'customer': AccountMeta(Icons.person, Colors.blue, 'Customer'),
    'supplier': AccountMeta(Icons.local_shipping, Colors.orange, 'Supplier'),
    'exchanger': AccountMeta(Icons.swap_horiz, Colors.purple, 'Exchanger'),
    'bank': AccountMeta(Icons.account_balance, Colors.green, 'Bank'),
    'income': AccountMeta(Icons.trending_up, Colors.lightGreen, 'Income'),
    'expense': AccountMeta(Icons.trending_down, Colors.red, 'Expense'),
    'owner': AccountMeta(Icons.emoji_people, Colors.indigo, 'Owner'),
    'company': AccountMeta(Icons.business, Colors.teal, 'Company'),
  };

  @override
  void initState() {
    super.initState();
    _futureBalances = _dbHelper.getAccountBalances();
    // getAccountCountByType
    _futureCount = _dbHelper.getAccountCountByType();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.accountReports),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureBalances,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: ${snapshot.error}',
                    style: theme.textTheme.bodyMedium),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(loc.noDataAvailable,
                    style: theme.textTheme.bodyMedium),
              ),
            );
          }

          final groups = _prepareGroups(data);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ExpansionPanelList.radio(
              elevation: 1,
              expandedHeaderPadding: EdgeInsets.zero,
              children:
                  groups.map((group) => _buildPanel(group, theme)).toList(),
            ),
          );
        },
      ),
    );
  }

  List<AccountGroup> _prepareGroups(List<Map<String, dynamic>> rows) {
    final Map<String, Map<String, _CurrencyEntry>> temp = {};
    for (final row in rows) {
      final type = row['account_type'] as String;
      final curr = row['currency'] as String;
      final txType = row['transaction_type'] as String;
      final amount = (row['total_amount'] as num).toDouble();

      temp.putIfAbsent(type, () => {});
      temp[type]!.putIfAbsent(curr, () => _CurrencyEntry(curr, 0, 0));
      final entry = temp[type]![curr]!;
      if (txType == 'credit') {
        entry.credit += amount;
      } else {
        entry.debit += amount;
      }
    }

    return temp.entries.map((e) {
      final meta = _accountMeta[e.key]!;
      final entries = e.value.values.toList();
      return AccountGroup(
        type: e.key,
        meta: meta,
        entries: entries,
      );
    }).toList();
  }

  ExpansionPanelRadio _buildPanel(AccountGroup group, ThemeData theme) {
    return ExpansionPanelRadio(
      value: group.type,
      headerBuilder: (context, isOpen) {
        return FutureBuilder<Map<String, int>>(
          future: _futureCount,
          builder: (context, snapshot) {
            final count = snapshot.data?[group.type] ?? 0;

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: group.meta.color.withValues(alpha: 0.1),
                child: Icon(group.meta.icon, color: group.meta.color),
              ),
              title: Text(group.meta.label, style: theme.textTheme.titleLarge),
              subtitle: Text('Total ${group.meta.label}: $count',
                  style: theme.textTheme.bodySmall),
            );
          },
        );
      },
      body: Column(
        children: group.entries
            .map((entry) => _EntryCard(entry: entry, theme: theme))
            .toList(),
      ),
    );
  }
}

class AccountMeta {
  final IconData icon;
  final Color color;
  final String label;
  const AccountMeta(this.icon, this.color, this.label);
}

class AccountGroup {
  final String type;
  final AccountMeta meta;
  final List<_CurrencyEntry> entries;
  double get total => entries.fold(0, (sum, e) => sum + e.balance);
  AccountGroup({required this.type, required this.meta, required this.entries});
}

class _CurrencyEntry {
  final String currency;
  double credit;
  double debit;
  _CurrencyEntry(this.currency, this.credit, this.debit);
  double get balance => credit - debit;
}

class _EntryCard extends StatelessWidget {
  final _CurrencyEntry entry;
  final ThemeData theme;
  const _EntryCard({Key? key, required this.entry, required this.theme})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###.##');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Credit', style: theme.textTheme.bodyMedium),
                Text(formatter.format(entry.credit),
                    style: theme.textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Debit', style: theme.textTheme.bodyMedium),
                Text(formatter.format(entry.debit),
                    style: theme.textTheme.bodyLarge),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Balance (${entry.currency})',
                    style: theme.textTheme.bodyMedium),
                Text(formatter.format(entry.balance),
                    style: theme.textTheme.titleMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
