import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../../themes/app_theme.dart';
import '../../../../utils/date_formatters.dart' as dFormatter;

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final NumberFormat amountFormatter;
  final VoidCallback onTap;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const TransactionCard({
    Key? key,
    required this.transaction,
    required this.amountFormatter,
    required this.onTap,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isCredit = transaction['transaction_type'] == 'credit';
    final icon = isCredit ? FontAwesomeIcons.plus : FontAwesomeIcons.minus;
    final color = isCredit ? Colors.green : Colors.red;
    final balanceColor = transaction['balance'] >= 0 ? Colors.green : Colors.red;
    
    String formatAmount(num amount) => '\u200E${amountFormatter.format(amount)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          '${formatAmount(transaction['amount'])} ${transaction['currency']}',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.balance}:${formatAmount(transaction['balance'])} ${transaction['currency']}',
              style: TextStyle(fontSize: 14, color: balanceColor),
            ),
            Text(
              dFormatter.formatLocalizedDateTime(context, transaction['date']),
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              transaction['description'] ?? '',
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
                onDetails();
                break;
              case 'share':
                onShare();
                break;
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
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
                leading: Icon(Icons.edit, color: AppTheme.primaryColor),
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
  }
} 