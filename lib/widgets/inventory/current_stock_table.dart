import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../themes/app_theme.dart';
import '../../screens/inventory/widgets/stock_alert_card.dart';

class CurrentStockTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ScrollController scrollController;
  final bool isLoading;
  final bool hasMore;
  final Widget? filters;
  final List<Map<String, dynamic>> lowStockProducts;
  final List<Map<String, dynamic>> expiringProducts;

  const CurrentStockTable({
    Key? key,
    required this.items,
    required this.scrollController,
    required this.isLoading,
    required this.hasMore,
    this.filters,
    required this.lowStockProducts,
    required this.expiringProducts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              loc.noItemsFound,
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

    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          // Filters Section
          if (filters != null) filters!,
          
          // Alert Cards
          if (lowStockProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: StockAlertCard(
                title: loc.lowStockAlerts,
                icon: Icons.warning,
                color: Colors.red,
                items: lowStockProducts,
              ),
            ),
          if (expiringProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: StockAlertCard(
                title: loc.expiringProducts,
                icon: Icons.schedule,
                color: Colors.orange,
                items: expiringProducts,
              ),
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
                      _buildHeaderCell(loc.product, Icons.inventory, 2),
                      _buildHeaderCell(loc.sku, Icons.qr_code, 1),
                      _buildHeaderCell(loc.category, Icons.category, 1),
                      _buildHeaderCell(loc.currentStock, Icons.scale, 1),
                      _buildHeaderCell(loc.location, Icons.location_on, 1),
                      _buildHeaderCell(loc.actions, Icons.more_vert, 1),
                    ],
                  ),
                ),
                // Table Rows
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

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
                      onTap: () => _showDetailsDialog(context, item),
                      onLongPress: () => _showDetailsDialog(context, item),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          _buildProductCell(item),
                          _buildSkuCell(item),
                          _buildCategoryCell(item),
                          _buildStockCell(item),
                          _buildLocationCell(item),
                          _buildActionsCell(item, context),
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

  Widget _buildProductCell(Map<String, dynamic> item) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          item['product_name'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildSkuCell(Map<String, dynamic> item) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          item['sku'] ?? '-',
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildCategoryCell(Map<String, dynamic> item) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          item['category_name'] ?? 'Uncategorized',
          style: const TextStyle(
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStockCell(Map<String, dynamic> item) {
    final numberFormatter = NumberFormat('#,###.##');
    final quantity = item['quantity'] ?? 0;
    final unitName = item['unit_name'] ?? '';
    final minimumStock = item['minimum_stock'] ?? 0;
    
    Color textColor = Colors.black;
    if (quantity <= minimumStock) {
      textColor = Colors.red;
    }
    
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          '${numberFormatter.format(quantity)} $unitName',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLocationCell(Map<String, dynamic> item) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          item['warehouse_name'] ?? '-',
          style: const TextStyle(
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildActionsCell(Map<String, dynamic> item, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Expanded(
      flex: 1,
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 22),
        tooltip: loc.actions,
        padding: EdgeInsets.zero,
        onSelected: (value) {
          switch (value) {
            case 'details':
              _showDetailsDialog(context, item);
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
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    final loc = AppLocalizations.of(context)!;
    final numberFormatter = NumberFormat('#,###.##');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
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
                          item['product_name'] ?? '',
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
                          if (item['maximum_stock'] != null)
                            _buildDetailRow(loc.maximumStock,
                                numberFormatter.format(item['maximum_stock'])),
                          _buildDetailRow(loc.location, item['warehouse_name']),
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