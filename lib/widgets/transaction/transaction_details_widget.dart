import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../utils/date_formatters.dart';

class TransactionDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;
  static final NumberFormat _amountFormatter = NumberFormat('#,###.##');

  const TransactionDetailsSheet({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.journalDetails,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Detail content
                  _detailItem(loc.description,
                      transaction['description'] ?? loc.noDescription),
                  _detailItem(loc.date,
                      formatLocalizedDateTime(context, transaction['date'])),
                  _detailItem(
                    loc.amount,
                    '\u200E${_amountFormatter.format(transaction['amount'])} ${transaction['currency']}',
                  ),
                  _detailItem(
                    loc.transactionType,
                    transaction['transaction_type'] == 'credit'
                        ? loc.credit
                        : loc.debit,
                  ),
                  _detailItem(
                    loc.balance,
                    '\u200E${_amountFormatter.format(transaction['balance'])} ${transaction['currency']}',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}
