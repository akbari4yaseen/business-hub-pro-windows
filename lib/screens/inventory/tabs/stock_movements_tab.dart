import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../models/stock_movement.dart';
import '../add_stock_movement_screen.dart';
import '../widgets/search_filter_bar.dart';

class StockMovementsTab extends StatefulWidget {
  const StockMovementsTab({Key? key}) : super(key: key);

  @override
  State<StockMovementsTab> createState() => _StockMovementsTabState();
}

class _StockMovementsTabState extends State<StockMovementsTab> {
  String _searchQuery = '';
  String? _selectedWarehouse;
  String? _selectedCategory;
  MovementType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          final movements = provider.stockMovements.where((movement) {
            // Get the product name from provider to search
            final product = provider.products.firstWhere(
              (p) => p.id == movement.productId,
              orElse: () => throw Exception('Product not found for movement'),
            );

            final matchesSearch =
                product.name.toLowerCase().contains(_searchQuery.toLowerCase());

            // For warehouse and category filtering, we would need to join with product and location data
            // Simplified version:
            final matchesType =
                _selectedType == null || movement.type == _selectedType;

            final matchesDateRange = _isWithinDateRange(movement.createdAt);

            return matchesSearch && matchesType && matchesDateRange;
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SearchFilterBar(
                        onSearchChanged: (query) =>
                            setState(() => _searchQuery = query),
                        onWarehouseChanged: (warehouse) =>
                            setState(() => _selectedWarehouse = warehouse),
                        onCategoryChanged: (category) =>
                            setState(() => _selectedCategory = category),
                        warehouses:
                            provider.warehouses.map((w) => w.name).toList(),
                        categories:
                            provider.categories.map((c) => c.name).toList(),
                      ),
                      const SizedBox(height: 8),
                      _buildTypeFilter(),
                      const SizedBox(height: 8),
                      _buildDateRangeFilter(),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: movements.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No movements found',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildMovementCard(
                              context, provider, movements[index]),
                          childCount: movements.length,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMovementDialog(context),
        heroTag: "stock_movement_fab",
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DropdownButtonFormField<MovementType>(
          decoration: const InputDecoration(
            labelText: 'Movement Type',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
          ),
          value: _selectedType,
          hint: const Text('All Types'),
          items: MovementType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.toString().split('.').last),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedType = value),
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => _selectDateRange(context),
                icon: const Icon(Icons.date_range),
                label: Text(_getDateRangeText()),
              ),
            ),
            if (_startDate != null || _endDate != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() {
                  _startDate = null;
                  _endDate = null;
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementCard(BuildContext context, InventoryProvider provider,
      StockMovement movement) {
    // Get product info
    final product = provider.products.firstWhere(
      (p) => p.id == movement.productId,
      orElse: () => throw Exception('Product not found for movement'),
    );

    // Get source location
    String sourceLocation = 'N/A';
    if (movement.sourceBinId != null) {
      final sourceBin = provider.currentStock
          .where((stock) => stock['bin_id'] == movement.sourceBinId)
          .firstOrNull;
      if (sourceBin != null) {
        sourceLocation = sourceBin['warehouse_name'] ?? 'N/A';
      }
    }

    // Get destination location
    String destinationLocation = 'N/A';
    if (movement.destinationBinId != null) {
      final destBin = provider.currentStock
          .where((stock) => stock['bin_id'] == movement.destinationBinId)
          .firstOrNull;
      if (destBin != null) {
        destinationLocation = destBin['warehouse_name'] ?? 'N/A';
      }
    }

    // Set color and icon based on movement type
    Color color;
    IconData icon;

    switch (movement.type) {
      case MovementType.stockIn:
        color = Colors.green;
        icon = Icons.add_circle;
        break;
      case MovementType.stockOut:
        color = Colors.red;
        icon = Icons.remove_circle;
        break;
      case MovementType.transfer:
        color = Colors.blue;
        icon = Icons.swap_horiz;
        break;
      case MovementType.adjustment:
        color = Colors.orange;
        icon = Icons.build;
        break;
    }

    // Get unit name
    final unitName = provider.getUnitName(product.unitId);

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${movement.type.toString().split('.').last} - ${movement.quantity} $unitName',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            Text('From: $sourceLocation'),
            Text('To: $destinationLocation'),
            Text('Date: ${_formatDate(movement.createdAt)}'),
            if (movement.reference != null)
              Text('Reference: ${movement.reference}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showMovementDetails(context, provider, movement),
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String _getDateRangeText() {
    if (_startDate == null && _endDate == null) {
      return 'Select Date Range';
    }
    return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isWithinDateRange(DateTime date) {
    if (_startDate == null || _endDate == null) return true;
    try {
      return date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
          date.isBefore(_endDate!.add(const Duration(days: 1)));
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return true;
    }
  }

  void _showAddMovementDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddStockMovementScreen()),
    );
  }

  void _showMovementDetails(BuildContext context, InventoryProvider provider,
      StockMovement movement) {
    // Get product
    final product = provider.products.firstWhere(
      (p) => p.id == movement.productId,
      orElse: () => throw Exception('Product not found for movement'),
    );

    // Get unit
    final unitName = provider.getUnitName(product.unitId);

    // Get locations
    String sourceLocation = 'N/A';
    if (movement.sourceBinId != null) {
      final sourceBin = provider.currentStock
          .where((stock) => stock['bin_id'] == movement.sourceBinId)
          .firstOrNull;
      if (sourceBin != null) {
        sourceLocation = sourceBin['warehouse_name'] ?? 'N/A';
      }
    }

    String destinationLocation = 'N/A';
    if (movement.destinationBinId != null) {
      final destBin = provider.currentStock
          .where((stock) => stock['bin_id'] == movement.destinationBinId)
          .firstOrNull;
      if (destBin != null) {
        destinationLocation = destBin['warehouse_name'] ?? 'N/A';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Movement Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Product', product.name),
              _buildDetailRow('Type', movement.type.toString().split('.').last),
              _buildDetailRow('Quantity', '${movement.quantity} $unitName'),
              _buildDetailRow('Source', sourceLocation),
              _buildDetailRow('Destination', destinationLocation),
              if (movement.reference != null)
                _buildDetailRow('Reference', movement.reference!),
              if (movement.notes != null)
                _buildDetailRow('Notes', movement.notes!),
              if (movement.expiryDate != null)
                _buildDetailRow(
                    'Expiry Date', _formatDate(movement.expiryDate!)),
              _buildDetailRow('Created At', _formatDate(movement.createdAt)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
