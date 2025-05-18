import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/inventory_provider.dart';
import '../widgets/stock_alert_card.dart';
import '../widgets/stock_list.dart';
import '../widgets/search_filter_bar.dart';
import '../add_product_screen.dart';

class CurrentStockTab extends StatefulWidget {
  const CurrentStockTab({Key? key}) : super(key: key);

  @override
  State<CurrentStockTab> createState() => _CurrentStockTabState();
}

class _CurrentStockTabState extends State<CurrentStockTab> {
  String _searchQuery = '';
  String? _selectedWarehouse;
  String? _selectedCategory;

  // Cache the unique values to avoid recalculating them on every build
  List<String> _getUniqueWarehouses(List<Map<String, dynamic>> stock) {
    return stock.map((e) => e['warehouse_name'] as String).toSet().toList()
      ..sort();
  }

  List<String> _getUniqueCategories(List<Map<String, dynamic>> stock) {
    return stock.map((e) => e['category_name'] as String).toSet().toList()
      ..sort();
  }

  void _showAddProductDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.initialize(),
                    child: const Text('Retry'),
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
            child: CustomScrollView(
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
                                const Text('Active filters:'),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _searchQuery = '';
                                    _selectedWarehouse = null;
                                    _selectedCategory = null;
                                  }),
                                  child: const Text('Clear all'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (provider.lowStockProducts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: StockAlertCard(
                      title: 'Low Stock Alerts',
                      icon: Icons.warning,
                      color: Colors.red,
                      items: provider.lowStockProducts,
                    ),
                  ),
                if (provider.expiringProducts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: StockAlertCard(
                      title: 'Expiring Products',
                      icon: Icons.schedule,
                      color: Colors.orange,
                      items: provider.expiringProducts,
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: filteredStock.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No items found',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        )
                      : StockList(items: filteredStock),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        tooltip: 'Add Product',
        heroTag: "add_product_stock",
        child: const Icon(Icons.add),
      ),
    );
  }
}
