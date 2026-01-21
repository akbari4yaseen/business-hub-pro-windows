import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../utils/date_formatters.dart';
import '../providers/info_provider.dart';

class TransactionShareHelper {
  static Future<String> buildTransactionMessage(
    BuildContext context,
    Map<String, dynamic> transaction, {
    String? accountName,
  }) async {
    final loc = AppLocalizations.of(context)!;
    final infoProvider = Provider.of<InfoProvider>(context, listen: false);
    await infoProvider.loadInfo();
    final companyName = infoProvider.info.name ?? loc.appName;

    // Extract and format transaction data
    final rawDate = transaction['date'];
    final DateTime parsedDate =
        rawDate is String ? DateTime.parse(rawDate) : rawDate as DateTime;
    final date =
        formatLocalizedDateEnglishNumbers(context, parsedDate.toString());
    final amount = transaction['amount'] as num? ?? 0;
    final formattedAmount = NumberFormat('#,###.##').format(amount);
    final currency = transaction['currency'] as String? ?? '';
    final description = transaction['description'] as String? ?? '';
    final type =
        (transaction['transaction_type'] as String?)?.toLowerCase() ?? '';
    final transactionType =
        type == 'credit' ? loc.creditTransactionType : loc.debitTransactionType;

    // Build the message using localized strings
    return '''${loc.shareTransactionGreeting(accountName ?? '')}
${loc.shareTransactionMessage(formattedAmount, currency, transactionType, date)}
${description.isNotEmpty ? '\n${loc.shareTransactionDescription(description)}' : ''}

${loc.shareTransactionBalanceHeader}
${formattedAmount} $currency

${loc.shareTransactionSignature(companyName)}''';
  }

  static Future<void> shareTransaction(
    BuildContext context,
    Map<String, dynamic> transaction, {
    String? accountName,
  }) async {
    final message = await buildTransactionMessage(context, transaction,
        accountName: accountName);
    await Share.share(message);
  }

  static Future<void> copyTransaction(
    BuildContext context,
    Map<String, dynamic> transaction, {
    String? accountName,
  }) async {
    final message = await buildTransactionMessage(context, transaction,
        accountName: accountName);
    await Clipboard.setData(ClipboardData(text: message));

    if (context.mounted) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.copiedToClipboard)),
      );
    }
  }

  static Future<void> sendTransaction(
    BuildContext context,
    Map<String, dynamic> transaction, {
    String? phoneNumber,
    String? accountName,
  }) async {
    final message = await buildTransactionMessage(context, transaction,
        accountName: accountName);

    // If phone number is provided, try to open WhatsApp
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final whatsappUrl =
          'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
      final url = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Fall back to regular share if WhatsApp is not available or no phone number
    await shareTransaction(context, transaction, accountName: accountName);
  }
}
