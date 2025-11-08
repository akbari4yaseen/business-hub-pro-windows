import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../database/inventory_db.dart';
import '../../models/stock_movement.dart';
import '../../models/product.dart';
import '../../models/warehouse.dart';
import '../../utils/date_time_picker_helper.dart';
import '../../utils/date_formatters.dart' as dFormatter;

class StockMovementReportsScreen extends StatefulWidget {
  const StockMovementReportsScreen({Key? key}) : super(key: key);

  @override
  _StockMovementReportsScreenState createState() =>
      _StockMovementReportsScreenState();
}

class _StockMovementReportsScreenState
    extends State<StockMovementReportsScreen> {
  final InventoryDB _db = InventoryDB();
  DateTime? _startDate;
  DateTime? _endDate;
  Product? _selectedProduct;
  Warehouse? _selectedWarehouse;
  bool _isLoading = false;
  List<_ProductSummary> _summaries = [];
  List<Product> _products = [];
  List<Warehouse> _warehouses = [];
  int _rowsPerPage = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 6));
    _scrollController.addListener(_onScroll);
    _loadFiltersAndSummary();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading) {
      _fetchNextPage();
    }
  }

  Future<void> _loadFiltersAndSummary() async {
    setState(() => _isLoading = true);
    final products = await _db.getProducts();
    final warehouses = await _db.getWarehouses();
    setState(() {
      _products = products;
      _warehouses = warehouses;
      _summaries.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    await _fetchNextPage(reset: true);
  }

  Future<void> _fetchNextPage({bool reset = false}) async {
    if (!_hasMore && !reset) return;
    setState(() {
      if (reset) _isLoading = true;
      _isLoadingMore = !reset;
    });
    try {
      final all = await _db.getStockMovements();
      final filtered = all.where((m) {
        final matchesDate = (_startDate == null ||
                m.date
                    .isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
            (_endDate == null ||
                m.date.isBefore(_endDate!.add(const Duration(days: 1))));
        final matchesProduct =
            _selectedProduct == null || m.productId == _selectedProduct!.id;
        final matchesWarehouse = _selectedWarehouse == null ||
            m.sourceWarehouseId == _selectedWarehouse!.id ||
            m.destinationWarehouseId == _selectedWarehouse!.id;
        return matchesDate && matchesProduct && matchesWarehouse;
      }).toList();
      final Map<int, _ProductSummary> summaryMap = {};
      for (final m in filtered) {
        final key = m.productId;
        summaryMap.putIfAbsent(
          key,
          () => _ProductSummary(
            productId: m.productId,
            productName: m.productName ?? '',
            unitName: m.unitName ?? '',
          ),
        );
        if (m.type == MovementType.stockIn) {
          summaryMap[key]!.totalIn += m.quantity;
        } else if (m.type == MovementType.stockOut) {
          summaryMap[key]!.totalOut += m.quantity;
        }
      }
      var allSummaries = summaryMap.values.toList();
      _sortSummaries(allSummaries);
      final start = _currentPage * _rowsPerPage;

      final nextPage = allSummaries.skip(start).take(_rowsPerPage).toList();
      setState(() {
        if (reset) {
          _summaries = nextPage;
          _isLoading = false;
        } else {
          _summaries.addAll(nextPage);
        }
        _isLoadingMore = false;
        if (nextPage.length < _rowsPerPage) {
          _hasMore = false;
        } else {
          _currentPage++;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stock movement summary: $e')),
      );
    }
  }

  void _sortSummaries(List<_ProductSummary> summaries) {
    summaries.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.productName.compareTo(b.productName);
          break;
        case 1:
          cmp = a.totalIn.compareTo(b.totalIn);
          break;
        case 2:
          cmp = a.totalOut.compareTo(b.totalOut);
          break;
        case 3:
          cmp = (a.totalIn - a.totalOut).compareTo(b.totalIn - b.totalOut);
          break;
        case 4:
          cmp = a.unitName.compareTo(b.unitName);
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 0;
      _hasMore = true;
      _summaries.clear();
    });
    _fetchNextPage(reset: true);
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedProduct = null;
      _selectedWarehouse = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.stockMovementReports)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _datePickerField(loc, true),
                    const SizedBox(width: 12),
                    _datePickerField(loc, false),
                    const SizedBox(width: 12),
                    _productDropdown(loc),
                    const SizedBox(width: 12),
                    _warehouseDropdown(loc),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.sort),
                      label: Text(loc.filter),
                      onPressed: _applyFilters,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.clear),
                      label: Text(loc.clear),
                      onPressed: _clearFilters,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth =
                      constraints.maxWidth > 800 ? constraints.maxWidth : 800.0;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildSummaryList(loc),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePickerField(AppLocalizations loc, bool isStart) {
    final date = isStart ? _startDate : _endDate;
    return SizedBox(
      width: 180,
      child: TextButton.icon(
        icon: const Icon(Icons.calendar_today),
        label: Text(date == null
            ? (isStart ? loc.startDate : loc.endDate)
            : dFormatter.formatLocalizedDate(context, date.toString())),
        onPressed: () async {
          final picked = await pickLocalizedDate(
              context: context, initialDate: date ?? DateTime.now());
          if (picked != null)
            setState(() => isStart ? _startDate = picked : _endDate = picked);
        },
      ),
    );
  }

  Widget _productDropdown(AppLocalizations loc) {
    return SizedBox(
      width: 220,
      child: DropdownButton<Product?>(
        isExpanded: true,
        value: _selectedProduct,
        hint: Text(loc.product),
        items: [
          DropdownMenuItem<Product?>(value: null, child: Text(loc.all)),
          ..._products.map((p) => DropdownMenuItem<Product?>(
                value: p,
                child: Text(p.name),
              )),
        ],
        onChanged: (p) => setState(() => _selectedProduct = p),
      ),
    );
  }

  Widget _warehouseDropdown(AppLocalizations loc) {
    return SizedBox(
      width: 220,
      child: DropdownButton<Warehouse?>(
        isExpanded: true,
        value: _selectedWarehouse,
        hint: Text(loc.warehouse),
        items: [
          DropdownMenuItem<Warehouse?>(
              value: null, child: Text(loc.allWarehouses)),
          ..._warehouses.map((w) => DropdownMenuItem<Warehouse?>(
                value: w,
                child: Text(w.name),
              )),
        ],
        onChanged: (w) => setState(() => _selectedWarehouse = w),
      ),
    );
  }

  Widget _buildSummaryList(AppLocalizations loc) {
    if (_summaries.isEmpty && !_isLoading) {
      return Center(child: Text(loc.noMovementsFound));
    }
    final netTotals =
        _summaries.fold<double>(0, (sum, s) => sum + (s.totalIn - s.totalOut));
    final totalIn = _summaries.fold<double>(0, (sum, s) => sum + s.totalIn);
    final totalOut = _summaries.fold<double>(0, (sum, s) => sum + s.totalOut);
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              _headerCell(loc.product, flex: 3),
              _headerCell(loc.totalIn,
                  flex: 2, icon: Icons.arrow_downward, color: Colors.green),
              _headerCell(loc.totalOut,
                  flex: 2, icon: Icons.arrow_upward, color: Colors.red),
              _headerCell(loc.netMovement,
                  flex: 2, icon: Icons.equalizer, color: Colors.blue),
              _headerCell(loc.unit, flex: 1, icon: Icons.straighten),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _summaries.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _summaries.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final s = _summaries[index];
              final net = s.totalIn - s.totalOut;
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    _dataCell(s.productName, flex: 3),
                    _dataCell(NumberFormat('#,##0.##').format(s.totalIn),
                        flex: 2, color: Colors.green),
                    _dataCell(NumberFormat('#,##0.##').format(s.totalOut),
                        flex: 2, color: Colors.red),
                    _dataCell(NumberFormat('#,##0.##').format(net),
                        flex: 2,
                        color: net < 0 ? Colors.red : Colors.green,
                        isBold: true),
                    _dataCell(s.unitName, flex: 1),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              _dataCell(loc.total, flex: 3, isBold: true),
              _dataCell(NumberFormat('#,##0.##').format(totalIn),
                  flex: 2, color: Colors.green, isBold: true),
              _dataCell(NumberFormat('#,##0.##').format(totalOut),
                  flex: 2, color: Colors.red, isBold: true),
              _dataCell(NumberFormat('#,##0.##').format(netTotals),
                  flex: 2,
                  color: netTotals < 0 ? Colors.red : Colors.green,
                  isBold: true),
              _dataCell('', flex: 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String label,
      {int flex = 1, IconData? icon, Color? color}) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 16, color: color),
          if (icon != null) const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _dataCell(String value,
      {int flex = 1, Color? color, bool isBold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ProductSummary {
  final int productId;
  final String productName;
  final String unitName;
  double totalIn = 0;
  double totalOut = 0;
  _ProductSummary({
    required this.productId,
    required this.productName,
    required this.unitName,
  });
}
