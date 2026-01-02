import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../database/invoice_db.dart';
import '../../utils/date_time_picker_helper.dart';
import '../../utils/date_formatters.dart' as dFormatter;

final _amountFormatter = NumberFormat('#,##0.##');

class SalesReportsScreen extends StatefulWidget {
  const SalesReportsScreen({Key? key}) : super(key: key);

  @override
  _SalesReportsScreenState createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends State<SalesReportsScreen>
    with TickerProviderStateMixin {
  final InvoiceDBHelper _db = InvoiceDBHelper();
  
  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _searchQuery;
  String? _selectedCurrency;
  String? _selectedStatus;
  
  // Data
  bool _isLoading = false;
  List<Map<String, dynamic>> _invoices = [];
  List<String> _currencies = [];
  List<String> _statuses = ['draft', 'finalized', 'partially_paid', 'paid', 'cancelled'];
  
  // Summary data
  Map<String, double> _currencyTotals = {};
  Map<String, int> _customerCounts = {};
  Map<String, Map<String, double>> _customerTotals = {};
  Map<String, int> _statusCounts = {};
  
  // Product analysis
  Map<String, int> _productCounts = {};
  Map<String, Map<String, double>> _productTotals = {};
  // Track quantities with units: {productName: {unit1: quantity1, unit2: quantity2, ...}}
  Map<String, Map<String, double>> _productQuantitiesByUnit = {};
  // Product pagination and search
  final int _productPageSize = 20;
  int _productPage = 0;
  bool _hasMoreProducts = true;
  bool _isLoadingMoreProducts = false;
  final TextEditingController _productSearchController = TextEditingController();
  final ScrollController _productScrollController = ScrollController();
  String _currentProductSort = 'total_desc';
  List<MapEntry<String, Map<String, double>>> _sortedProducts = [];
  
  // Tab controller
  late TabController _tabController;
  
  // Pagination state for invoices
  final int _invoicePageSize = 30;
  int _invoicePage = 0;
  bool _hasMoreInvoices = true;
  bool _isLoadingMoreInvoices = false;
  final ScrollController _invoiceScrollController = ScrollController();

  // Pagination state for customers
  final int _customerPageSize = 30;
  int _customerPage = 0;
  bool _hasMoreCustomers = true;
  bool _isLoadingMoreCustomers = false;
  final ScrollController _customerScrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    _tabController = TabController(length: 4, vsync: this);
    _invoiceScrollController.addListener(_onInvoiceScroll);
    _customerScrollController.addListener(_onCustomerScroll);
    _productScrollController.addListener(_onProductScroll);
    _productSearchController.addListener(_onProductSearchChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productSearchController.dispose();
    _productScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      // Load currencies
      final currencies = await _db.getCurrencies();
      if (mounted) {
        setState(() => _currencies = currencies);
      }
      
      await _fetchInvoices(reset: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchInvoices({bool reset = false}) async {
    if (_isLoadingMoreInvoices) return;
    
    if (mounted) {
      setState(() {
        _isLoading = reset ? true : _isLoading;
        _isLoadingMoreInvoices = !reset;
        if (reset) {
          _customerPage = 0;
          _productPage = 0;
          _hasMoreProducts = true;
        }
      });
    }
    
    try {
      if (reset) {
        _invoicePage = 0;
        _hasMoreInvoices = true;
        _invoices.clear();
      }
      
      if (!_hasMoreInvoices && !reset) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoadingMoreInvoices = false;
          });
        }
        return;
      }
      
      final invoices = await _db.getInvoices(
        startDate: _startDate,
        endDate: _endDate,
        searchQuery: _searchQuery,
        status: _selectedStatus,
        limit: _invoicePageSize,
        offset: _invoicePage * _invoicePageSize,
        includeItems: true, // Make sure to include invoice items
      );
      
      if (invoices.isEmpty) {
        if (mounted) {
          setState(() {
            _hasMoreInvoices = false;
            _isLoading = false;
            _isLoadingMoreInvoices = false;
          });
        }
        return;
      }
      
      // Filter by currency if selected
      final filteredInvoices = _selectedCurrency != null
          ? invoices.where((i) => i['currency'] == _selectedCurrency).toList()
          : invoices;
          
      if (reset) {
        _invoices = filteredInvoices;
      } else {
        _invoices.addAll(filteredInvoices);
      }
      
      _calculateSummaries(_invoices);
      
      if (mounted) {
        setState(() {
          _hasMoreInvoices = filteredInvoices.length == _invoicePageSize;
          _invoicePage++;
          _hasMoreCustomers = _customerTotals.length > (_customerPage + 1) * _customerPageSize;
          _isLoading = false;
          _isLoadingMoreInvoices = false;
          
          // Update sorted products when data changes
          if (_productTotals.isNotEmpty) {
            _sortedProducts = _sortProducts();
            _hasMoreProducts = _sortedProducts.length > _productPageSize;
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMoreInvoices = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching invoices: $e')),
      );
    }
  }

  void _calculateSummaries(List<Map<String, dynamic>> invoices) {
    if (invoices.isEmpty) return;
    
    // Reset summaries if it's a fresh load
    if (_invoicePage == 0) {
      _currencyTotals.clear();
      _customerCounts.clear();
      _customerTotals.clear();
      _statusCounts.clear();
      _productCounts.clear();
      _productTotals.clear();
      _productQuantitiesByUnit.clear();
    }
    
    for (final invoice in invoices) {
      try {
        final amount = (invoice['total_amount'] as num?)?.toDouble() ?? 0;
        final currency = invoice['currency'] as String? ?? '';
        final customerName = (invoice['account_name'] as String?)?.trim() ?? 'Unknown';
        final status = (invoice['status'] as String?)?.trim() ?? '';
        
        // Safely get items, handling different possible formats
        List<Map<String, dynamic>> items = [];
        if (invoice['items'] is List) {
          items = (invoice['items'] as List).whereType<Map<String, dynamic>>().toList();
        }
        
        // Skip if no valid data
        if (customerName.isEmpty && amount == 0 && items.isEmpty) continue;
        
        // Currency totals
        _currencyTotals[currency] = (_currencyTotals[currency] ?? 0) + amount;
        
        // Customer analysis
        _customerCounts[customerName] = (_customerCounts[customerName] ?? 0) + 1;
        _customerTotals[customerName] ??= {};
        _customerTotals[customerName]![currency] = 
            (_customerTotals[customerName]![currency] ?? 0) + amount;
        
        // Status analysis
        if (status.isNotEmpty) {
          _statusCounts[status] = (_statusCounts[status] ?? 0) + 1;
        }
        
        // Product analysis
        if (items.isNotEmpty) {
          _analyzeProducts(items, currency);
        }
      } catch (e) {
        debugPrint('Error processing invoice: $e');
        continue;
      }
    }
  }
  
  void _analyzeProducts(List<Map<String, dynamic>> items, String currency) {
    if (items.isEmpty) return;
    
    for (final item in items) {
      try {
        final productName = (item['product_name'] as String?)?.trim() ?? 'Unknown Product';
        if (productName.isEmpty) continue;
        
        final quantity = (item['quantity'] is num) 
            ? (item['quantity'] as num).toDouble() 
            : double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
            
        final unitPrice = (item['unit_price'] is num)
            ? (item['unit_price'] as num).toDouble()
            : double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0;
            
        final unitName = (item['unit_name'] as String?)?.trim().isNotEmpty == true
            ? (item['unit_name'] as String).trim()
            : 'unit';
            
        final total = quantity * unitPrice;
        
        if (quantity <= 0 || unitPrice < 0) continue;
        
        // Update product counts and totals
        _productCounts[productName] = (_productCounts[productName] ?? 0) + 1;
        _productTotals[productName] ??= {};
        _productTotals[productName]![currency] = 
            (_productTotals[productName]![currency] ?? 0) + total;
        
        // Track quantities by unit
        _productQuantitiesByUnit[productName] ??= {};
        _productQuantitiesByUnit[productName]![unitName] = 
            (_productQuantitiesByUnit[productName]![unitName] ?? 0) + quantity;
      } catch (e) {
        debugPrint('Error processing product item: $e');
        continue;
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
      _fetchInvoices(reset: true);
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _searchQuery = null;
      _selectedCurrency = null;
      _selectedStatus = null;
      _customerPage = 0;
    });
    _fetchInvoices(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.salesReports),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: loc.summary),
            Tab(icon: Icon(Icons.list), text: loc.invoices),
            Tab(icon: Icon(Icons.people), text: loc.customers),
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
                          child: Text(_startDate != null ? dFormatter.formatLocalizedDate(context, _startDate.toString()) : '-'),
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
                          child: Text(_endDate != null ? dFormatter.formatLocalizedDate(context, _endDate.toString()) : '-'),
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
                          _fetchInvoices(reset: true);
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
                          _fetchInvoices(reset: true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: loc.status,
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedStatus,
                        items: [
                          DropdownMenuItem(value: null, child: Text(loc.all)),
                          ..._statuses.map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(_getStatusLabel(loc, status)),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
                          _fetchInvoices(reset: true);
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
                _buildInvoicesTab(loc, theme),
                _buildCustomersTab(loc, theme),
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
                  title: loc.totalInvoices(_invoices.length),
                  subtitle: '${_invoices.length} ${loc.invoices.toLowerCase()}',
                  icon: Icons.receipt,
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
                  title: _customerCounts.length.toString(),
                  subtitle: loc.customers,
                  icon: Icons.people,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: _statusCounts.length.toString(),
                  subtitle: loc.status,
                  icon: Icons.assessment,
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
          
          const SizedBox(height: 24),
          
          // Status Breakdown
          Text(
            loc.status,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ..._statusCounts.entries.map((entry) => Card(
            child: ListTile(
              leading: Icon(_getStatusIcon(entry.key), color: _getStatusColor(entry.key)),
              title: Text(_getStatusLabel(loc, entry.key)),
              trailing: Text(
                entry.value.toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(entry.key),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab(AppLocalizations loc, ThemeData theme) {
    if (_isLoading && _invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_invoices.isEmpty) {
      return Center(child: Text(loc.noDataAvailable));
    }

    return ListView.separated(
      controller: _invoiceScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _invoices.length + (_hasMoreInvoices ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        if (index == _invoices.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final invoice = _invoices[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: Icon(Icons.receipt, color: Colors.blue),
            ),
            title: Text(invoice['invoice_number'] ?? '-'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice['account_name'] ?? '-'),
                Text(dFormatter.formatLocalizedDateTime(context, invoice['date'])),
                if (invoice['notes'] != null && invoice['notes'].isNotEmpty)
                  Text(invoice['notes'], style: theme.textTheme.bodySmall),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_amountFormatter.format(invoice['total_amount'])} ${invoice['currency'] ?? ''}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(invoice['status']).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(loc, invoice['status']),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(invoice['status']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            // onTap: () => _showInvoiceDetails(invoice),
          ),
        );
      },
    );
  }

  List<MapEntry<String, Map<String, double>>> get _paginatedCustomers {
    final sortedCustomers = _customerTotals.entries.toList()
      ..sort((a, b) {
        final aTotal = a.value.values.fold(0.0, (sum, v) => sum + v);
        final bTotal = b.value.values.fold(0.0, (sum, v) => sum + v);
        return bTotal.compareTo(aTotal);
      });
    final start = _customerPage * _customerPageSize;
    final end = (_customerPage + 1) * _customerPageSize;
    return sortedCustomers.sublist(
      start,
      end > sortedCustomers.length ? sortedCustomers.length : end,
    );
  }
  
  // Sort products based on current sort option
  List<MapEntry<String, Map<String, double>>> _sortProducts() {
    final products = _productTotals.entries.toList();
    
    switch (_currentProductSort) {
      case 'name_asc':
        products.sort((a, b) => a.key.compareTo(b.key));
        break;
      case 'name_desc':
        products.sort((a, b) => b.key.compareTo(a.key));
        break;
      case 'quantity_asc':
        products.sort((a, b) {
          final aQty = _productQuantitiesByUnit[a.key]?.values.fold(0.0, (sum, v) => sum + v) ?? 0;
          final bQty = _productQuantitiesByUnit[b.key]?.values.fold(0.0, (sum, v) => sum + v) ?? 0;
          return aQty.compareTo(bQty);
        });
        break;
      case 'quantity_desc':
        products.sort((a, b) {
          final aQty = _productQuantitiesByUnit[a.key]?.values.fold(0.0, (sum, v) => sum + v) ?? 0;
          final bQty = _productQuantitiesByUnit[b.key]?.values.fold(0.0, (sum, v) => sum + v) ?? 0;
          return bQty.compareTo(aQty);
        });
        break;
      case 'total_desc':
      default:
        products.sort((a, b) {
          final aTotal = a.value.values.fold(0.0, (sum, v) => sum + v);
          final bTotal = b.value.values.fold(0.0, (sum, v) => sum + v);
          return bTotal.compareTo(aTotal);
        });
    }
    
    // Apply search filter
    final searchQuery = _productSearchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      return products.where((entry) => 
        entry.key.toLowerCase().contains(searchQuery)
      ).toList();
    }
    
    return products;
  }

  // Get paginated products
  List<MapEntry<String, Map<String, double>>> get _paginatedProducts {
    final start = _productPage * _productPageSize;
    final end = (_productPage + 1) * _productPageSize;
    return _sortedProducts.sublist(
      0,
      end > _sortedProducts.length ? _sortedProducts.length : end,
    );
  }

  // Handle product scroll for pagination
  void _onProductScroll() {
    if (_isLoadingMoreProducts || !_hasMoreProducts) return;
    
    final maxScroll = _productScrollController.position.maxScrollExtent;
    final currentScroll = _productScrollController.position.pixels;
    final delta = MediaQuery.of(context).size.height * 0.2;
    
    if (maxScroll - currentScroll <= delta) {
      _fetchMoreProducts();
    }
  }
  
  // Handle product search changes
  void _onProductSearchChanged() {
    setState(() {
      _productPage = 0;
      _sortedProducts = _sortProducts();
      _hasMoreProducts = _sortedProducts.length > _productPageSize;
    });
  }
  
  // Fetch more products for pagination
  void _fetchMoreProducts() {
    if (_isLoadingMoreProducts || !_hasMoreProducts) return;
    
    setState(() {
      _isLoadingMoreProducts = true;
      _productPage++;
      _hasMoreProducts = _sortedProducts.length > _productPage * _productPageSize;
      _isLoadingMoreProducts = false;
    });
  }
  
  // Build sort menu
  Widget _buildSortMenu(AppLocalizations loc) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      onSelected: (value) {
        setState(() {
          _currentProductSort = value;
          _productPage = 0;
          _sortedProducts = _sortProducts();
          _hasMoreProducts = _sortedProducts.length > _productPageSize;
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'total_desc',
          child: Text(loc.sortByTotalDesc),
        ),
        PopupMenuItem(
          value: 'name_asc',
          child: Text(loc.sortByNameAsc),
        ),
        PopupMenuItem(
          value: 'name_desc',
          child: Text(loc.sortByNameDesc),
        ),
        PopupMenuItem(
          value: 'quantity_desc',
          child: Text(loc.sortByQuantityDesc),
        ),
      ],
    );
  }
  
  // Build product list item widget
  Widget _buildProductItem(
    BuildContext context,
    String productName,
    Map<String, double> currencyMap,
    int count,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        leading: CircleAvatar(
          backgroundColor: Colors.purple.withValues(alpha: 0.1),
          child: const Icon(Icons.inventory, color: Colors.purple, size: 20),
        ),
        title: Text(
          productName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Show quantities by unit
            ..._productQuantitiesByUnit[productName]?.entries.map(
              (unitQty) => Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  '${_amountFormatter.format(unitQty.value)} ${unitQty.key}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
                ),
              ),
            ) ?? [const SizedBox.shrink()],
            // Show sales count
            Text(
              '${loc.sales}: $count',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...currencyMap.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Text(
                '${_amountFormatter.format(e.value)} ${e.key}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.right,
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  // Build products tab
  Widget _buildProductsTab(AppLocalizations loc, ThemeData theme) {
    // Sort products if not already sorted
    if (_sortedProducts.isEmpty && _productTotals.isNotEmpty) {
      _sortedProducts = _sortProducts();
    }
    
    return Column(
      children: [
        // Search and sort bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _productSearchController,
                  decoration: InputDecoration(
                    hintText: loc.searchProducts,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildSortMenu(loc),
            ],
          ),
        ),
        
        // Summary card removed as per user request
        
        // Products list
        Expanded(
          child: _productTotals.isEmpty
              ? Center(
                  child: _isLoading 
                      ? const CircularProgressIndicator()
                      : Text(loc.noDataAvailable),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchInvoices(reset: true);
                    setState(() {
                      _productPage = 0;
                      _sortedProducts = _sortProducts();
                      _hasMoreProducts = _sortedProducts.length > _productPageSize;
                    });
                  },
                  child: ListView.builder(
                    controller: _productScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: _paginatedProducts.length + (_hasMoreProducts ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _paginatedProducts.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      final entry = _paginatedProducts[index];
                      final productName = entry.key;
                      final currencyMap = entry.value;
                      final count = _productCounts[productName] ?? 0;
                      
                      return _buildProductItem(
                        context,
                        productName,
                        currencyMap,
                        count,
                        theme,
                        loc,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
  
  // Helper to build summary items
  Widget _buildSummaryItem(String value, String label, IconData icon, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  void _fetchMoreCustomers() {
    if (_isLoadingMoreCustomers || !_hasMoreCustomers) return;
    setState(() => _isLoadingMoreCustomers = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _customerPage++;
        final totalCustomers = _customerTotals.length;
        final start = _customerPage * _customerPageSize;
        // If the next page would be empty, there are no more customers
        if (start >= totalCustomers) {
          _hasMoreCustomers = false;
        } else {
          _hasMoreCustomers = true;
        }
        _isLoadingMoreCustomers = false;
      });
    });
  }

  Widget _buildCustomersTab(AppLocalizations loc, ThemeData theme) {
    if (_isLoading && _customerTotals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_customerTotals.isEmpty) {
      return Center(child: Text(loc.noDataAvailable));
    }

    final paginatedCustomers = _paginatedCustomers;

    return ListView.separated(
      controller: _customerScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: paginatedCustomers.length + ((_hasMoreCustomers && paginatedCustomers.isNotEmpty) ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        if (index == paginatedCustomers.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final entry = paginatedCustomers[index];
        final customerName = entry.key;
        final currencyMap = entry.value;
        final count = _customerCounts[customerName] ?? 0;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: Icon(Icons.people, color: Colors.orange),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName),
                      Text('${loc.invoices}: $count', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...currencyMap.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 12.0, bottom: 2.0),
                      child: Text(
                        '${_amountFormatter.format(e.value)} ${e.key}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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

  String _getStatusLabel(AppLocalizations loc, String status) {
    switch (status) {
      case 'draft':
        return loc.invoiceStatusDraft;
      case 'finalized':
        return loc.invoiceStatusFinalized;
      case 'partially_paid':
        return loc.invoiceStatusPartiallyPaid;
      case 'paid':
        return loc.invoiceStatusPaid;
      case 'cancelled':
        return loc.invoiceStatusCancelled;
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icons.edit;
      case 'finalized':
        return Icons.check_circle;
      case 'partially_paid':
        return Icons.payment;
      case 'paid':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'finalized':
        return Colors.blue;
      case 'partially_paid':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _onInvoiceScroll() {
    if (_invoiceScrollController.position.pixels >= _invoiceScrollController.position.maxScrollExtent - 200) {
      if (_hasMoreInvoices && !_isLoadingMoreInvoices) {
        _fetchInvoices();
      }
    }
  }

  void _onCustomerScroll() {
    if (_customerScrollController.position.pixels >= _customerScrollController.position.maxScrollExtent - 200) {
      if (_hasMoreCustomers && !_isLoadingMoreCustomers) {
        _fetchMoreCustomers();
      }
    }
  }

  // void _showInvoiceDetails(Map<String, dynamic> invoice) {
  //   // TODO: Implement invoice details dialog/sheet
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text('Invoice details: ${invoice['invoice_number']}')),
  //   );
  // }
} 