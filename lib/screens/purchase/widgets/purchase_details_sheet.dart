import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/purchase.dart';
import '../../../providers/purchase_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../providers/account_provider.dart';
import '../../../utils/date_formatters.dart';

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
  bool _isInitialized = false;
  final _amountFormatter = NumberFormat('#,##0.##');

  @override
  void initState() {
    super.initState();
    _itemsFuture = Future.value([]);
    _supplierFuture = Future.value(null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized && widget.purchase.id != null) {
      _itemsFuture =
          context.read<PurchaseProvider>().getPurchaseItems(widget.purchase.id);
      _supplierFuture = context
          .read<AccountProvider>()
          .getAccountById(widget.purchase.supplierId);
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: FutureBuilder<List<PurchaseItem>>(
          future: _itemsFuture,
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            final totalPurchase = widget.purchase.totalAmount;
            final additionalCost = widget.purchase.additionalCost;
            final totalCost = totalPurchase + additionalCost;
            final totalQuantity =
                items.fold<double>(0, (sum, i) => sum + i.quantity);
            final additionalCostPerUnit = totalQuantity > 0
                ? (widget.purchase.additionalCost / totalQuantity).toDouble()
                : 0.0;

            return FutureBuilder<Map<String, dynamic>?>(
              future: _supplierFuture,
              builder: (context, supplierSnapshot) {
                final supplier = supplierSnapshot.data;

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.purchaseDetails,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                            loc.invoice, widget.purchase.invoiceNumber!),
                        _buildDetailRow(
                            loc.date,
                            formatLocalizedDateTime(
                                context, widget.purchase.date.toString())),
                        _buildDetailRow(loc.supplier, supplier?['name'] ?? ''),
                        _buildDetailRow(loc.currency, widget.purchase.currency),
                        _buildDetailRow(
                            loc.total,
                            _amountFormatter
                                .format(widget.purchase.totalAmount)),
                        _buildDetailRow(loc.additionalCost,
                            _amountFormatter.format(additionalCost)),
                        _buildDetailRow(
                            loc.totalCost, _amountFormatter.format(totalCost),
                            isTotal: true),
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
                        ...items.map((item) =>
                            _buildItemRow(item, additionalCostPerUnit)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
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

  Widget _buildItemRow(PurchaseItem item, double additionalCostPerUnit) {
    final costPerItem = item.unitPrice + additionalCostPerUnit;
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
                  '${_amountFormatter.format(item.quantity)} ${item.unitName ?? 'units'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _amountFormatter.format(item.price),
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
                  '${AppLocalizations.of(context)!.price}: ${_amountFormatter.format(item.unitPrice)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${AppLocalizations.of(context)!.unitCostWithAdditional}: ${_amountFormatter.format(costPerItem)}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
