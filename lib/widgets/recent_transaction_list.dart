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
    final loc = AppLocalizations.of(context)!;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: transactionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final txs = snapshot.data;
        if (txs == null || txs.isEmpty) {
          return Center(child: Text(loc.noRecentTransactions));
        }
        return Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: txs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = txs[index];
              final type = tx['transaction_type'] as String;
              final isCredit = type == 'credit';
              final color = isCredit ? Colors.green : Colors.red;
              final icon =
                  isCredit ? FontAwesomeIcons.plus : FontAwesomeIcons.minus;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(icon, color: color, size: 18),
                ),
                title: Text(
                  getLocalizedSystemAccountName(context, tx['account_name']),
                  style: const TextStyle(fontFamily: 'IRANsans'),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatLocalizedDate(context, tx['date'])),
                    Text(
                      tx['description'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Text(
                  '${_amountFormatter.format(tx['amount'])} ${tx['currency']}',
                  style: TextStyle(color: color),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              );
            },
          ),
        );
      },
    );
  }
}
