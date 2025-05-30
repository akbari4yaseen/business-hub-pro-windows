import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    Future.microtask(() async {
      if (!mounted) return;
      await context.read<InventoryProvider>().initialize();
      if (!mounted) return;
      await context.read<InventoryProvider>().refreshWarehouses();
      if (!mounted) return;
      await context.read<InventoryProvider>().refreshProducts();
      if (!mounted) return;
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
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(local.inventoryManagement),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: local.currentStock),
            Tab(text: local.products),
            Tab(text: local.warehouses),
            Tab(text: local.stockMovements),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CurrentStockTab(),
          ProductsTab(),
          WarehousesTab(),
          StockMovementsTab(),
        ],
      ),
    );
  }
}
