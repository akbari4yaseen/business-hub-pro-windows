import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/invoice_provider.dart';

import '../models/unit.dart';
import '../models/category.dart' as inventory_models;
import './inventory/dialogs/add_warehouse_dialog.dart';

import './inventory/tabs/warehouses_tab.dart';
import './inventory/tabs/products_tab.dart';
import './inventory/tabs/current_stock_tab.dart';
import './inventory/tabs/stock_movements_tab.dart';

import './inventory/add_product_screen.dart';
import './inventory/add_stock_movement_screen.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        switch (_tabController.index) {
          case 1: // Products tab
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddProductScreen(),
              ),
            );
            break;
          case 2: // Warehouses tab
            showDialog(
              context: context,
              builder: (dialogContext) =>
                  ChangeNotifierProvider<InventoryProvider>.value(
                value: context.read<InventoryProvider>(),
                child: const AddWarehouseDialog(),
              ),
            );
            break;
          case 3: // Stock Movements tab
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddStockMovementScreen(),
              ),
            );
            break;
        }
      },
      child: const Icon(Icons.add),
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
              builder: (dialogContext) =>
                  ChangeNotifierProvider<InventoryProvider>.value(
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
                  subtitle:
                      unit.description != null ? Text(unit.description!) : null,
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
              builder: (dialogContext) =>
                  ChangeNotifierProvider<InventoryProvider>.value(
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
