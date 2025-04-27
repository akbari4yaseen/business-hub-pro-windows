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
    'customer': AccountMeta(Icons.person, Colors.blue),
    'supplier': AccountMeta(Icons.local_shipping, Colors.orange),
    'exchanger': AccountMeta(Icons.swap_horiz, Colors.purple),
    'bank': AccountMeta(Icons.account_balance, Colors.green),
    'income': AccountMeta(Icons.trending_up, Colors.lightGreen),
    'expense': AccountMeta(Icons.trending_down, Colors.red),
    'owner': AccountMeta(Icons.emoji_people, Colors.indigo),
    'company': AccountMeta(Icons.business, Colors.teal),
  };

  @override
  void initState() {
    super.initState();
    _futureBalances = _dbHelper.getAccountBalances();
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
                child: Text(
                  '${loc.error}: ${snapshot.error}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  loc.noDataAvailable,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          final groups = _prepareGroups(data);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Material(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionPanelList.radio(
                expandedHeaderPadding: EdgeInsets.zero,
                children: groups
                    .map((group) => _buildPanel(group, theme, loc))
                    .toList(),
              ),
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

  ExpansionPanelRadio _buildPanel(
      AccountGroup group, ThemeData theme, AppLocalizations loc) {
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
                backgroundColor: group.meta.color.withAlpha(25),
                child: Icon(group.meta.icon, color: group.meta.color),
              ),
              title: Text(_accountLabel(loc, group.type),
                  style: theme.textTheme.titleLarge),
              subtitle: Text(loc.totalCount(count.toString()),
                  style: theme.textTheme.bodySmall),
            );
          },
        );
      },
      body: Column(
        children: group.entries
            .map((entry) => _EntryCard(entry: entry, theme: theme, loc: loc))
            .toList(),
      ),
    );
  }

  String _accountLabel(AppLocalizations loc, String type) {
    switch (type) {
      case 'customer':
        return loc.customer;
      case 'supplier':
        return loc.supplier;
      case 'exchanger':
        return loc.exchanger;
      case 'bank':
        return loc.bank;
      case 'income':
        return loc.income;
      case 'expense':
        return loc.expense;
      case 'owner':
        return loc.owner;
      case 'company':
        return loc.company;
      default:
        return type;
    }
  }
}

class AccountMeta {
  final IconData icon;
  final Color color;
  const AccountMeta(this.icon, this.color);
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
  final AppLocalizations loc;
  const _EntryCard(
      {Key? key, required this.entry, required this.theme, required this.loc})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###.##');
    final balanceColor = entry.balance < 0 ? Colors.red : Colors.green;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(loc.credit, style: theme.textTheme.bodyMedium),
                ),
                Expanded(
                  child: Text(formatter.format(entry.credit),
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.end),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(loc.debit, style: theme.textTheme.bodyMedium),
                ),
                Expanded(
                  child: Text(formatter.format(entry.debit),
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.end),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(loc.balanceLabel(entry.currency),
                      style: theme.textTheme.bodyMedium),
                ),
                Expanded(
                  child: Text('\u200E${formatter.format(entry.balance)}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: balanceColor),
                      textAlign: TextAlign.end),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
