import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import 'tabs/current_stock_tab.dart';
import 'tabs/products_tab.dart';
import 'tabs/warehouses_tab.dart';
import 'tabs/stock_movements_tab.dart';

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
    Future.microtask(() => context.read<InventoryProvider>().initialize());
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: ScrollConfiguration(
            behavior: NoGlowScrollBehavior(),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.inventory_2),
                    child: Text(
                      'Current Stock',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Tab(
                    icon: Icon(Icons.category),
                    child: Text(
                      'Products',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Tab(
                    icon: Icon(Icons.warehouse),
                    child: Text(
                      'Warehouses',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Tab(
                    icon: Icon(Icons.swap_horiz),
                    child: Text(
                      'Stock Movements',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
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

// Disable overscroll glow (removes fade effect on scroll)
class NoGlowScrollBehavior extends ScrollBehavior {
  Widget buildViewportChrome(
    BuildContext context,
    Widget child,
    AxisDirection axisDirection,
  ) {
    return child;
  }
}
