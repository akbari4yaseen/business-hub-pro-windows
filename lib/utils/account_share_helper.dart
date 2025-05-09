import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'date_time_picker_helper.dart';
import '../providers/info_provider.dart';

/// Builds a localized, formatted message summarizing an account's balances
String buildShareMessage(BuildContext context, Map<String, dynamic> account) {
  final loc = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final formattedDate = formatLocalizedDateTime(context, now);
  final balances = account['balances'] as Map<String, dynamic>;

  // Format each balance line
  final lines = balances.entries.map((e) {
    final currency = e.value['currency'] ?? e.key;
    final balance = e.value['summary']['balance'] as double? ?? 0.0;
    return '•  ${NumberFormat('#,###.##').format(balance)} $currency';
  }).join('\n');

  final info = Provider.of<InfoProvider>(context, listen: false).info;
  final appName = info.name ?? loc.appName;

  final header = loc.shareMessageHeader(account['name']);
  final timestamp = loc.shareMessageTimestamp(formattedDate);
  final footer = loc.shareMessageFooter(appName);

  String message = '$header\n$lines\n\n$timestamp';

  final hasNegative = balances.values.any(
    (e) => (e['summary']['balance'] as num?)?.isNegative ?? false,
  );

  if (hasNegative) {
    message += '\n\n${loc.shareMessagePaymentReminder}';
  }

  return '$message\n\n$footer';
}

/// Shares an account's balances via system share or WhatsApp
Future<void> shareAccountBalances(
  BuildContext context,
  Map<String, dynamic> account, {
  bool viaWhatsApp = false,
}) async {
  final message = buildShareMessage(context, account);

  if (viaWhatsApp) {
    final phone = account['phone'] ?? '';
    if (phone.isEmpty) return;

    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } else {
    await Share.share(message);
  }
}

/// Launches the phone dialer for the given [phone] number.
/// Shows a SnackBar with an error message if dialing fails.
Future<void> launchAccountCall(BuildContext context, String? phone) async {
  if (phone == null || phone.isEmpty) return;
  final uri = Uri(scheme: 'tel', path: phone);
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $uri';
    }
  } catch (_) {
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc!.callError),
      ),
    );
  }
}
