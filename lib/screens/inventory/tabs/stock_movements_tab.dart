import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../utils/date_time_picker_helper.dart';
import '../../../utils/date_formatters.dart' as dFormatter;
import '../add_stock_movement_dialog.dart';
import '../widgets/search_filter_bar.dart';
import '../../../utils/inventory.dart';

import '../../../providers/inventory_provider.dart';
import '../../../models/stock_movement.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/inventory/movement_details_sheet.dart';
import '../../../widgets/auth_widget.dart';

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
    // Initialize stock movements
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadStockMovements(refresh: true);
    });
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
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 80,
                  ),
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
                icon: const Icon(Icons.calendar_today),
                label: Text(_startDate == null
                    ? loc.startDate
                    : dFormatter.formatLocalizedDate(
                        context, _startDate.toString())),
                onPressed: () => _selectStartDate(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(_endDate == null
                    ? loc.endDate
                    : dFormatter.formatLocalizedDate(
                        context, _endDate.toString())),
                onPressed: () => _selectEndDate(context),
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
            ? _showAddMovementDialog()
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

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await pickLocalizedDate(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, update end date
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await pickLocalizedDate(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _showAddMovementDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddStockMovementDialog(
        onSave: (movement) async {
          final provider =
              Provider.of<InventoryProvider>(context, listen: false);
          await provider.recordStockMovement(movement);
          await provider.loadStockMovements(refresh: true);
        },
      ),
    ).then((movement) {
      if (movement != null) {
        final provider = Provider.of<InventoryProvider>(context, listen: false);
        provider.loadStockMovements(refresh: true);
      }
    });
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
      case MovementType.purchase:
        color = Colors.blue;
        icon = Icons.shopping_cart; // 🛒
        break;
      case MovementType.sale:
        color = Colors.purple;
        icon = Icons.sell; // 🏷️
        break;
    }

    // Get unit name
    final unitName = provider.getUnitName(product.baseUnitId);

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
                '${dFormatter.formatLocalizedDateTime(context, movement.date.toString())}'),
            if (movement.reference != null)
              Text('${loc.reference}: ${movement.reference}'),
          ],
        ),
        onTap: () => _showMovementDetails(context, provider, movement),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: loc.delete,
          onPressed: () async {
            // Step 1: authenticate
            showDialog(
              context: context,
              builder: (_) => AuthWidget(
                actionReason: loc.deleteStockMovementAuthMessage,
                onAuthenticated: () {
                  Navigator.of(context).pop(); // Close AuthWidget
                  // Step 2: confirm
                  showDialog(
                    context: context,
                    builder: (confirmCtx) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: AlertDialog(
                          title: Text(loc.confirmDelete),
                          content: Text(loc.confirmDeleteStockMovement),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(confirmCtx).pop(),
                              child: Text(loc.cancel),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(confirmCtx).pop();
                                try {
                                  await provider
                                      .deleteStockMovement(movement.id);
                                  await provider.loadStockMovements(
                                      refresh: true);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text(loc.stockMovementDeleted)),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              loc.errorDeletingStockMovement)),
                                    );
                                  }
                                }
                              },
                              child: Text(
                                loc.delete,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
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
    final unitName = provider.getUnitName(product.baseUnitId);

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

    showDialog(
      context: context,
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
