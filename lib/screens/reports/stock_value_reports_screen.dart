import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../database/reports_db.dart';
import '../../database/inventory_db.dart';
import '../../models/product.dart';
import '../../models/warehouse.dart';
import '../../utils/date_formatters.dart' as dFormatter;
import '../../utils/date_time_picker_helper.dart';

class StockValueReportsScreen extends StatefulWidget {
  const StockValueReportsScreen({Key? key}) : super(key: key);

  @override
  _StockValueReportsScreenState createState() =>
      _StockValueReportsScreenState();
}

class _StockValueReportsScreenState extends State<StockValueReportsScreen>
    with TickerProviderStateMixin {
  final ReportsDBHelper _db = ReportsDBHelper();
  final InventoryDB _inventoryDb = InventoryDB();
  late TabController _tabController;

  DateTime? _expiryDateFrom;
  DateTime? _expiryDateTo;
  Product? _selectedProduct;
  Warehouse? _selectedWarehouse;
  bool _isLoading = false;

  List<Map<String, dynamic>> _stockValues = [];
  List<Map<String, dynamic>> _warehouseSummaries = [];
  List<Map<String, dynamic>> _productSummaries = [];
  List<Map<String, dynamic>> _currencySummaries = [];
  Map<String, dynamic> _totalSummary = {};

  List<Product> _products = [];
  List<Warehouse> _warehouses = [];
  
  final NumberFormat _numberFormatter = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadFiltersAndData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFiltersAndData() async {
    setState(() => _isLoading = true);

    try {
      final products = await _inventoryDb.getProducts();
      final warehouses = await _inventoryDb.getWarehouses();

      setState(() {
        _products = products;
        _warehouses = warehouses;
      });

      await _loadAllData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadStockValues(),
      _loadWarehouseSummaries(),
      _loadProductSummaries(),
      _loadCurrencySummaries(),
      _loadTotalSummary(),
    ]);
  }

  Future<void> _loadStockValues() async {
    final data = await _db.getStockValues(
      expiryDateFrom: _expiryDateFrom,
      expiryDateTo: _expiryDateTo,
      productId: _selectedProduct?.id,
      warehouseId: _selectedWarehouse?.id,
    );
    
    // Calculate total_stock_value in UI
    final calculatedData = data.map((item) {
      final quantity = (item['quantity'] ?? 0).toDouble();
      final unitPrice = (item['unit_price'] ?? 0).toDouble();
      final conversionFactor = (item['conversion_factor'] ?? 1).toDouble();
      final totalStockValue = quantity * unitPrice / conversionFactor;
      
      return {
        ...item,
        'total_stock_value': totalStockValue,
      };
    }).toList();
    
    setState(() => _stockValues = calculatedData);
  }

  // Helper method to format currency based on the currency type
  String _formatCurrencyValue(dynamic value, String currency) {
    final doubleValue = (value ?? 0).toDouble();
    switch (currency.toUpperCase()) {
      case 'USD':
        return NumberFormat.currency(symbol: '\$').format(doubleValue);
      case 'EUR':
        return NumberFormat.currency(symbol: '€').format(doubleValue);
      case 'GBP':
        return NumberFormat.currency(symbol: '£').format(doubleValue);
      case 'AFN':
        return NumberFormat.currency(symbol: '؋').format(doubleValue);
      default:
        return NumberFormat.currency(symbol: currency).format(doubleValue);
    }
  }

  Future<void> _loadWarehouseSummaries() async {
    final data = await _db.getStockValuesByWarehouse(
      expiryDateFrom: _expiryDateFrom,
      expiryDateTo: _expiryDateTo,
    );
    setState(() => _warehouseSummaries = data);
  }

  Future<void> _loadProductSummaries() async {
    final data = await _db.getStockValuesByProduct(
      expiryDateFrom: _expiryDateFrom,
      expiryDateTo: _expiryDateTo,
    );
    setState(() => _productSummaries = data);
  }

  Future<void> _loadCurrencySummaries() async {
    final data = await _db.getStockValuesByCurrency(
      expiryDateFrom: _expiryDateFrom,
      expiryDateTo: _expiryDateTo,
    );
    setState(() => _currencySummaries = data);
  }

  Future<void> _loadTotalSummary() async {
    final data = await _db.getTotalStockValue(
      expiryDateFrom: _expiryDateFrom,
      expiryDateTo: _expiryDateTo,
    );
    setState(() => _totalSummary = data);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.stockValueReports),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: loc.summary),
            Tab(text: loc.detailed),
            Tab(text: loc.byWarehouse),
            Tab(text: loc.byProduct),
            Tab(text: loc.byCurrency),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildDetailedTab(),
                _buildWarehouseTab(),
                _buildProductTab(),
                _buildCurrencyTab(),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildCurrencySummarySection(),
          const SizedBox(height: 24),
          _buildFilterInfo(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          'Total Products',
          '${_totalSummary['total_products'] ?? 0}',
          Icons.inventory,
          Colors.blue,
        ),
        _buildSummaryCard(
          'Total Warehouses',
          '${_totalSummary['total_warehouses'] ?? 0}',
          Icons.warehouse,
          Colors.orange,
        ),
        _buildSummaryCard(
          'Total Quantity',
          _numberFormatter.format((_totalSummary['total_quantity'] ?? 0).toDouble()),
          Icons.shopping_cart,
          Colors.purple,
        ),
        _buildSummaryCard(
          'Currencies',
          '${_currencySummaries.length}',
          Icons.attach_money,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildCurrencySummarySection() {
    final loc = AppLocalizations.of(context)!;
    if (_currencySummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.stockValueByCurrency,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._currencySummaries.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            item['currency'] ?? 'USD',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['currency'] ?? 'USD'} ${loc.stockValue}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${item['product_count'] ?? 0} ${loc.products}, ${item['warehouse_count'] ?? 0} ${loc.warehouses}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrencyValue(
                            item['total_stock_value'],
                            item['currency'] ?? 'USD'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${loc.quantity}: ${_numberFormatter.format((item['total_quantity'] ?? 0).toDouble())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterInfo() {
    final loc = AppLocalizations.of(context)!;
    final filters = <String>[];
    
    if (_expiryDateFrom != null) {
      filters.add('${loc.from}: ${dFormatter.formatDate(_expiryDateFrom!.toIso8601String())}');
    }
    if (_expiryDateTo != null) {
      filters.add('${loc.to}: ${dFormatter.formatDate(_expiryDateTo!.toIso8601String())}');
    }
    if (_selectedProduct != null) {
      filters.add('${loc.product}: ${_selectedProduct!.name}');
    }
    if (_selectedWarehouse != null) {
      filters.add('${loc.warehouse}: ${_selectedWarehouse!.name}');
    }

    if (filters.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.activeFilters,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: filters
                  .map((filter) => Chip(
                        label: Text(filter),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _clearFilters(),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedTab() {
    final loc = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(loc.product)),
                  DataColumn(label: Text(loc.warehouse)),
                  DataColumn(label: Text(loc.quantity)),
                  DataColumn(label: Text(loc.unitPrice)),
                  DataColumn(label: Text(loc.totalValue)),
                  DataColumn(label: Text(loc.currency)),
                  DataColumn(label: Text(loc.expiryDate)),
                ],
                rows: _stockValues
                    .map((item) => DataRow(
                          cells: [
                            DataCell(Text(item['product_name'] ?? '')),
                            DataCell(Text(item['warehouse_name'] ?? '')),
                            DataCell(Text(_numberFormatter
                                .format((item['quantity'] ?? 0).toDouble()))),
                            DataCell(Text(_formatCurrencyValue(
                                item['unit_price'],
                                item['currency'] ?? 'USD'))),
                            DataCell(Text(_formatCurrencyValue(
                                item['total_stock_value'],
                                item['currency'] ?? 'USD'))),
                            DataCell(Text(item['currency'] ?? '')),
                            DataCell(Text(item['expiry_date'] != null
                                ? dFormatter.formatLocalizedDate(
                                    context, item['expiry_date'])
                                : loc.na)),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseTab() {
    final loc = AppLocalizations.of(context)!;
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _warehouseSummaries.length,
      itemBuilder: (context, index) {
        final item = _warehouseSummaries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text(item['warehouse_name'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${loc.products}: ${item['product_count'] ?? 0}'),
                Text(
                    '${loc.totalQuantity}: ${_numberFormatter.format((item['total_quantity'] ?? 0).toDouble())}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrencyValue(
                      item['total_stock_value'],
                      item['currency'] ?? 'USD'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  item['currency'] ?? 'USD',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductTab() {
    final loc = AppLocalizations.of(context)!;
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _productSummaries.length,
      itemBuilder: (context, index) {
        final item = _productSummaries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text(item['product_name'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${loc.warehouses}: ${item['warehouse_count'] ?? 0}'),
                Text(
                    '${loc.totalQuantity}: ${_numberFormatter.format((item['total_quantity'] ?? 0).toDouble())}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrencyValue(
                      item['total_stock_value'],
                      item['currency'] ?? 'USD'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  item['currency'] ?? 'USD',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyTab() {
    final loc = AppLocalizations.of(context)!;
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _currencySummaries.length,
      itemBuilder: (context, index) {
        final item = _currencySummaries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text('${item['currency'] ?? 'USD'}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${loc.products}: ${item['product_count'] ?? 0}'),
                Text('${loc.warehouses}: ${item['warehouse_count'] ?? 0}'),
                Text(
                    '${loc.totalQuantity}: ${_numberFormatter.format((item['total_quantity'] ?? 0).toDouble())}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrencyValue(
                      item['total_stock_value'],
                      item['currency'] ?? 'USD'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  item['currency'] ?? 'USD',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        expiryDateFrom: _expiryDateFrom,
        expiryDateTo: _expiryDateTo,
        selectedProduct: _selectedProduct,
        selectedWarehouse: _selectedWarehouse,
        products: _products,
        warehouses: _warehouses,
        onApply: (expiryFrom, expiryTo, product, warehouse) {
          setState(() {
            _expiryDateFrom = expiryFrom;
            _expiryDateTo = expiryTo;
            _selectedProduct = product;
            _selectedWarehouse = warehouse;
          });
          _loadAllData();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _expiryDateFrom = null;
      _expiryDateTo = null;
      _selectedProduct = null;
      _selectedWarehouse = null;
    });
    _loadAllData();
  }
}

class _FilterDialog extends StatefulWidget {
  final DateTime? expiryDateFrom;
  final DateTime? expiryDateTo;
  final Product? selectedProduct;
  final Warehouse? selectedWarehouse;
  final List<Product> products;
  final List<Warehouse> warehouses;
  final Function(DateTime?, DateTime?, Product?, Warehouse?) onApply;

  const _FilterDialog({
    required this.expiryDateFrom,
    required this.expiryDateTo,
    required this.selectedProduct,
    required this.selectedWarehouse,
    required this.products,
    required this.warehouses,
    required this.onApply,
  });

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  DateTime? _expiryDateFrom;
  DateTime? _expiryDateTo;
  Product? _selectedProduct;
  Warehouse? _selectedWarehouse;

  @override
  void initState() {
    super.initState();
    _expiryDateFrom = widget.expiryDateFrom;
    _expiryDateTo = widget.expiryDateTo;
    _selectedProduct = widget.selectedProduct;
    _selectedWarehouse = widget.selectedWarehouse;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.filters),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(loc.expiryDateFrom),
              subtitle: Text(_expiryDateFrom != null
                  ? dFormatter.formatLocalizedDate(
                      context, _expiryDateFrom!.toString())
                  : loc.selectDate),
              onTap: () async {
                final date = await pickLocalizedDate(
                  context: context,
                  initialDate: _expiryDateFrom ?? DateTime.now(),
                );
                if (date != null) {
                  setState(() => _expiryDateFrom = date);
                }
              },
            ),
            ListTile(
              title: Text(loc.expiryDateTo),
              subtitle: Text(_expiryDateTo != null
                  ? dFormatter.formatLocalizedDate(
                      context, _expiryDateTo!.toString())
                  : loc.selectDate),
              onTap: () async {
                final date = await pickLocalizedDate(
                  context: context,
                  initialDate: _expiryDateTo ?? DateTime.now(),
                );
                if (date != null) {
                  setState(() => _expiryDateTo = date);
                }
              },
            ),
            ListTile(
              title: Text(loc.product),
              subtitle: Text(_selectedProduct?.name ?? loc.allProducts),
              onTap: () => _showProductPicker(),
            ),
            ListTile(
              title: Text(loc.warehouse),
              subtitle: Text(_selectedWarehouse?.name ?? loc.allWarehouses),
              onTap: () => _showWarehousePicker(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _expiryDateFrom = null;
              _expiryDateTo = null;
              _selectedProduct = null;
              _selectedWarehouse = null;
            });
          },
          child: Text(loc.clear),
        ),
        ElevatedButton(
          onPressed: () => widget.onApply(
            _expiryDateFrom,
            _expiryDateTo,
            _selectedProduct,
            _selectedWarehouse,
          ),
          child: Text(loc.apply),
        ),
      ],
    );
  }

  void _showProductPicker() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.product),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.products.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text(loc.allProducts),
                  onTap: () {
                    setState(() => _selectedProduct = null);
                    Navigator.of(context).pop();
                  },
                );
              }
              final product = widget.products[index - 1];
              return ListTile(
                title: Text(product.name),
                onTap: () {
                  setState(() => _selectedProduct = product);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showWarehousePicker() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.warehouse),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.warehouses.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text(loc.allWarehouses),
                  onTap: () {
                    setState(() => _selectedWarehouse = null);
                    Navigator.of(context).pop();
                  },
                );
              }
              final warehouse = widget.warehouses[index - 1];
              return ListTile(
                title: Text(warehouse.name),
                onTap: () {
                  setState(() => _selectedWarehouse = warehouse);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
