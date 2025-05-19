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
  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isInitializing = true;
        _error = null;
      });
      
      final provider = context.read<InventoryProvider>();
      await provider.initialize();
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _error = e.toString();
        });
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isInitializing ? null : _initializeData,
            tooltip: 'Refresh Data',
          ),
        ],
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
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
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
