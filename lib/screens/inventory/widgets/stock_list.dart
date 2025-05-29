import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../utils/date_formatters.dart';

class StockList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  static final NumberFormat numberFormatter = NumberFormat('#,###.##');

  const StockList({
    Key? key,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            loc.noItemsFound,
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(
                item['product_name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    Icons.inventory,
                    '${loc.stock}: ${numberFormatter.format(item['quantity'])} ${item['unit_name'] ?? ''}',
                  ),
                  if (item['warehouse_name'] != null)
                    _buildInfoRow(
                      Icons.location_on,
                      '${loc.location}: ${item['warehouse_name']}',
                    ),
                  if (item['expiry_date'] != null)
                    _buildInfoRow(
                      Icons.event,
                      '${loc.expires}: ${formatLocalizedDate(context, item['expiry_date'])}',
                    ),
                ],
              ),
              onTap: () => _showDetailsDialog(context, item),
            ),
          );
        },
        childCount: items.length,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16), // Responsive padding
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['product_name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(loc.sku, item['sku']),
                          _buildDetailRow(loc.category, item['category_name']),
                          _buildDetailRow(loc.unit, item['unit_name']),
                          _buildDetailRow(loc.currentStock,
                              numberFormatter.format(item['quantity'])),
                          _buildDetailRow(loc.minimumStock,
                              numberFormatter.format(item['minimum_stock'])),
                          _buildDetailRow(loc.maximumStock,
                              numberFormatter.format(item['maximum_stock'])),
                          _buildDetailRow(loc.location, item['warehouse_name']),
                          if (item['expiry_date'] != null)
                            _buildDetailRow(
                                loc.expiryDate,
                                formatLocalizedDate(
                                    context, item['expiry_date'])),
                          if (item['last_movement'] != null)
                            _buildDetailRow(
                                loc.lastMovement, item['last_movement']),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? '-'),
          ),
        ],
      ),
    );
  }
}
