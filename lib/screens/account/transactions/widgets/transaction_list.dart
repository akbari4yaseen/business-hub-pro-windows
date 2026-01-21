import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'transaction_balance_header.dart';
import '../../../../themes/app_theme.dart';
import '../../../../utils/date_formatters.dart' as dFormatter;

class TransactionList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final bool isLoading;
  final bool hasMore;
  final ScrollController scrollController;
  final void Function(Map<String, dynamic>) onDetails;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;
  final void Function(Map<String, dynamic>) onShare;
  final void Function(Map<String, dynamic>) onCopy;
  final void Function(Map<String, dynamic>) onSend;
  final NumberFormat amountFormatter;
  final Map<String, dynamic> balances;

  const TransactionList({
    Key? key,
    required this.transactions,
    required this.isLoading,
    required this.hasMore,
    required this.scrollController,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    required this.onCopy,
    required this.onSend,
    required this.amountFormatter,
    required this.balances,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (transactions.isEmpty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 400),
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            children: [
              // Balance Header
              TransactionBalanceHeader(
                balances: balances,
                amountFormatter: amountFormatter,
              ),
              // Empty State
              SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.noTransactionsFound,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontFamily: 'VazirBold',
                        ),
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

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 400),
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            // Balance Header
            TransactionBalanceHeader(
              balances: balances,
              amountFormatter: amountFormatter,
            ),
            // Data Table
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 18, color: AppTheme.primaryColor),
                                const SizedBox(width: 10),
                                Text(
                                  loc.date,
                                  style: TextStyle(
                                    fontFamily: 'VazirBold',
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildHeaderCell(loc.amount, Icons.attach_money, 1),
                        _buildHeaderCell(loc.balance, Icons.account_balance, 1),
                        _buildHeaderCell(loc.description, Icons.description, 3),
                        _buildHeaderCell(loc.actions, Icons.more_vert, 1),
                      ],
                    ),
                  ),
                  // Table Rows
                  ...transactions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final transaction = entry.value;
                    final isCredit =
                        transaction['transaction_type'] == 'credit';
                    final amountColor =
                        isCredit ? Colors.green[700] : Colors.red[700];

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.03)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade100,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => onDetails(transaction),
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.share),
                                    title: Text(loc.share),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onShare(transaction);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.copy),
                                    title: Text(loc.copy),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onCopy(transaction);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.send),
                                    title: Text(loc.send),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onSend(transaction);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            _buildDateCell(transaction['date'], context),
                            _buildAmountCell(transaction, amountColor, context),
                            _buildBalanceCell(transaction, context),
                            _buildDescriptionCell(
                                transaction['description'] ?? ''),
                            _buildActionsCell(transaction, loc),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            // Loading indicator for pagination
            if (hasMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, IconData icon, int flex) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'VazirBold',
                fontSize: 14,
                color: Colors.grey[800],
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCell(String date, BuildContext context) {
    return SizedBox(
      width: 90,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          dFormatter.formatLocalizedDateTime(context, date),
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAmountCell(Map<String, dynamic> transaction, Color? amountColor,
      BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isEnglish = locale == 'en';

    final amountText =
        '\u200E${amountFormatter.format(transaction['amount'])} ${transaction['currency']}';
    final transactionType = (transaction['transaction_type'] ?? '').toString();
    final isCredit = transactionType.toLowerCase() == 'credit';
    final badgeBaseColor = isCredit ? Colors.green : Colors.red;
    final badgeBackground = badgeBaseColor.withValues(alpha: 0.1);
    final badgeTextColor = isCredit ? Colors.green[700] : Colors.red[700];
    final typeLabel = _localizedTypeLabel(context, transactionType);
    final rawGroup = (transaction['transaction_group'] ?? '').toString();
    final groupLabel = _localizedGroupLabel(context, rawGroup);
    final hasGroup = groupLabel.isNotEmpty;
    final groupBaseColor = Colors.blue;
    final groupBackground = groupBaseColor.withValues(alpha: 0.1);
    final groupTextColor = Colors.blue[700];

    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment:
              isEnglish ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              amountText,
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: isEnglish ? TextAlign.start : TextAlign.end,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (hasGroup) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: groupBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      groupLabel,
                      style: TextStyle(
                        color: groupTextColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _localizedGroupLabel(BuildContext context, String group) {
    final loc = AppLocalizations.of(context)!;
    switch (group.toLowerCase()) {
      case 'journal':
        return loc.journal;
      case 'sales':
        return loc.sales;
      case 'invoice':
        return loc.sales;
      case 'purchase':
        return loc.purchase;
      case 'exchange':
        return loc.exchange;
      default:
        return group;
    }
  }

  String _localizedTypeLabel(BuildContext context, String type) {
    final loc = AppLocalizations.of(context)!;
    switch (type.toLowerCase()) {
      case 'credit':
        return loc.credit;
      case 'debit':
        return loc.debit;
      default:
        return type;
    }
  }

  Widget _buildBalanceCell(
      Map<String, dynamic> transaction, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isEnglish = locale == 'en';
    final balanceColor =
        transaction['balance'] >= 0 ? Colors.green : Colors.red;

    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          '\u200E${amountFormatter.format(transaction['balance'])} ${transaction['currency']}',
          style: TextStyle(
            color: balanceColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          textAlign: isEnglish ? TextAlign.start : TextAlign.end,
        ),
      ),
    );
  }

  Widget _buildDescriptionCell(String description) {
    return Expanded(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildActionsCell(
      Map<String, dynamic> transaction, AppLocalizations loc) {
    return Expanded(
      flex: 1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
            onSelected: (value) {
              switch (value) {
                case 'details':
                  onDetails(transaction);
                  break;
                case 'edit':
                  onEdit(transaction);
                  break;
                case 'delete':
                  onDelete(transaction);
                  break;
                case 'share':
                  onShare(transaction);
                  break;
                case 'copy':
                  onCopy(transaction);
                  break;
                case 'send':
                  onSend(transaction);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'details',
                child: ListTile(
                  leading: const Icon(Icons.info_outline, size: 20),
                  title: Text(loc.details),
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: const Icon(Icons.share, size: 20),
                  title: Text(loc.share),
                ),
              ),
              PopupMenuItem(
                value: 'copy',
                child: ListTile(
                  leading: const Icon(Icons.copy, size: 20),
                  title: Text(loc.copy),
                ),
              ),
              PopupMenuItem(
                value: 'send',
                child: ListTile(
                  leading:
                      const Icon(Icons.send, size: 20, color: Colors.green),
                  title: Text(loc.send),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: const Icon(Icons.edit, size: 20, color: Colors.blue),
                  title: Text(loc.edit),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading:
                      const Icon(Icons.delete, size: 20, color: Colors.red),
                  title: Text(loc.delete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
