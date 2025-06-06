import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../themes/app_theme.dart';

import '../../../utils/utilities.dart';
import '../../../utils/date_formatters.dart';

class JournalList extends StatelessWidget {
  final List<Map<String, dynamic>> journals;
  final bool isLoading;
  final bool hasMore;
  final ScrollController scrollController;
  final void Function(Map<String, dynamic>) onDetails;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(int) onDelete;
  final void Function(Map<String, dynamic>) onShare;
  final NumberFormat amountFormatter;

  const JournalList({
    Key? key,
    required this.journals,
    required this.isLoading,
    required this.hasMore,
    required this.scrollController,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    required this.amountFormatter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (journals.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 100),
        children: [Center(child: Text(loc.noJournalEntries))],
      );
    }

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 60),
      itemCount: journals.length + (hasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i >= journals.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final j = journals[i];
        final isCredit = j['transaction_type'] == 'credit';
        final icon = isCredit ? FontAwesomeIcons.plus : FontAwesomeIcons.minus;
        final color = isCredit ? Colors.green : Colors.red;

        return Card(
          shape: const BeveledRectangleBorder(borderRadius: BorderRadius.zero),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            onTap: () => onDetails(j),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            leading: CircleAvatar(
              backgroundColor: color.withAlpha(25),
              child: Icon(icon, color: color, size: 18),
            ),
            title: Text(
              '${getLocalizedSystemAccountName(context, j['account_name'])} — ${getLocalizedSystemAccountName(context, j['track_name'])}',
              style: const TextStyle(fontSize: 14, fontFamily: 'VazirBold'),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u200E${amountFormatter.format(j['amount'])} ${j['currency']}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  formatLocalizedDateTime(context, j['date']),
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  j['description'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'details':
                    onDetails(j);
                    break;
                  case 'share':
                    onShare(j);
                    break;
                  case 'edit':
                    onEdit(j);
                    break;
                  case 'delete':
                    onDelete(j['id']);
                    break;
                  default:
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'details',
                  child: ListTile(
                    leading: const Icon(Icons.info),
                    title: Text(loc.details),
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: const Icon(Icons.share),
                    title: Text(loc.share),
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading:
                        const Icon(Icons.edit, color: AppTheme.primaryColor),
                    title: Text(loc.edit),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: const Icon(Icons.delete, color: Colors.redAccent),
                    title: Text(loc.delete),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
