import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../../themes/app_theme.dart';
import '../../../../utils/date_formatters.dart' as dFormatter;
import 'transaction_balance_header.dart';

class TransactionList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final bool isLoading;
  final bool hasMore;
  final ScrollController scrollController;
  final void Function(Map<String, dynamic>) onDetails;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;
  final void Function(Map<String, dynamic>) onShare;
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                                Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
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
                    final isCredit = transaction['transaction_type'] == 'credit';
                    final amountColor = isCredit ? Colors.green[700] : Colors.red[700];

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: index.isEven 
                            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.03)
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
                        onLongPress: () => onDetails(transaction),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            _buildDateCell(transaction['date'], context),
                            _buildAmountCell(transaction, amountColor, context),
                            _buildBalanceCell(transaction, context),
                            _buildDescriptionCell(transaction['description'] ?? ''),
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

  Widget _buildAmountCell(Map<String, dynamic> transaction, Color? amountColor, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isEnglish = locale == 'en';
    
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          '\u200E${amountFormatter.format(transaction['amount'])} ${transaction['currency']}',
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: isEnglish ? TextAlign.start : TextAlign.end,
        ),
      ),
    );
  }

  Widget _buildBalanceCell(Map<String, dynamic> transaction, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isEnglish = locale == 'en';
    final balanceColor = transaction['balance'] >= 0 ? Colors.green : Colors.red;
    
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

  Widget _buildActionsCell(Map<String, dynamic> transaction, AppLocalizations loc) {
    return Expanded(
      flex: 1,
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 22),
        tooltip: loc.actions,
        padding: EdgeInsets.zero,
        onSelected: (value) {
          switch (value) {
            case 'details':
              onDetails(transaction);
              break;
            case 'share':
              onShare(transaction);
              break;
            case 'edit':
              onEdit(transaction);
              break;
            case 'delete':
              onDelete(transaction);
              break;
            default:
              break;
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'details',
            child: Row(
              children: [
                const Icon(Icons.info, size: 18),
                const SizedBox(width: 12),
                Text(loc.details),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                const Icon(Icons.share, size: 18),
                const SizedBox(width: 12),
                Text(loc.share),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(loc.edit),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                const SizedBox(width: 12),
                Text(loc.delete),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 