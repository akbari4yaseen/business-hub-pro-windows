import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../providers/inventory_provider.dart';
import '../../../themes/app_theme.dart';

class ProductDetailsSheet extends StatelessWidget {
  final dynamic product;
  static final NumberFormat _numberFormatter = NumberFormat('#,###.##');

  const ProductDetailsSheet({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    final currentStock = provider.getCurrentStockForProduct(product.id);
    final loc = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!product.isActive)
                  Chip(
                    label: Text(loc.inactive),
                    backgroundColor: Colors.grey,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailCard(
                    loc.basicInfo,
                    [
                      _buildDetailRow(loc.category,
                          provider.getCategoryName(product.categoryId)),
                      _buildDetailRow(
                          loc.unit, provider.getUnitName(product.unitId)),
                      if (product.sku != null)
                        _buildDetailRow(loc.sku, product.sku),
                      if (product.barcode != null)
                        _buildDetailRow(loc.barcode, product.barcode),
                    ],
                  ),
                  if (product.description != null &&
                      product.description.isNotEmpty)
                    _buildDetailCard(
                      loc.description,
                      [_buildDetailRow('', product.description)],
                    ),
                  _buildDetailCard(
                    loc.stockSettings,
                    [
                      _buildDetailRow(loc.minStock,
                          _numberFormatter.format(product.minimumStock)),
                      _buildDetailRow(loc.maxStock,
                          _numberFormatter.format(product.maximumStock)),
                      _buildDetailRow(loc.reorderPoint,
                          _numberFormatter.format(product.reorderPoint)),
                    ],
                  ),
                  _buildDetailCard(
                    loc.currentStock,
                    [],
                    footer: currentStock.isEmpty
                        ? Text(loc.noStockAvailable)
                        : Column(
                            children: currentStock
                                .map((stock) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(stock['warehouse_name']),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${_numberFormatter.format(stock['quantity'])} ${provider.getUnitName(product.unitId)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> content,
      {Widget? footer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (content.isNotEmpty) const Divider(),
            ...content,
            if (footer != null) ...[
              if (content.isNotEmpty) const SizedBox(height: 8),
              footer,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
