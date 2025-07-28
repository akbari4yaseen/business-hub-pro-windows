import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../utils/date_time_picker_helper.dart';
import '../../../utils/date_formatters.dart' as dFormatter;
import '../add_stock_movement_dialog.dart';
import '../widgets/search_filter_bar.dart';
import '../../../utils/inventory.dart';

import '../../../providers/inventory_provider.dart';
import '../../../models/stock_movement.dart';
import '../../../widgets/inventory/stock_movement_table.dart';

class StockMovementsTab extends StatefulWidget {
  const StockMovementsTab({Key? key}) : super(key: key);

  @override
  State<StockMovementsTab> createState() => _StockMovementsTabState();
}

class _StockMovementsTabState extends State<StockMovementsTab> {
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  MovementType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          final filteredMovements = _filterMovements(provider);

          return RefreshIndicator(
            onRefresh: () => provider.loadStockMovements(refresh: true),
            child: StockMovementTable(
              movements: filteredMovements,
              scrollController: _scrollController,
              isLoading: provider.isLoadingMovements,
              hasMore: provider.hasMoreMovements,
              filters: _buildFilters(provider, loc),
              onDelete: (movement) async {
                try {
                  await provider.deleteStockMovement(movement.id);
                  await provider.loadStockMovements(refresh: true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.stockMovementDeleted)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.errorDeletingStockMovement)),
                    );
                  }
                }
              },
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
      final matchesDate = _isWithinDateRange(movement.date);

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
            onWarehouseChanged: (w) => setState(() {}),
            onCategoryChanged: (c) => setState(() {}),
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

  Widget _buildFAB() {
    final loc = AppLocalizations.of(context)!;
    
    return FloatingActionButton.extended(
      heroTag: "stock_movement_fab",
      onPressed: () {
        _showAddMovementDialog();
      },
      tooltip: loc.newStockMovement,
      icon: FaIcon(
        FontAwesomeIcons.plus,
        size: 18,
      ),
      label: Text(loc.newStockMovement),
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
}
