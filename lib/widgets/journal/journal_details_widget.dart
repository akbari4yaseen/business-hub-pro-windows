import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../utils/date_formatters.dart';
import '../../../utils/utilities.dart';

/// A reusable widget that displays journal entry details in a modal-friendly layout.
class JournalDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> journal;
  static final NumberFormat _numberFormatter = NumberFormat('#,###.##');

  const JournalDetailsWidget({Key? key, required this.journal}) : super(key: key);

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

                  // Content
                  _detailItem(loc.description, journal['description'] ?? loc.noDescription),
                  _detailItem(loc.date, formatLocalizedDateTime(context, journal['date'])),
                  _detailItem(
                    loc.amount,
                    '\u200E${_numberFormatter.format(journal['amount'])} ${journal['currency']}',
                  ),
                  _detailItem(
                    loc.transactionType,
                    journal['transaction_type'] == 'credit' ? loc.credit : loc.debit,
                  ),
                  _detailItem(
                    loc.account,
                    getLocalizedSystemAccountName(context, journal['account_name']),
                  ),
                  _detailItem(
                    loc.track,
                    getLocalizedSystemAccountName(context, journal['track_name']),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
