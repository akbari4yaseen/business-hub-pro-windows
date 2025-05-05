import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../utils/date_formatters.dart';
import '../../utils/utilities.dart';

/// A reusable widget that displays journal entry details in a draggable bottom sheet.
class JournalDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> journal;

  const JournalDetailsWidget({Key? key, required this.journal})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Stack(
          children: [
            // Header with title and close button
            Padding(
              padding: const EdgeInsets.only(
                  left: 12, right: 12, top: 12, bottom: 18),
              child: Row(
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
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _detailItem(loc.description,
                        journal['description'] ?? loc.noDescription),
                    _detailItem(loc.date,
                        formatLocalizedDateTime(context, journal['date'])),
                    _detailItem(
                      loc.amount,
                      '\u200E${NumberFormat('#,###.##').format(journal['amount'])} ${journal['currency']}',
                    ),
                    _detailItem(
                      loc.transactionType,
                      journal['transaction_type'] == 'credit'
                          ? loc.credit
                          : loc.debit,
                    ),
                    _detailItem(
                      loc.account,
                      getLocalizedSystemAccountName(
                          context, journal['account_name']),
                    ),
                    _detailItem(
                      loc.track,
                      getLocalizedSystemAccountName(
                          context, journal['track_name']),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontFamily: 'VazirBold', color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            content,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}
