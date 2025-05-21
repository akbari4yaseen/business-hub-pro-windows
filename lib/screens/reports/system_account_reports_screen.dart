import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../database/reports_db.dart';
import '../../utils/utilities.dart';
import '../../themes/app_theme.dart';

class SystemAccountReportsScreen extends StatefulWidget {
  const SystemAccountReportsScreen({Key? key}) : super(key: key);

  @override
  State<SystemAccountReportsScreen> createState() =>
      _SystemAccountReportsScreenState();
}

class _SystemAccountReportsScreenState
    extends State<SystemAccountReportsScreen> {
  late Future<List<Map<String, dynamic>>> _accountsFuture;

  static const _systemAccounts = <int, _AccountMeta>{
    1: _AccountMeta('treasure', Icons.account_balance_wallet, Colors.amber),
    3: _AccountMeta('asset', Icons.pie_chart, AppTheme.primaryColor),
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

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: accounts.map((acc) {
                        final id = acc['id'] as int;
                        final meta = _systemAccounts[id]!;
                        final details = List<Map<String, dynamic>>.from(
                            acc['details'] as List);
                        final summary = _aggregate(details);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: meta.color.withAlpha(50),
                                    child: Icon(meta.icon, color: meta.color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getLocalizedSystemAccountName(
                                              context, meta.name),
                                          style: theme.textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${loc.currencies}: ${summary.length}',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: summary.entries.map((entry) {
                                    final credit = entry.value['credit']!;
                                    final debit = entry.value['debit']!;
                                    final balance = entry.value['balance']!;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: _CurrencyCard(
                                        currency: entry.key,
                                        credit: credit,
                                        debit: debit,
                                        balance: balance,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              if (acc != accounts.last) ...[
                                const SizedBox(height: 24),
                                const Divider(),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
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
  static final NumberFormat _amountFormatter = NumberFormat('#,###.##');
  final String currency;
  final double credit;
  final double debit;
  final double balance;

  const _CurrencyCard({
    Key? key,
    required this.currency,
    required this.credit,
    required this.debit,
    required this.balance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      width: 240,
      height: 167,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF6353DA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            currency,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.credit,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _amountFormatter.format(credit),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.debit,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _amountFormatter.format(debit),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text(
                loc.balance,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '\u200E${_amountFormatter.format(balance)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
