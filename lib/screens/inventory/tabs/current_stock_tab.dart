import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/search_filter_bar.dart';
import '../../../providers/inventory_provider.dart';
import '../../../widgets/inventory/current_stock_table.dart';

class CurrentStockTab extends StatefulWidget {
  const CurrentStockTab({Key? key}) : super(key: key);

  @override
  State<CurrentStockTab> createState() => _CurrentStockTabState();
}

class _CurrentStockTabState extends State<CurrentStockTab> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedWarehouse;
  String? _selectedCategory;

  // Cache the unique values to avoid recalculating them on every build
  List<String> _getUniqueWarehouses(List<Map<String, dynamic>> stock) {
    return stock.map((e) => e['warehouse_name'] as String).toSet().toList()
      ..sort();
  }

  List<String> _getUniqueCategories(List<Map<String, dynamic>> stock) {
    return stock.map((e) => e['category_name'] as String? ?? 'Uncategorized').toSet().toList()
      ..sort();
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
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${loc.error}: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.initialize(),
                    child: Text(loc.retry),
                  ),
                ],
              ),
            );
          }

          final currentStock = provider.currentStock;
          final warehouses = _getUniqueWarehouses(currentStock);
          final categories = _getUniqueCategories(currentStock);

          // Apply filters
          final filteredStock = currentStock.where((stock) {
            final matchesSearch = stock['product_name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
            final matchesWarehouse = _selectedWarehouse == null ||
                stock['warehouse_name'] == _selectedWarehouse;
            final matchesCategory = _selectedCategory == null ||
                stock['category_name'] == _selectedCategory;
            return matchesSearch && matchesWarehouse && matchesCategory;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              try {
                await provider.initialize();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error refreshing data: $e')),
                  );
                }
              }
            },
            child: CurrentStockTable(
              items: filteredStock,
              scrollController: _scrollController,
              isLoading: provider.isLoading,
              hasMore: false, // Current stock doesn't have pagination
              filters: _buildFilters(warehouses, categories, loc),
              lowStockProducts: provider.lowStockProducts,
              expiringProducts: provider.expiringProducts,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters(List<String> warehouses, List<String> categories, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SearchFilterBar(
            onSearchChanged: (query) => setState(() => _searchQuery = query),
            onWarehouseChanged: (warehouse) => setState(() => _selectedWarehouse = warehouse),
            onCategoryChanged: (category) => setState(() => _selectedCategory = category),
            warehouses: warehouses,
            categories: categories,
          ),
          if (_searchQuery.isNotEmpty ||
              _selectedWarehouse != null ||
              _selectedCategory != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Text('${loc.activeFilters}:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _searchQuery = '';
                      _selectedWarehouse = null;
                      _selectedCategory = null;
                    }),
                    child: Text(loc.clearAll),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
