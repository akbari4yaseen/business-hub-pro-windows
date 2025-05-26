import 'package:BusinessHubPro/utils/inventory.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../add_stock_movement_screen.dart';
import '../widgets/search_filter_bar.dart';
import '../../../utils/date_formatters.dart';
import '../../../providers/inventory_provider.dart';
import '../../../models/stock_movement.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/inventory/movement_details_sheet.dart';

class StockMovementsTab extends StatefulWidget {
  const StockMovementsTab({Key? key}) : super(key: key);

  @override
  State<StockMovementsTab> createState() => _StockMovementsTabState();
}

class _StockMovementsTabState extends State<StockMovementsTab> {
  final ScrollController _scrollController = ScrollController();
  final NumberFormat _numberFormatter = NumberFormat('#,###.##');

  String _searchQuery = '';
  String? _selectedWarehouse;
  String? _selectedCategory;
  MovementType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isAtTop = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<InventoryProvider>().loadStockMovements();
    }

    final atTop = position.pixels <= 0;
    if (atTop != _isAtTop) {
      setState(() => _isAtTop = atTop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          final filteredMovements = _filterMovements(provider);

          return RefreshIndicator(
            onRefresh: () => provider.loadStockMovements(refresh: true),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildFilters(provider, loc)),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: filteredMovements.isEmpty
                      ? _buildEmptyState(loc)
                      : _buildMovementList(
                          context, provider, filteredMovements),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  List<StockMovement> _filterMovements(InventoryProvider provider) {
    return provider.stockMovements.where((movement) {
      final product = provider.products.firstWhere(
        (p) => p.id == movement.productId,
        orElse: () => throw Exception('Product not found'),
      );

      final matchesSearch =
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType =
          _selectedType == null || movement.type == _selectedType;
      final matchesDate = _isWithinDateRange(movement.date!);

      return matchesSearch && matchesType && matchesDate;
    }).toList();
  }

  Widget _buildFilters(InventoryProvider provider, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SearchFilterBar(
            onSearchChanged: (query) => setState(() => _searchQuery = query),
            onWarehouseChanged: (w) => setState(() => _selectedWarehouse = w),
            onCategoryChanged: (c) => setState(() => _selectedCategory = c),
            warehouses: provider.warehouses.map((w) => w.name).toList(),
            categories: provider.categories.map((c) => c.name).toList(),
          ),
          const SizedBox(height: 8),
          _buildTypeFilter(loc),
          const SizedBox(height: 8),
          _buildDateRangeFilter(loc),
        ],
      ),
    );
  }

  Widget _buildTypeFilter(AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DropdownButtonFormField<MovementType>(
          isDense: true,
          decoration: InputDecoration(
            labelText: loc.movementType,
            hintText: loc.allTypes,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          value: _selectedType,
          items: [
            DropdownMenuItem(value: null, child: Text(loc.allTypes)),
            ...MovementType.values.map(
              (type) => DropdownMenuItem(
                  value: type, child: Text(type.localized(context))),
            ),
          ],
          onChanged: (value) => setState(() => _selectedType = value),
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter(AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(_getDateRangeText(loc)),
                onPressed: () => _selectDateRange(context),
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

  Widget _buildEmptyState(AppLocalizations loc) {
    return SliverFillRemaining(
      child: Center(
        child: Text(loc.noMovementsFound, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildMovementList(BuildContext context, InventoryProvider provider,
      List<StockMovement> movements) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == movements.length) {
            return provider.isLoadingMovements
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }

          return _buildMovementCard(context, provider, movements[index]);
        },
        childCount: movements.length + 1,
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      heroTag: "stock_movement_fab",
      mini: !_isAtTop,
      onPressed: () {
        _isAtTop
            ? _showAddMovementDialog(context)
            : _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              );
      },
      child: FaIcon(
        _isAtTop ? FontAwesomeIcons.plus : FontAwesomeIcons.angleUp,
        size: 18,
      ),
    );
  }

  bool _isWithinDateRange(DateTime date) {
    if (_startDate == null || _endDate == null) return true;
    return date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
        date.isBefore(_endDate!.add(const Duration(days: 1)));
  }

  String _getDateRangeText(AppLocalizations loc) {
    if (_startDate == null && _endDate == null) return loc.selectDateRange;
    return '${formatLocalizedDate(context, _startDate.toString())} - ${formatLocalizedDate(context, _endDate.toString())}';
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
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

  void _showAddMovementDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddStockMovementScreen()),
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
              '${movement.type.localized(context)} - ${_numberFormatter.format(movement.quantity)} $unitName',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            Text('${loc.from}: $sourceLocation'),
            Text('${loc.to}: $destinationLocation'),
            Text(
                '${formatLocalizedDateTime(context, movement.date.toString())}'),
            if (movement.reference != null)
              Text('${loc.reference}: ${movement.reference}'),
          ],
        ),
        onTap: () => _showMovementDetails(context, provider, movement),
      ),
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
      builder: (context) => MovementDetailsSheet(
        movement: movement,
        product: product,
        sourceLocation: sourceLocation,
        destinationLocation: destinationLocation,
        unitName: unitName,
        numberFormatter: _numberFormatter,
      ),
    );
  }
}
