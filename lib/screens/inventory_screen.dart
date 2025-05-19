import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/invoice_provider.dart';

import './inventory/tabs/warehouses_tab.dart';
import './inventory/tabs/products_tab.dart';
import './inventory/tabs/current_stock_tab.dart';
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
    );
  }
}
