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
    Map<String, dynamic>? accountBalances,
  }) async {
    final loc = AppLocalizations.of(context)!;
    final infoProvider = Provider.of<InfoProvider>(context, listen: false);
    await infoProvider.loadInfo();
    final companyName = infoProvider.info.name ?? loc.appName;

    // Extract and format transaction data
    final rawDate = transaction['date'];
    final DateTime transactionDate = rawDate == null 
        ? DateTime.now() 
        : rawDate is String 
            ? DateTime.parse(rawDate) 
            : rawDate as DateTime;
    final date = formatLocalizedDateEnglishNumbers(context, transactionDate.toString());
    final amount = transaction['amount'] as num? ?? 0;
    final formattedAmount = NumberFormat('#,###.##').format(amount);
    final currency = transaction['currency'] as String? ?? '';
    final description = transaction['description'] as String? ?? '';
    final type = (transaction['transaction_type'] as String?)?.toLowerCase() ?? '';
    final transactionType = type == 'credit' ? loc.creditTransactionType : loc.debitTransactionType;

    // Build transaction details
    final buffer = StringBuffer();
    buffer.writeln(loc.shareTransactionGreeting(accountName ?? ''));
    buffer.writeln(loc.shareTransactionMessage(formattedAmount, currency, transactionType, date));
    
    if (description.isNotEmpty) {
      buffer.writeln('\n${loc.shareTransactionDescription(description)}');
    }

    // Add account balances if available
    if (accountBalances != null && accountBalances.isNotEmpty) {
      buffer.writeln('\n${loc.shareTransactionBalanceHeader}');
      
      // Format each balance line
      accountBalances.forEach((currency, data) {
        final balance = data['summary']?['balance'] as num? ?? 0.0;
        final formattedBalance = NumberFormat('#,###.##').format(balance);
        buffer.writeln('• $formattedBalance $currency');
      });
    } else {
      // Fallback to single transaction amount if no balances available
      buffer.writeln('\n${loc.shareTransactionBalanceHeader}');
      buffer.writeln('$formattedAmount $currency');
    }

    // Add company signature
    buffer.writeln('\n${loc.shareTransactionSignature(companyName)}');

    return buffer.toString();
  }

  static Future<void> shareTransaction(
    BuildContext context,
    Map<String, dynamic> transaction, {
    String? accountName,
    Map<String, dynamic>? accountBalances,
  }) async {
    final message = await buildTransactionMessage(
      context, 
      transaction,
      accountName: accountName,
      accountBalances: accountBalances,
    );
    await Share.share(message);
  }

  static Future<void> copyTransaction(
    BuildContext context,
    Map<String, dynamic> transaction, {
    String? accountName,
    Map<String, dynamic>? accountBalances,
  }) async {
    final message = await buildTransactionMessage(
      context, 
      transaction,
      accountName: accountName,
      accountBalances: accountBalances,
    );
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
    Map<String, dynamic>? accountBalances,
  }) async {
    final message = await buildTransactionMessage(
      context, 
      transaction,
      accountName: accountName,
      accountBalances: accountBalances,
    );

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
    await shareTransaction(
      context, 
      transaction, 
      accountName: accountName,
      accountBalances: accountBalances,
    );
  }
}
