import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StockList extends StatelessWidget {
  final List<Map<String, dynamic>> items;

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
                    '${loc.stock}: ${item['quantity']} ${item['unit_name'] ?? ''}',
                  ),
                  if (item['warehouse_name'] != null)
                    _buildInfoRow(
                      Icons.location_on,
                      '${loc.location}: ${item['warehouse_name']}',
                    ),
                  if (item['expiry_date'] != null)
                    _buildInfoRow(
                      Icons.event,
                      '${loc.expires}: ${item['expiry_date']}',
                    ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'move',
                    child: Text(loc.moveStock),
                  ),
                  PopupMenuItem(
                    value: 'adjust',
                    child: Text(loc.adjustQuantity),
                  ),
                  PopupMenuItem(
                    value: 'history',
                    child: Text(loc.viewHistory),
                  ),
                ],
                onSelected: (value) => _handleMenuAction(context, value, item),
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
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['product_name']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(loc.sku, item['sku']),
              _buildDetailRow(loc.category, item['category_name']),
              _buildDetailRow(loc.unit, item['unit_name']),
              _buildDetailRow(loc.currentStock, '${item['quantity']}'),
              _buildDetailRow(loc.minimumStock, '${item['minimum_stock']}'),
              _buildDetailRow(loc.maximumStock, '${item['maximum_stock']}'),
              _buildDetailRow(loc.location, item['warehouse_name']),
              if (item['expiry_date'] != null)
                _buildDetailRow(loc.expiryDate, item['expiry_date']),
              if (item['last_movement'] != null)
                _buildDetailRow(loc.lastMovement, item['last_movement']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Map<String, dynamic> item,
  ) {
    switch (action) {
      case 'move':
        // TODO: Implement move stock functionality
        break;
      case 'adjust':
        // TODO: Implement adjust quantity functionality
        break;
      case 'history':
        // TODO: Implement view history functionality
        break;
    }
  }
}
