import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../themes/app_theme.dart';
import 'purchase_table_row.dart';

class PurchaseTable extends StatelessWidget {
  final List<Map<String, dynamic>> purchases;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onDelete;
  final Function(Map<String, dynamic>) onDetails;

  const PurchaseTable({
    Key? key,
    required this.purchases,
    required this.onEdit,
    required this.onDelete,
    required this.onDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height - 200, // Provide explicit height
      child: Column(
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
                  _buildHeaderCell(loc.supplier, Icons.person, 2),
                  _buildHeaderCell(loc.invoiceNumber, Icons.receipt, 1),
                  _buildHeaderCell(loc.total, Icons.attach_money, 1),
                  _buildHeaderCell(loc.items, Icons.inventory, 2),
                  _buildHeaderCell(loc.actions, Icons.more_vert, 1),
                ],
              ),
            ),
          ),
          // Scrollable Data
          Expanded(
            child: SingleChildScrollView(
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
                    ...purchases.asMap().entries.map((entry) {
                      final index = entry.key;
                      final purchase = entry.value;

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
                          onTap: () => onDetails(purchase),
                          onLongPress: () => onDetails(purchase),
                          borderRadius: BorderRadius.circular(12),
                          child: PurchaseTableRow(
                            purchase: purchase,
                            onEdit: () => onEdit(purchase),
                            onDelete: () => onDelete(purchase),
                            onDetails: () => onDetails(purchase),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
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
} 