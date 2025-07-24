import 'package:flutter/foundation.dart';
import '../database/invoice_db.dart';
import '../models/invoice.dart';
import '../providers/inventory_provider.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class InvoiceProvider with ChangeNotifier {
  final InvoiceDBHelper _db = InvoiceDBHelper();
  final InventoryProvider _inventoryProvider;

  // State management
  List<Invoice> _invoices = [];
  List<Invoice> _overdueInvoices = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 30;

  // Cache for invoice details
  final Map<int, Invoice> _invoiceCache = {};

  // Search and filter state
  String? _searchQuery;
  String? _selectedStatus;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  int? _selectedAccountId;

  // Debounce timer for search
  Timer? _searchDebounce;

  InvoiceProvider(this._inventoryProvider);

  // Getters
  List<Invoice> get invoices => _invoices;
  List<Invoice> get overdueInvoices => _overdueInvoices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String? get searchQuery => _searchQuery;
  String? get selectedStatus => _selectedStatus;
  DateTime? get selectedStartDate => _selectedStartDate;
  DateTime? get selectedEndDate => _selectedEndDate;
  int? get selectedAccountId => _selectedAccountId;

  // Initialize provider
  Future<void> initialize() async {
    try {
      await Future.wait([
        loadInvoices(),
        loadOverdueInvoices(),
      ]);
    } catch (e) {
      debugPrint('Error initializing InvoiceProvider: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load all invoices with pagination
  Future<void> loadInvoices({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _invoices.clear();
      _hasMore = true;
      _invoiceCache.clear();
    }

    if (!_hasMore || _isLoading) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final invoiceMaps = await _db.getInvoices(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        includeItems: true,
        searchQuery: _searchQuery,
        status: _selectedStatus,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        accountId: _selectedAccountId,
      );

      final newInvoices = invoiceMaps.map((map) {
        final invoice = _convertMapToInvoice(map);
        _invoiceCache[invoice.id!] = invoice;
        return invoice;
      }).toList();

      if (refresh) {
        _invoices = newInvoices;
      } else {
        _invoices.addAll(newInvoices);
      }

      _currentPage++;
      _hasMore = newInvoices.length == _pageSize;
    } catch (e) {
      debugPrint('Error loading invoices: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load overdue invoices
  Future<void> loadOverdueInvoices() async {
    try {
      final overdueMaps = await _db.getOverdueInvoices();
      _overdueInvoices = overdueMaps.map((map) {
        final invoice = _convertMapToInvoice(map);
        _invoiceCache[invoice.id!] = invoice;
        return invoice;
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading overdue invoices: $e');
    }
  }

  // Create new invoice
  Future<void> createInvoice(Invoice invoice) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 1. Create the invoice in the database
      final invoiceId = await _db.createInvoice(
        accountId: invoice.accountId,
        invoiceNumber: invoice.invoiceNumber,
        date: invoice.date,
        currency: invoice.currency,
        notes: invoice.notes,
        status: invoice.status.toString().split('.').last,
        paidAmount: invoice.paidAmount,
        dueDate: invoice.dueDate,
        userEnteredTotal: invoice.userEnteredTotal,
        items: invoice.items.map((item) => item.toMap()).toList(),
        isPreSale: invoice.isPreSale,
      );

      // 2. Add to cache
      final createdInvoice = invoice.copyWith(id: invoiceId);
      _invoiceCache[invoiceId] = createdInvoice;

      // 3. Reset pagination and refresh data
      _currentPage = 0;
      _invoices.clear();
      _hasMore = true;

      // 4. Clear loading state before loading fresh data
      _isLoading = false;
      notifyListeners();

      // 5. Load fresh data
      await loadInvoices(refresh: true);
      await loadOverdueInvoices();
    } catch (e) {
      debugPrint('Error creating invoice: $e');
      _error = e.toString();
      rethrow;
    }
  }

  // Update invoice
  Future<void> updateInvoice(Invoice invoice) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.updateInvoice(
        id: invoice.id!,
        accountId: invoice.accountId,
        date: invoice.date,
        currency: invoice.currency,
        notes: invoice.notes,
        status: invoice.status.toString().split('.').last,
        paidAmount: invoice.paidAmount,
        dueDate: invoice.dueDate,
        userEnteredTotal: invoice.userEnteredTotal,
        items: invoice.items.map((item) => item.toMap()).toList(),
        isPreSale: invoice.isPreSale,
      );

      // Update cache
      _invoiceCache[invoice.id!] = invoice;

      // Reset pagination and refresh data
      await _refreshData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete invoice
  Future<void> deleteInvoice(int id) async {
    try {
      // Get the invoice first to check its status and items
      final invoice = await getInvoice(id);
      if (invoice == null) {
        throw Exception('Invoice not found');
      }

      // Only allow deletion of draft invoices
      if (invoice.status != InvoiceStatus.draft) {
        throw Exception('Only draft invoices can be deleted');
      }

      // Delete the invoice
      await _db.deleteInvoice(id);

      // Refresh data
      await loadInvoices();
      await loadOverdueInvoices();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Record payment
  Future<void> recordPayment(
      int invoiceId, double amount, String localizedDescription) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.recordPayment(invoiceId, amount,
          localizedDescription: localizedDescription);

      // Update cache if exists
      if (_invoiceCache.containsKey(invoiceId)) {
        final invoice = _invoiceCache[invoiceId]!;
        final updatedInvoice = invoice.copyWith(
          paidAmount: (invoice.paidAmount ?? 0) + amount,
          status: (invoice.paidAmount ?? 0) + amount >= invoice.total
              ? InvoiceStatus.paid
              : InvoiceStatus.partiallyPaid,
        );
        _invoiceCache[invoiceId] = updatedInvoice;
      }

      // Reset pagination and refresh data
      await _refreshData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Finalize invoice and update inventory
  Future<void> finalizeInvoice(
      Invoice invoice, String localizedDescription) async {
    if (invoice.status != InvoiceStatus.draft) {
      throw Exception('Only draft invoices can be finalized');
    }

    final updatedInvoice = invoice.copyWith(
      status: InvoiceStatus.finalized,
      updatedAt: DateTime.now(),
    );

    try {
      _isLoading = true;
      notifyListeners();

      // Update invoice status
      await updateInvoice(updatedInvoice);

      // Update warehouse inventory (skip for pre-sale invoices)
      if (!invoice.isPreSale) {
        await _updateInventoryForInvoice(invoice.items, invoice.invoiceNumber);
      }
      await _db.finalizeInvoice(invoice.id!,
          localizedDescription: localizedDescription);

      // Update cache
      _invoiceCache[invoice.id!] = updatedInvoice;

      // Reset pagination and refresh data
      await _refreshData();
    } catch (e) {
      debugPrint('Error finalizing invoice: $e');
      await updateInvoice(invoice);
      throw Exception('Failed to update inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get invoices for account
  Future<List<Invoice>> getInvoicesForAccount(int accountId) async {
    final invoiceMaps =
        await _db.getInvoices(accountId: accountId, includeItems: true);
    return invoiceMaps.map((map) => _convertMapToInvoice(map)).toList();
  }

  // Generate new invoice number
  Future<String> generateInvoiceNumber() async {
    try {
      // Use the built-in method from InvoiceDBHelper
      return await _db.generateInvoiceNumber();
    } catch (e) {
      // Fallback in case of errors
      return 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 4)}';
    }
  }

  // Get invoice by ID with cache
  Future<Invoice?> getInvoice(int id) async {
    if (_invoiceCache.containsKey(id)) {
      return _invoiceCache[id];
    }

    final invoice = await _db.getInvoiceById(id, includeItems: true);
    if (invoice == null) return null;

    final convertedInvoice = _convertMapToInvoice(invoice);
    _invoiceCache[id] = convertedInvoice;
    return convertedInvoice;
  }

  // Filter invoices
  Future<void> filterInvoices({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final invoiceMaps = await _db.getInvoices(
        status: status,
        startDate: startDate,
        endDate: endDate,
        includeItems: true,
      );
      _invoices = invoiceMaps.map((map) => _convertMapToInvoice(map)).toList();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search invoices with debounce
  Future<void> searchInvoices(String query) async {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      _searchQuery = query;
      _currentPage = 0;
      _invoices.clear();
      _hasMore = true;
      await loadInvoices(refresh: true);
    });
  }

  // Apply filters
  Future<void> applyFilters({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? accountId,
  }) async {
    _selectedStatus = status;
    _selectedStartDate = startDate;
    _selectedEndDate = endDate;
    _selectedAccountId = accountId;

    // Reset pagination
    _currentPage = 0;
    _invoices.clear();
    _hasMore = true;
    _invoiceCache.clear();

    // Load fresh data
    await loadInvoices(refresh: true);
    await loadOverdueInvoices();
  }

  // Reset filters
  Future<void> resetFilters() async {
    _selectedStatus = null;
    _selectedStartDate = null;
    _selectedEndDate = null;
    _selectedAccountId = null;
    _searchQuery = null;

    // Reset pagination
    _currentPage = 0;
    _invoices.clear();
    _hasMore = true;
    _invoiceCache.clear();

    // Load fresh data
    await loadInvoices(refresh: true);
    await loadOverdueInvoices();
  }

  // Helper method to refresh all data
  Future<void> _refreshData() async {
    try {
      _isLoading = true;
      notifyListeners();

      _currentPage = 0;
      _invoices.clear();
      _hasMore = true;
      _invoiceCache.clear();

      // Clear loading state before loading fresh data
      _isLoading = false;
      notifyListeners();

      await loadInvoices(refresh: true);
      await loadOverdueInvoices();
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      _error = e.toString();
    }
  }

  // Helper method to convert database map to Invoice object
  Invoice _convertMapToInvoice(Map<String, dynamic> map) {
    final items = (map['items'] as List<dynamic>?)?.map((itemMap) {
          return InvoiceItem(
            id: itemMap['id'] as int?,
            invoiceId: itemMap['invoice_id'] as int?,
            productId: itemMap['product_id'] as int,
            quantity: itemMap['quantity'] as double,
            unitPrice: itemMap['unit_price'] as double,
            unitId: itemMap['unit_id'] as int?,
            description: itemMap['description'] as String?,
            warehouseId: itemMap['warehouse_id'] as int?,
          );
        }).toList() ??
        [];

    return Invoice(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      invoiceNumber: map['invoice_number'] as String,
      date: DateTime.parse(map['date'] as String),
      currency: map['currency'] as String,
      notes: map['notes'] as String?,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      items: items,
      paidAmount: map['paid_amount'] as double?,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      userEnteredTotal: map['user_entered_total'] as double?,
      isPreSale: (map['is_pre_sale'] as int?) == 1,
    );
  }

  // New method to update warehouse inventory when items are sold
  Future<void> _updateInventoryForInvoice(
      List<InvoiceItem> items, String invoiceNumber) async {
    final currentStock = _inventoryProvider.currentStock;

    for (final item in items) {
      final productId = item.productId;
      // Convert quantity to base unit if different unit was used
      double quantityToDeduct = item.quantity;

      if (item.unitId != null) {
        final product =
            _inventoryProvider.products.firstWhere((p) => p.id == productId);
        if (product.baseUnitId != null && item.unitId != product.baseUnitId) {
          // Convert from selected unit to base unit
          quantityToDeduct = _inventoryProvider.convertQuantity(
            productId: productId,
            quantity: item.quantity,
            fromUnitId: item.unitId!,
            toUnitId: product.baseUnitId!,
          );
        }
      }

      var remainingQuantity = quantityToDeduct;

      final productStock = currentStock
          .where((stock) =>
              stock['product_id'] == productId &&
              stock['warehouse_id'] == item.warehouseId)
          .toList();

      if (productStock.isEmpty) {
        throw Exception('No stock available for product ID: $productId');
      }

      for (final stock in productStock) {
        if (remainingQuantity <= 0) break;

        final stockId = stock['id'] as int?;
        final availableQuantity = (stock['quantity'] as num?)?.toDouble();
        final warehouseId = stock['warehouse_id'] as int?;

        if (stockId == null ||
            availableQuantity == null ||
            warehouseId == null) {
          throw Exception('Invalid stock entry with null values');
        }

        final deduction = remainingQuantity > availableQuantity
            ? availableQuantity
            : remainingQuantity;

        await _db.updateStockQuantity(stockId, availableQuantity - deduction,
            warehouseId, productId, invoiceNumber);

        remainingQuantity -= deduction;
      }

      if (remainingQuantity > 0) {
        throw Exception(
            'Insufficient stock for product ID: $productId. Missing ${remainingQuantity.toStringAsFixed(2)} units');
      }
    }

    await _inventoryProvider.initialize();
  }

  // Cancel invoice
  Future<void> cancelInvoice(int invoiceId, String localizedDescription) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get the invoice first to check its status
      final invoice = await getInvoice(invoiceId);
      if (invoice == null) {
        throw Exception('Invoice not found');
      }

      // Only allow cancellation of finalized or partially paid invoices
      if (invoice.status != InvoiceStatus.finalized &&
          invoice.status != InvoiceStatus.partiallyPaid) {
        throw Exception(
            'Only finalized or partially paid invoices can be cancelled');
      }

      // Cancel the invoice
      await _db.cancelInvoice(invoiceId,
          localizedDescription: localizedDescription);

      // Update cache if exists
      if (_invoiceCache.containsKey(invoiceId)) {
        final updatedInvoice = invoice.copyWith(
          status: InvoiceStatus.cancelled,
          updatedAt: DateTime.now(),
        );
        _invoiceCache[invoiceId] = updatedInvoice;
      }

      // Reset pagination and refresh data
      await _refreshData();
    } catch (e) {
      debugPrint('Error cancelling invoice: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
