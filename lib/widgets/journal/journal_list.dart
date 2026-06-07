import 'package:flutter/material.dart';
import 'package:BusinessHubPro/localization/app_localizations.dart';
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
      return Center(
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
              loc.noJournalEntries,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontFamily: 'VazirBold',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Fixed Header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
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
                _buildHeaderCell(loc.account, Icons.account_balance, 2),
                _buildHeaderCell(loc.track, Icons.track_changes, 2),
                _buildHeaderCell(loc.description, Icons.description, 3),
                _buildHeaderCell(loc.amount, Icons.attach_money, 1),
                _buildHeaderCell(loc.actions, Icons.more_vert, 1),
              ],
            ),
          ),
        ),
        // Scrollable Data
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
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
                  // Table Rows
                  ...journals.asMap().entries.map((entry) {
                    final index = entry.key;
                    final journal = entry.value;
                    final isCredit = journal['transaction_type'] == 'credit';
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
                        onTap: () => onDetails(journal),
                        onLongPress: () => onDetails(journal),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            _buildDateCell(journal['date'], context),
                            _buildTextCell(
                              getLocalizedSystemAccountName(
                                  context, journal['account_name']),
                              2,
                              fontWeight: FontWeight.w600,
                            ),
                            _buildTextCell(
                              getLocalizedSystemAccountName(
                                  context, journal['track_name']),
                              2,
                              fontWeight: FontWeight.w500,
                            ),
                            _buildDescriptionCell(journal['description'] ?? ''),
                            _buildAmountCell(journal, amountColor, context),
                            _buildActionsCell(journal, loc),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  // Loading indicator for pagination
                  if (hasMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
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
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'VazirBold',
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextCell(String text, int flex, {FontWeight? fontWeight}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: fontWeight ?? FontWeight.normal,
            fontSize: 13,
            color: Colors.grey[800],
            height: 1.4,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildAmountCell(
      Map<String, dynamic> journal, Color? amountColor, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isEnglish = locale == 'en';

    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          '\u200E${amountFormatter.format(journal['amount'])} ${journal['currency']}',
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

  Widget _buildDateCell(String date, BuildContext context) {
    return SizedBox(
      width: 90,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          formatLocalizedDateTime(context, date),
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

  Widget _buildActionsCell(Map<String, dynamic> journal, AppLocalizations loc) {
    return Expanded(
      flex: 1,
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 22),
        tooltip: loc.actions,
        padding: EdgeInsets.zero,
        onSelected: (value) {
          switch (value) {
            case 'details':
              onDetails(journal);
              break;
            case 'share':
              onShare(journal);
              break;
            case 'edit':
              onEdit(journal);
              break;
            case 'delete':
              onDelete(journal['id']);
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
