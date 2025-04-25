import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../database/reports_db.dart';
import '../../utils/utilities.dart';

class SystemAccountReportsScreen extends StatefulWidget {
  const SystemAccountReportsScreen({Key? key}) : super(key: key);

  @override
  State<SystemAccountReportsScreen> createState() =>
      _SystemAccountReportsScreenState();
}

class _SystemAccountReportsScreenState
    extends State<SystemAccountReportsScreen> {
  late Future<List<Map<String, dynamic>>> _accountsFuture;

  // Formatter with thousands separators and exactly two decimals
  static final NumberFormat _amountFormatter = NumberFormat('#,###.##');

  static const _systemAccounts = <int, _AccountMeta>{
    1: _AccountMeta('treasure', Icons.account_balance_wallet, Colors.amber),
    3: _AccountMeta('asset', Icons.pie_chart, Colors.blue),
    9: _AccountMeta('profit', Icons.trending_up, Colors.green),
    10: _AccountMeta('loss', Icons.trending_down, Colors.red),
  };

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    _accountsFuture = ReportsDBHelper().getSystemAccounts();
  }

  Future<void> _refresh() async {
    _loadAccounts();
    setState(() {});
    await _accountsFuture;
  }

  Map<String, Map<String, double>> _aggregate(List<Map<String, dynamic>> txns) {
    final map = <String, Map<String, double>>{};
    for (var txn in txns) {
      final cur = txn['currency'] as String;
      final amt = (txn['amount'] as num).toDouble();
      final type = txn['transaction_type'] as String;
      final bucket = map.putIfAbsent(cur, () => {'credit': 0, 'debit': 0});
      bucket[type] = bucket[type]! + amt;
    }
    return map.map((cur, sums) {
      final c = sums['credit']!;
      final d = sums['debit']!;
      return MapEntry(cur, {
        'credit': c,
        'debit': d,
        'balance': c - d,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.systemAccount),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: theme.colorScheme.primary,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _accountsFuture,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Text(
                  '${loc.error}: ${snap.error}',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }

            final raw = snap.data ?? [];
            final accounts = raw
                .where((a) => _systemAccounts.containsKey(a['id'] as int))
                .toList();
            if (accounts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 200),
                  Center(child: Text(loc.noSystemAccountsFound)),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: accounts.length,
              itemBuilder: (context, idx) {
                final acc = accounts[idx];
                final id = acc['id'] as int;
                final meta = _systemAccounts[id]!;
                final details =
                    List<Map<String, dynamic>>.from(acc['details'] as List);
                final summary = _aggregate(details);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: meta.color.withAlpha(50),
                        child: Icon(meta.icon, color: meta.color),
                      ),
                      title: Text(
                        // your helper will pick the right localized name
                        getLocalizedSystemAccountName(context, meta.name),
                        style: theme.textTheme.titleLarge,
                      ),
                      subtitle: Text(
                        '${loc.currencies}: ${summary.length}',
                        style: theme.textTheme.bodySmall,
                      ),
                      childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth > 600 ? 4 : 2;
                            final itemWidth =
                                (constraints.maxWidth - (columns - 1) * 12) /
                                    columns;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: summary.entries.map((entry) {
                                final creditStr = _amountFormatter
                                    .format(entry.value['credit']!);
                                final debitStr = _amountFormatter
                                    .format(entry.value['debit']!);
                                final balanceStr = _amountFormatter
                                    .format(entry.value['balance']!);

                                return SizedBox(
                                  width: itemWidth,
                                  child: _CurrencyCard(
                                    currency: entry.key,
                                    credit: creditStr,
                                    debit: debitStr,
                                    balance: balanceStr,
                                    balanceLabel: loc.balance,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AccountMeta {
  final String name;
  final IconData icon;
  final Color color;
  const _AccountMeta(this.name, this.icon, this.color);
}

class _CurrencyCard extends StatelessWidget {
  final String currency;
  final String credit;
  final String debit;
  final String balance;
  final String balanceLabel;

  const _CurrencyCard({
    Key? key,
    required this.currency,
    required this.credit,
    required this.debit,
    required this.balance,
    required this.balanceLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currency, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _RowIconText(
              icon: FontAwesomeIcons.plus,
              text: credit,
              iconColor: Colors.green,
            ),
            const SizedBox(height: 4),
            _RowIconText(
              icon: FontAwesomeIcons.minus,
              text: debit,
              iconColor: Colors.red,
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(balanceLabel, style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(balance, style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _RowIconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _RowIconText({
    Key? key,
    required this.icon,
    required this.text,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
