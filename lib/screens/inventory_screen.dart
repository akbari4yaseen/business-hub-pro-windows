import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/invoice_provider.dart';
import '../widgets/invoice/invoice_list.dart';
import '../models/stock_movement.dart';
import '../models/warehouse.dart';
import '../models/zone.dart';
import '../models/bin.dart';
import '../models/product.dart';
import '../models/unit.dart';
import '../models/category.dart' as inventory_models;
import './create_invoice_screen.dart';
import './inventory/dialogs/add_warehouse_dialog.dart';
import './inventory/dialogs/add_product_dialog.dart';
import './inventory/dialogs/add_stock_movement_dialog.dart';
import './inventory/dialogs/edit_warehouse_dialog.dart';
import './inventory/dialogs/manage_zones_dialog.dart';
import './inventory/dialogs/move_stock_dialog.dart';
import './inventory/tabs/warehouses_tab.dart';
import './inventory/tabs/current_stock_tab.dart';
import './inventory/tabs/products_tab.dart';
import './inventory/tabs/stock_movements_tab.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Initialize inventory data
    Future.microtask(() async {
      await context.read<InventoryProvider>().initialize();
      // Force a specific refresh of warehouses and products data
      await context.read<InventoryProvider>().refreshWarehouses();
      await context.read<InventoryProvider>().refreshProducts();
      await context.read<InvoiceProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Current Stock'),
            Tab(text: 'Products'),
            Tab(text: 'Warehouses'),
            Tab(text: 'Stock Movements'),
            Tab(text: 'Invoices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const CurrentStockTab(),
          const ProductsTab(),
          const WarehousesTab(),
          const StockMovementsTab(),
          Consumer<InvoiceProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return InvoiceList(
                invoices: provider.invoices,
                onPaymentRecorded: (invoice, amount) async {
                  await provider.recordPayment(invoice.id!, amount);
                },
                onInvoiceFinalized: (invoice) async {
                  await provider.finalizeInvoice(invoice);
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_tabController.index == 4) { // Invoices tab
      return FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateInvoiceScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Invoice',
      );
    }
    return FloatingActionButton(
      onPressed: () {
        switch (_tabController.index) {
          case 1: // Products tab
            showDialog(
              context: context,
              builder: (context) => ChangeNotifierProvider<InventoryProvider>.value(
                value: context.read<InventoryProvider>(),
                child: const AddProductDialog(),
              ),
            );
            break;
          case 2: // Warehouses tab
            showDialog(
              context: context,
              builder: (dialogContext) => ChangeNotifierProvider<InventoryProvider>.value(
                value: context.read<InventoryProvider>(),
                child: const AddWarehouseDialog(),
              ),
            );
            break;
          case 3: // Stock Movements tab
            showDialog(
              context: context,
              builder: (context) => const AddStockMovementDialog(),
            );
            break;
        }
      },
      child: const Icon(Icons.add),
    );
  }
}

class CurrentStockTab extends StatelessWidget {
  const CurrentStockTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        final currentStock = provider.currentStock;
        final lowStockProducts = provider.lowStockProducts;
        final expiringProducts = provider.expiringProducts;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lowStockProducts.isNotEmpty) ...[
                  const Text(
                    'Low Stock Alerts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lowStockProducts.length,
                      itemBuilder: (context, index) {
                        final product = lowStockProducts[index];
                        return ListTile(
                          title: Text(product['product_name']),
                          subtitle: Text(
                            'Current: ${product['current_stock']} / Minimum: ${product['minimum_stock']}',
                          ),
                          leading: const Icon(
                            Icons.warning,
                            color: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (expiringProducts.isNotEmpty) ...[
                  const Text(
                    'Expiring Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: expiringProducts.length,
                      itemBuilder: (context, index) {
                        final product = expiringProducts[index];
                        return ListTile(
                          title: Text(product['product_name']),
                          subtitle: Text(
                            'Location: ${product['warehouse_name']} > ${product['zone_name']} > ${product['bin_name']}\n'
                            'Expires: ${product['expiry_date']}',
                          ),
                          leading: const Icon(
                            Icons.schedule,
                            color: Colors.orange,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Current Stock',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentStock.length,
                    itemBuilder: (context, index) {
                      final stock = currentStock[index];
                      return ListTile(
                        title: Text(stock['product_name']),
                        subtitle: Text(
                          'Location: ${stock['warehouse_name']} > ${stock['zone_name']} > ${stock['bin_name']}\n'
                          'Quantity: ${stock['quantity']}',
                        ),
                        trailing: stock['expiry_date'] != null
                            ? Text('Expires: ${stock['expiry_date']}')
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ManageCategoriesDialog extends StatelessWidget {
  const ManageCategoriesDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Categories'),
      content: SizedBox(
        width: double.maxFinite,
        child: Consumer<InventoryProvider>(
          builder: (context, provider, child) {
            return ListView.builder(
              shrinkWrap: true,
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                return ListTile(
                  title: Text(category.name),
                  subtitle: category.description != null
                      ? Text(category.description!)
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      provider.deleteCategory(category.id!);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (dialogContext) => ChangeNotifierProvider<InventoryProvider>.value(
                value: context.read<InventoryProvider>(),
                child: const AddCategoryDialog(),
              ),
            );
          },
          child: const Text('Add Category'),
        ),
      ],
    );
  }
}

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({Key? key}) : super(key: key);

  @override
  _AddCategoryDialogState createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final category = inventory_models.Category(
                name: _nameController.text,
                description: _descriptionController.text,
              );

              context.read<InventoryProvider>().addCategory(category);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class ManageUnitsDialog extends StatelessWidget {
  const ManageUnitsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Units'),
      content: SizedBox(
        width: double.maxFinite,
        child: Consumer<InventoryProvider>(
          builder: (context, provider, child) {
            return ListView.builder(
              shrinkWrap: true,
              itemCount: provider.units.length,
              itemBuilder: (context, index) {
                final unit = provider.units[index];
                return ListTile(
                  title: Text(unit.name),
                  subtitle: unit.description != null
                      ? Text(unit.description!)
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (unit.symbol != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            unit.symbol!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          provider.deleteUnit(unit.id!);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (dialogContext) => ChangeNotifierProvider<InventoryProvider>.value(
                value: context.read<InventoryProvider>(),
                child: const AddUnitDialog(),
              ),
            );
          },
          child: const Text('Add Unit'),
        ),
      ],
    );
  }
}

class AddUnitDialog extends StatefulWidget {
  const AddUnitDialog({Key? key}) : super(key: key);

  @override
  _AddUnitDialogState createState() => _AddUnitDialogState();
}

class _AddUnitDialogState extends State<AddUnitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Unit'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Unit Name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a unit name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _symbolController,
              decoration: const InputDecoration(
                labelText: 'Symbol (optional)',
              ),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final unit = Unit(
                name: _nameController.text,
                symbol: _symbolController.text.isEmpty
                    ? null
                    : _symbolController.text,
                description: _descriptionController.text,
              );

              context.read<InventoryProvider>().addUnit(unit);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class StockMovementsTab extends StatelessWidget {
  const StockMovementsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.stockMovements.isEmpty) {
            return const Center(
              child: Text('No stock movements recorded yet'),
            );
          }
          
          return ListView.builder(
            itemCount: provider.stockMovements.length,
            itemBuilder: (context, index) {
              final movement = provider.stockMovements[index];
              
              // Get the product name
              final productName = provider.currentStock
                  .where((stock) => stock['product_id'] == movement.productId)
                  .map((stock) => stock['product_name'] as String)
                  .firstOrNull ?? 'Unknown Product';
              
              // Get location names
              String sourceLocation = 'N/A';
              String destinationLocation = 'N/A';
              
              if (movement.sourceBinId != null) {
                final sourceBin = provider.currentStock
                    .where((stock) => stock['bin_id'] == movement.sourceBinId)
                    .firstOrNull;
                if (sourceBin != null) {
                  sourceLocation = '${sourceBin['warehouse_name']} > ${sourceBin['zone_name']} > ${sourceBin['bin_name']}';
                }
              }
              
              if (movement.destinationBinId != null) {
                final destBin = provider.currentStock
                    .where((stock) => stock['bin_id'] == movement.destinationBinId)
                    .firstOrNull;
                if (destBin != null) {
                  destinationLocation = '${destBin['warehouse_name']} > ${destBin['zone_name']} > ${destBin['bin_name']}';
                }
              }
              
              // Get movement type icon and color
              IconData typeIcon;
              Color typeColor;
              switch (movement.type) {
                case MovementType.stockIn:
                  typeIcon = Icons.add_box;
                  typeColor = Colors.green;
                  break;
                case MovementType.stockOut:
                  typeIcon = Icons.remove_circle;
                  typeColor = Colors.red;
                  break;
                case MovementType.transfer:
                  typeIcon = Icons.swap_horiz;
                  typeColor = Colors.blue;
                  break;
                case MovementType.adjustment:
                  typeIcon = Icons.tune;
                  typeColor = Colors.orange;
                  break;
              }
              
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: typeColor.withOpacity(0.2),
                    child: Icon(typeIcon, color: typeColor),
                  ),
                  title: Text(productName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${movement.type.toString().split('.').last}'),
                      Text('Quantity: ${movement.quantity.toString()}'),
                      Text('From: $sourceLocation'),
                      Text('To: $destinationLocation'),
                      if (movement.reference != null && movement.reference!.isNotEmpty)
                        Text('Reference: ${movement.reference}'),
                      if (movement.expiryDate != null)
                        Text('Expires: ${movement.expiryDate?.toString().split(' ')[0] ?? 'N/A'}'),
                      Text('Date: ${movement.createdAt.toString().split('.')[0]}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddStockMovementDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 