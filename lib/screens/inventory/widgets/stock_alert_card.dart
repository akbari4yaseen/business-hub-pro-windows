import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StockAlertCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> items;

  const StockAlertCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['product_name']),
                subtitle: Text(_buildSubtitle(context, item)),
                leading: Icon(icon, color: color),
                onTap: () => _showDetailsDialog(context, item),
              );
            },
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(BuildContext context, Map<String, dynamic> item) {
    final List<String> details = [];
    final loc = AppLocalizations.of(context)!;

    if (item.containsKey('current_stock') &&
        item.containsKey('minimum_stock')) {
      details.add(
        '${loc.current}: ${item['current_stock']} / ${loc.minimum}: ${item['minimum_stock']}',
      );
    }

    if (item.containsKey('warehouse_name')) {
      details.add('${loc.location}: ${item['warehouse_name']}');
    }

    if (item.containsKey('expiry_date')) {
      details.add('${loc.expires}: ${item['expiry_date']}');
    }

    return details.join('\n');
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['product_name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, loc.sku, item['sku']),
            _buildDetailRow(context, loc.category, item['category_name']),
            _buildDetailRow(
                context, loc.currentStock, item['current_stock']?.toString()),
            _buildDetailRow(
                context, loc.minimumStock, item['minimum_stock']?.toString()),
            _buildDetailRow(context, loc.location, item['warehouse_name']),
            if (item.containsKey('expiry_date'))
              _buildDetailRow(context, loc.expiryDate, item['expiry_date']),
          ],
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

  Widget _buildDetailRow(BuildContext context, String label, String? value) {
    final loc = AppLocalizations.of(context)!;
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
            child: Text(value ?? loc.notAvailable),
          ),
        ],
      ),
    );
  }
}
