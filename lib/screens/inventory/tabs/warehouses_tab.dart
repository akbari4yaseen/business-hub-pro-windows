import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../dialogs/add_warehouse_dialog.dart';
import '../dialogs/edit_warehouse_dialog.dart';
import '../dialogs/move_stock_dialog.dart';
import '../../../providers/inventory_provider.dart';
import '../../../models/warehouse.dart';

class WarehousesTab extends StatefulWidget {
  const WarehousesTab({Key? key}) : super(key: key);

  @override
  State<WarehousesTab> createState() => _WarehousesTabState();
}

class _WarehousesTabState extends State<WarehousesTab> {
  String _searchQuery = '';
  bool _showEmpty = true;
  static final NumberFormat numberFormatter = NumberFormat('#,###.##');

  Map<String, List<Map<String, dynamic>>> _groupStockByWarehouse(
      List<Map<String, dynamic>> stock) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in stock) {
      final warehouseName = item['warehouse_name'] as String;
      grouped.putIfAbsent(warehouseName, () => []);
      grouped[warehouseName]!.add(item);
    }
    return grouped;
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

          // Group stock by warehouse - moved to a separate method for better organization
          final warehouseStock = _groupStockByWarehouse(provider.currentStock);

          // Filter warehouses based on search
          final filteredWarehouses = provider.warehouses.where((warehouse) {
            final matchesSearch = warehouse.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
            final hasItems =
                warehouseStock[warehouse.name]?.isNotEmpty ?? false;
            return matchesSearch && (_showEmpty || hasItems);
          }).toList();

          if (filteredWarehouses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.no_warehouses_found,
                    style: TextStyle(fontSize: 16),
                  ),
                  if (_searchQuery.isNotEmpty || _showEmpty)
                    TextButton(
                      onPressed: () => setState(() {
                        _searchQuery = '';
                        _showEmpty = false;
                      }),
                      child: Text(loc.clear_filters),
                    ),
                  ElevatedButton.icon(
                    onPressed: () => provider.refreshWarehouses(),
                    icon: const Icon(Icons.refresh),
                    label: Text(loc.refresh_warehouses),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: loc.search_warehouses,
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilterChip(
                      label: Text(loc.show_empty),
                      selected: _showEmpty,
                      onSelected: (value) => setState(() => _showEmpty = value),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      tooltip: loc.refresh_warehouses,
                      onPressed: () => provider.refreshWarehouses(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 80,
                  ),
                  itemCount: filteredWarehouses.length,
                  itemBuilder: (context, index) {
                    final warehouse = filteredWarehouses[index];
                    final items = warehouseStock[warehouse.name] ?? [];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        title: Text(warehouse.name),
                        subtitle: Text(
                            '${numberFormatter.format(items.length)} ${loc.items}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: loc.edit_warehouse,
                              onPressed: () =>
                                  _handleWarehouseAction('edit', warehouse),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: loc.delete_warehouse,
                              onPressed: items.isEmpty
                                  ? () => _handleWarehouseAction(
                                      'delete', warehouse)
                                  : null,
                            ),
                          ],
                        ),
                        children: _buildWarehouseItems(items),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWarehouseDialog(context),
        heroTag: "warehouse_manage_fab",
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildWarehouseItems(List<Map<String, dynamic>> items) {
    final loc = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            loc.no_items_in_warehouse,
          ),
        ),
      ];
    }

    return [
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(item['product_name']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${loc.quantity}: ${numberFormatter.format(item['quantity'])} ${item['unit_name'] ?? ''}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => _showMoveStockDialog(context, item),
            ),
          );
        },
      ),
    ];
  }

  void _showAddWarehouseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          ChangeNotifierProvider<InventoryProvider>.value(
        value: context.read<InventoryProvider>(),
        child: const AddWarehouseDialog(),
      ),
    );
  }

  Future<void> _handleWarehouseAction(
      String action, Warehouse warehouse) async {
    final provider = context.read<InventoryProvider>();
    final loc = AppLocalizations.of(context)!;
    try {
      switch (action) {
        case 'edit':
          await showDialog(
            context: context,
            builder: (context) =>
                ChangeNotifierProvider<InventoryProvider>.value(
              value: provider,
              child: EditWarehouseDialog(warehouse: warehouse),
            ),
          );
          break;
        case 'delete':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(loc.delete_warehouse),
              content: Text(
                '${loc.delete_warehouse_confirm(warehouse.name)}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(loc.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(loc.delete),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await provider.deleteWarehouse(warehouse.id!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.warehouse_deleted)),
            );
          }
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.error}: $e')),
      );
    }
  }

  Future<void> _showMoveStockDialog(
      BuildContext context, Map<String, dynamic> item) async {
    await showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider<InventoryProvider>.value(
        value: context.read<InventoryProvider>(),
        child: MoveStockDialog(stockItem: item),
      ),
    );
  }
}
