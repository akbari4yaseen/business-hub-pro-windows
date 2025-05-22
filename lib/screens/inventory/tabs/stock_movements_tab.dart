import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../add_stock_movement_screen.dart';
import '../widgets/search_filter_bar.dart';
import '../../../utils/date_formatters.dart';
import '../../../providers/inventory_provider.dart';
import '../../../models/stock_movement.dart';
import '../../../themes/app_theme.dart';

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
    final loc = AppLocalizations.of(context)!;

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
                    ? SliverFillRemaining(
                        child: Center(
                          child: Text(
                            loc.noMovementsFound,
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
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DropdownButtonFormField<MovementType>(
          isDense: true,
          decoration: InputDecoration(
            labelText: loc.movementType,
            hintText: loc.allTypes,
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          value: _selectedType,
          items: [
            DropdownMenuItem<MovementType>(
              value: null,
              child: Text(loc.allTypes),
            ),
            ...MovementType.values.map(
              (type) => DropdownMenuItem<MovementType>(
                value: type,
                child: Text(type.toString().split('.').last),
              ),
            ),
          ],
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
    final loc = AppLocalizations.of(context)!;
    // Get product info
    final product = provider.products.firstWhere(
      (p) => p.id == movement.productId,
      orElse: () => throw Exception('Product not found for movement'),
    );

    // Get source location
    String sourceLocation = loc.notAvailable;

    if (movement.sourceWarehouseId != null) {
      final sourceWarehouse = provider.warehouses
          .firstWhere((w) => w.id == movement.sourceWarehouseId);
      sourceLocation = sourceWarehouse.name;
    }

    // Get destination location
    String destinationLocation = loc.notAvailable;
    if (movement.destinationWarehouseId != null) {
      final destWarehouse = provider.warehouses
          .firstWhere((w) => w.id == movement.destinationWarehouseId);
      destinationLocation = destWarehouse.name;
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
        color = AppTheme.primaryColor;
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
            Text('${loc.from}: $sourceLocation'),
            Text('${loc.to}: $destinationLocation'),
            Text(
                '${loc.date}: ${formatLocalizedDateTime(context, movement.createdAt.toString())}'),
            if (movement.reference != null)
              Text('${loc.reference}: ${movement.reference}'),
          ],
        ),
        onTap: () => _showMovementDetails(context, provider, movement),
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
    final loc = AppLocalizations.of(context)!;
    if (_startDate == null && _endDate == null) {
      return loc.selectDateRange;
    }
    return '${formatLocalizedDate(context, _startDate.toString())} - ${formatLocalizedDate(context, _endDate.toString())}';
  }

  bool _isWithinDateRange(DateTime date) {
    if (_startDate == null || _endDate == null) return true;
    try {
      return date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
          date.isBefore(_endDate!.add(const Duration(days: 1)));
    } catch (e) {
      // debugPrint('Error parsing date: $e');
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
    final loc = AppLocalizations.of(context)!;
    // Get product
    final product = provider.products.firstWhere(
      (p) => p.id == movement.productId,
      orElse: () => throw Exception('Product not found for movement'),
    );

    // Get unit
    final unitName = provider.getUnitName(product.unitId);

    // Get locations
    String sourceLocation = loc.notAvailable;
    if (movement.sourceWarehouseId != null) {
      final sourceWarehouse = provider.warehouses
          .firstWhere((w) => w.id == movement.sourceWarehouseId);
      sourceLocation = sourceWarehouse.name;
    }

    String destinationLocation = loc.notAvailable;
    if (movement.destinationWarehouseId != null) {
      final destWarehouse = provider.warehouses
          .firstWhere((w) => w.id == movement.destinationWarehouseId);
      destinationLocation = destWarehouse.name;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.movementDetails,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(loc.product, product.name),
                    _buildDetailRow(
                        loc.type, movement.type.toString().split('.').last),
                    _buildDetailRow(
                        loc.quantity, '${movement.quantity} $unitName'),
                    _buildDetailRow(loc.source, sourceLocation),
                    _buildDetailRow(loc.description, destinationLocation),
                    if (movement.reference != null)
                      _buildDetailRow(loc.reference, movement.reference!),
                    if (movement.notes != null)
                      _buildDetailRow(loc.notes, movement.notes!),
                    if (movement.expiryDate != null)
                      _buildDetailRow(
                          loc.expiryDate,
                          formatLocalizedDate(
                              context, movement.expiryDate.toString())),
                    _buildDetailRow(
                        loc.createdAt,
                        formatLocalizedDateTime(
                            context, movement.createdAt.toString())),
                  ],
                ),
              ),
            ),
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
