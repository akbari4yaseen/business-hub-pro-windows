import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../utils/date_formatters.dart';
import '../providers/info_provider.dart';

Future<void> shareJournalEntry(
    BuildContext context, Map<String, dynamic> journal) async {
  final loc = AppLocalizations.of(context)!;
  final infoProvider = Provider.of<InfoProvider>(context, listen: false);
  await infoProvider.loadInfo(); // Ensure info is loaded
  final info = infoProvider.info;
  final appName = info.name ?? loc.appName;

  // Extract and sanitize fields
  final accountName = journal['account_name'] as String? ?? '';
  final rawDate = journal['date'];
  final DateTime parsedDate =
      rawDate is String ? DateTime.parse(rawDate) : rawDate as DateTime;
  final date = formatLocalizedDate(context, parsedDate.toString());
  final amount = NumberFormat('#,###.##').format(journal['amount'] as num);
  final currency = journal['currency'] as String? ?? '';
  final description = journal['description'] as String? ?? '';
  final type = (journal['transaction_type'] as String?)?.toLowerCase() ?? '';
  final action = type == 'credit' ? loc.credited : loc.debited;
  final footer = loc.shareMessageFooter(appName);

  // Use a localized template for the full message
  final message = loc.shareMessage(
    accountName,
    action,
    amount,
    currency,
    date,
    description,
    footer,
  );

  await Share.share(message);
}
