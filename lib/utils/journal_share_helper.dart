import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/info_provider.dart';
import 'package:intl/intl.dart';
import '../../utils/date_formatters.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class JournalShareHelper {
  static Future<String> buildJournalMessage(
    BuildContext context,
    Map<String, dynamic> journal,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final infoProvider = Provider.of<InfoProvider>(context, listen: false);
    await infoProvider.loadInfo();
    final companyName = infoProvider.info.name ?? loc.appName;

    final rawDate = journal['date'];
    final DateTime parsedDate =
        rawDate is String ? DateTime.parse(rawDate) : rawDate as DateTime;
    final date =
        formatLocalizedDateEnglishNumbers(context, parsedDate.toString());
    final description = journal['description'] as String? ?? '';
    final amount = journal['amount'] as num? ?? 0;
    final formattedAmount = NumberFormat('#,###.##').format(amount);
    final currency = journal['currency'] as String? ?? '';
    final transactionType =
        (journal['transaction_type'] as String?)?.toLowerCase() ?? '';

    return '''${loc.shareTransactionGreeting(journal['account_name'] ?? '')}

${loc.date}: $date
${loc.amount}: $formattedAmount $currency
${loc.transactionType}: ${transactionType == 'credit' ? loc.credit : loc.debit}

${loc.description}:
$description

${loc.shareTransactionSignature(companyName)}''';
  }

  static Future<void> shareJournal(
    BuildContext context,
    Map<String, dynamic> journal,
  ) async {
    final message = await buildJournalMessage(context, journal);
    await Share.share(message);
  }

  static Future<void> copyJournal(
    BuildContext context,
    Map<String, dynamic> journal,
  ) async {
    final message = await buildJournalMessage(context, journal);
    await Clipboard.setData(ClipboardData(text: message));

    if (context.mounted) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.copiedToClipboard)),
      );
    }
  }
}
