import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../models/purchase.dart';
import '../../../models/purchase_item.dart';
import '../../../providers/purchase_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../providers/account_provider.dart';

class PurchaseDetailsSheet extends StatefulWidget {
  final Purchase purchase;

  const PurchaseDetailsSheet({
    Key? key,
    required this.purchase,
  }) : super(key: key);

  @override
  _PurchaseDetailsSheetState createState() => _PurchaseDetailsSheetState();
}

class _PurchaseDetailsSheetState extends State<PurchaseDetailsSheet> {
  late Future<List<PurchaseItem>> _itemsFuture;
  late Future<Map<String, dynamic>?> _supplierFuture;

  @override
  void initState() {
    super.initState();
    if (widget.purchase.id != null) {
      _itemsFuture =
          context.read<PurchaseProvider>().getPurchaseItems(widget.purchase.id);
      _supplierFuture = context
          .read<AccountProvider>()
          .getAccountById(widget.purchase.supplierId);
    } else {
      _itemsFuture = Future.value([]);
      _supplierFuture = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return FutureBuilder<List<PurchaseItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return FutureBuilder<Map<String, dynamic>?>(
          future: _supplierFuture,
          builder: (context, supplierSnapshot) {
            final supplier = supplierSnapshot.data;

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.purchaseDetails,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(loc.invoice, widget.purchase.invoiceNumber!),
                  _buildDetailRow(loc.date,
                      widget.purchase.date.toIso8601String().split('T')[0]),
                  _buildDetailRow(loc.supplier, supplier?['name'] ?? ''),
                  _buildDetailRow(loc.currency, widget.purchase.currency),
                  _buildDetailRow(loc.total,
                      widget.purchase.totalAmount.toStringAsFixed(2)),
                  if (widget.purchase.notes != null &&
                      widget.purchase.notes!.isNotEmpty)
                    _buildDetailRow(loc.notes, widget.purchase.notes!),
                  const SizedBox(height: 16),
                  Text(
                    loc.items,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) => _buildItemRow(item)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(PurchaseItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName ?? 'Unknown Product',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.quantity} ${item.unitName ?? 'units'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.price.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.price}: ${item.unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
