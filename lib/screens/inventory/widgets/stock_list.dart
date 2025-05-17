import 'package:flutter/material.dart';

class StockList extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const StockList({
    Key? key,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'No items found',
            style: TextStyle(
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
                    'Stock: ${item['quantity']} ${item['unit_name'] ?? ''}',
                  ),
                  if (item['warehouse_name'] != null)
                    _buildInfoRow(
                      Icons.location_on,
                      [
                        item['warehouse_name'],
                        item['zone_name'],
                        item['bin_name']
                      ].where((e) => e != null).join(' > '),
                    ),
                  if (item['expiry_date'] != null)
                    _buildInfoRow(
                      Icons.event,
                      'Expires: ${item['expiry_date']}',
                    ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'move',
                    child: Text('Move Stock'),
                  ),
                  const PopupMenuItem(
                    value: 'adjust',
                    child: Text('Adjust Quantity'),
                  ),
                  const PopupMenuItem(
                    value: 'history',
                    child: Text('View History'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['product_name']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('SKU', item['sku']),
              _buildDetailRow('Category', item['category_name']),
              _buildDetailRow('Unit', item['unit_name']),
              _buildDetailRow('Current Stock', '${item['quantity']}'),
              _buildDetailRow('Minimum Stock', '${item['minimum_stock']}'),
              _buildDetailRow('Maximum Stock', '${item['maximum_stock']}'),
              _buildDetailRow('Location', [
                item['warehouse_name'],
                item['zone_name'],
                item['bin_name']
              ].where((e) => e != null).join(' > ')),
              if (item['expiry_date'] != null)
                _buildDetailRow('Expiry Date', item['expiry_date']),
              if (item['last_movement'] != null)
                _buildDetailRow('Last Movement', item['last_movement']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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