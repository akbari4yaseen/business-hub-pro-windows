import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../utils/utilities.dart';
import '../utils/date_formatters.dart';

class RecentTransactionList extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> transactionsFuture;
  static final NumberFormat _amountFormatter = NumberFormat('#,###.##');

  const RecentTransactionList({
    Key? key,
    required this.transactionsFuture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: transactionsFuture,
            builder: (context, snapshot) {
              // Title
              Widget title = Text(
                loc.recentTransactions,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              );

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 16),
                    const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                );
              }
              final txs = snapshot.data;
              if (txs == null || txs.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FontAwesomeIcons.moneyBillTransfer,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              loc.noRecentTransactions,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              // Data available
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: txs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = txs[index];
                      final type = tx['transaction_type'] as String;
                      final isCredit = type == 'credit';
                      final color = isCredit ? Colors.green : Colors.red;
                      final icon = isCredit
                          ? FontAwesomeIcons.plus
                          : FontAwesomeIcons.minus;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.1),
                          child: Icon(icon, color: color, size: 18),
                        ),
                        title: Text(
                          getLocalizedSystemAccountName(
                              context, tx['account_name']),
                          style: const TextStyle(fontFamily: 'IRANsans'),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatLocalizedDateTime(context, tx['date'])),
                            Text(
                              tx['description'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: Text(
                          '\u200E${_amountFormatter.format(tx['amount'])} ${tx['currency']}',
                          style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
