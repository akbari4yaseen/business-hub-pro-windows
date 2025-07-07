import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../database/purchase_db.dart';
import '../../utils/date_time_picker_helper.dart';
import '../../utils/date_formatters.dart' as dFormatter;

final _amountFormatter = NumberFormat('#,##0.##');

class PurchaseReportsScreen extends StatefulWidget {
  const PurchaseReportsScreen({Key? key}) : super(key: key);

  @override
  _PurchaseReportsScreenState createState() => _PurchaseReportsScreenState();
}

class _PurchaseReportsScreenState extends State<PurchaseReportsScreen>
    with TickerProviderStateMixin {
  final PurchaseDBHelper _db = PurchaseDBHelper();

  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _searchQuery;
  int? _selectedSupplierId;
  String? _selectedCurrency;

  // Data
  bool _isLoading = false;
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<String> _currencies = [];

  // Summary data
  Map<String, double> _currencyTotals = {};
  Map<String, int> _supplierCounts = {};
  Map<String, double> _supplierTotals = {};
  Map<String, int> _productCounts = {};
  Map<String, Map<String, double>> _productTotals = {};

  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Load suppliers
      final suppliers = await _db.getSuppliers();
      setState(() => _suppliers = suppliers);

      // Load currencies
      final currencies = await _db.getCurrencies();
      setState(() => _currencies = currencies);

      await _fetchPurchases();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPurchases() async {
    setState(() => _isLoading = true);

    try {
      final purchases = await _db.getPurchases(
        startDate: _startDate,
        endDate: _endDate,
        searchQuery: _searchQuery,
        supplierId: _selectedSupplierId,
      );

      // Filter by currency if selected
      final filteredPurchases = _selectedCurrency != null
          ? purchases.where((p) => p['currency'] == _selectedCurrency).toList()
          : purchases;

      _calculateSummaries(filteredPurchases);

      setState(() {
        _purchases = filteredPurchases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching purchases: $e')),
      );
    }
  }

  void _calculateSummaries(List<Map<String, dynamic>> purchases) {
    // Reset summaries
    _currencyTotals.clear();
    _supplierCounts.clear();
    _supplierTotals.clear();
    _productCounts.clear();
    _productTotals.clear();

    for (final purchase in purchases) {
      final amount = (purchase['total_amount'] as num?)?.toDouble() ?? 0;
      final currency = purchase['currency'] as String? ?? '';
      final supplierId = purchase['supplier_id'] as int?;
      final supplierName = purchase['supplier_name'] as String? ?? 'Unknown';

      // Currency totals
      _currencyTotals[currency] = (_currencyTotals[currency] ?? 0) + amount;

      // Supplier analysis
      if (supplierId != null) {
        _supplierCounts[supplierName] =
            (_supplierCounts[supplierName] ?? 0) + 1;
        _supplierTotals[supplierName] =
            (_supplierTotals[supplierName] ?? 0) + amount;
      }
    }

    // Product analysis (would need to fetch purchase items)
    _analyzeProducts(purchases);
  }

  Future<void> _analyzeProducts(List<Map<String, dynamic>> purchases) async {
    _productCounts.clear();
    _productTotals.clear();
    for (final purchase in purchases) {
      final purchaseId = purchase['id'] as int?;
      if (purchaseId != null) {
        final items = await _db.getPurchaseItems(purchaseId);
        for (final item in items) {
          final productName =
              item['product_name'] as String? ?? 'Unknown Product';
          final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
          final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0;
          final currency = item['currency'] as String? ??
              (purchase['currency'] as String? ?? '');
          final totalCost = quantity * unitPrice;
          _productCounts[productName] = (_productCounts[productName] ?? 0) + 1;
          _productTotals[productName] ??= {};
          _productTotals[productName]![currency] =
              (_productTotals[productName]![currency] ?? 0) + totalCost;
        }
      }
    }
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_endDate ?? now);
    final picked = await pickLocalizedDate(
      context: context,
      initialDate: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _fetchPurchases();
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _searchQuery = null;
      _selectedSupplierId = null;
      _selectedCurrency = null;
    });
    _fetchPurchases();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.purchaseReports),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: loc.summary),
            Tab(icon: Icon(Icons.list), text: loc.purchases),
            Tab(icon: Icon(Icons.people), text: loc.suppliers),
            Tab(icon: Icon(Icons.inventory), text: loc.products),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(context, true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: loc.startDate,
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_startDate != null
                              ? dFormatter.formatLocalizedDate(
                                  context, _startDate.toString())
                              : '-'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(context, false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: loc.endDate,
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_endDate != null
                              ? dFormatter.formatLocalizedDate(
                                  context, _endDate.toString())
                              : '-'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: loc.search,
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) {
                          _searchQuery = val;
                          _fetchPurchases();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: loc.currency,
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedCurrency,
                        items: [
                          DropdownMenuItem(value: null, child: Text(loc.all)),
                          ..._currencies.map((currency) => DropdownMenuItem(
                                value: currency,
                                child: Text(currency),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCurrency = value);
                          _fetchPurchases();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: loc.supplier,
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedSupplierId,
                        items: [
                          DropdownMenuItem(value: null, child: Text(loc.all)),
                          ..._suppliers.map((supplier) => DropdownMenuItem(
                                value: supplier['id'] as int,
                                child: Text(supplier['name'] as String),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedSupplierId = value);
                          _fetchPurchases();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _clearFilters,
                      icon: Icon(Icons.clear),
                      label: Text(loc.clear),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(loc, theme),
                _buildPurchasesTab(loc, theme),
                _buildSuppliersTab(loc, theme),
                _buildProductsTab(loc, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(AppLocalizations loc, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: loc.totalPurchases(_purchases.length),
                  subtitle:
                      '${_purchases.length} ${loc.purchases.toLowerCase()}',
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: _currencyTotals.length.toString(),
                  subtitle: loc.currencies,
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: _supplierCounts.length.toString(),
                  subtitle: loc.suppliers,
                  icon: Icons.people,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: _productCounts.length.toString(),
                  subtitle: loc.products,
                  icon: Icons.inventory,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Currency Breakdown
          Text(
            loc.currencies,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ..._currencyTotals.entries.map((entry) => Card(
                child: ListTile(
                  leading: Icon(Icons.monetization_on, color: Colors.green),
                  title: Text(entry.key),
                  trailing: Text(
                    _amountFormatter.format(entry.value),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPurchasesTab(AppLocalizations loc, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_purchases.isEmpty) {
      return Center(child: Text(loc.noDataAvailable));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _purchases.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final purchase = _purchases[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: Icon(Icons.shopping_cart, color: Colors.blue),
            ),
            title: Text(purchase['invoice_number'] ?? '-'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(purchase['supplier_name'] ?? '-'),
                Text(dFormatter.formatLocalizedDateTime(
                    context, purchase['date'])),
                if (purchase['notes'] != null && purchase['notes'].isNotEmpty)
                  Text(purchase['notes'], style: theme.textTheme.bodySmall),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_amountFormatter.format(purchase['total_amount'])} ${purchase['currency'] ?? ''}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (purchase['additional_cost'] != null &&
                    purchase['additional_cost'] > 0)
                  Text(
                    '+${_amountFormatter.format(purchase['additional_cost'])} ${loc.additionalCost}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.orange),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuppliersTab(AppLocalizations loc, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_supplierTotals.isEmpty) {
      return Center(child: Text(loc.noDataAvailable));
    }

    final sortedSuppliers = _supplierTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSuppliers.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final entry = sortedSuppliers[index];
        final count = _supplierCounts[entry.key] ?? 0;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: Icon(Icons.people, color: Colors.orange),
            ),
            title: Text(entry.key),
            subtitle: Text('${loc.purchases}: $count'),
            trailing: Text(
              _amountFormatter.format(entry.value),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsTab(AppLocalizations loc, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_productTotals.isEmpty) {
      return Center(child: Text(loc.noDataAvailable));
    }

    final sortedProducts = _productTotals.entries.toList()
      ..sort((a, b) {
        // Sort by total of all currencies descending
        final aTotal = a.value.values.fold(0.0, (sum, v) => sum + v);
        final bTotal = b.value.values.fold(0.0, (sum, v) => sum + v);
        return bTotal.compareTo(aTotal);
      });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedProducts.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final entry = sortedProducts[index];
        final productName = entry.key;
        final currencyMap = entry.value;
        final count = _productCounts[productName] ?? 0;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withValues(alpha: 0.1),
              child: Icon(Icons.inventory, color: Colors.purple),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName),
                      Text('${loc.purchases}: $count',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...currencyMap.entries.map((e) => Padding(
                          padding:
                              const EdgeInsets.only(left: 12.0, bottom: 2.0),
                          child: Text(
                            '${_amountFormatter.format(e.value)} ${e.key}',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
