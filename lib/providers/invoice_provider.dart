import 'package:flutter/foundation.dart';
import '../database/invoice_db.dart';
import '../models/invoice.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../providers/inventory_provider.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class InvoiceProvider with ChangeNotifier {
  final InvoiceDBHelper _db = InvoiceDBHelper();
  final InventoryProvider _inventoryProvider;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Invoice> _invoices = [];
  List<Invoice> _overdueInvoices = [];
  bool _isLoading = false;
  String? _error;

  InvoiceProvider(this._inventoryProvider);

  List<Invoice> get invoices => _invoices;
  List<Invoice> get overdueInvoices => _overdueInvoices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize provider
  Future<void> initialize() async {
    await loadInvoices();
    await loadOverdueInvoices();
  }

  // Load all invoices
  Future<void> loadInvoices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final invoiceMaps = await _db.getInvoices(includeItems: true);
      _invoices = invoiceMaps.map((map) => _convertMapToInvoice(map)).toList();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load overdue invoices
  Future<void> loadOverdueInvoices() async {
    try {
      final overdueMaps = await _db.getOverdueInvoices();
      _overdueInvoices =
          overdueMaps.map((map) => _convertMapToInvoice(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading overdue invoices: $e');
    }
  }

  // Create new invoice
  Future<void> createInvoice(Invoice invoice) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
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
        items: invoice.items.map((item) => item.toMap()).toList(),
      );

      // 2. Update warehouse inventory for each item
      await _updateInventoryForInvoice(invoice.items);

      // 3. Fetch updated invoices
      await loadInvoices();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update invoice
  Future<void> updateInvoice(Invoice invoice) async {
    await _db.updateInvoice(
      id: invoice.id!,
      accountId: invoice.accountId,
      date: invoice.date,
      currency: invoice.currency,
      notes: invoice.notes,
      status: invoice.status.toString().split('.').last,
      paidAmount: invoice.paidAmount,
      dueDate: invoice.dueDate,
      items: invoice.items.map((item) => item.toMap()).toList(),
    );
    await loadInvoices();
  }

  // Delete invoice
  Future<void> deleteInvoice(int id) async {
    try {
      await _db.deleteInvoice(id);
      await loadInvoices();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Record payment
  Future<void> recordPayment(int invoiceId, double amount) async {
    await _db.recordPayment(invoiceId, amount);
    await loadInvoices();
    await loadOverdueInvoices();
  }

  // Finalize invoice and update inventory
  Future<void> finalizeInvoice(Invoice invoice) async {
    if (invoice.status != InvoiceStatus.draft) {
      throw Exception('Only draft invoices can be finalized');
    }

    // Update inventory for each item
    final updatedInvoice = invoice.copyWith(
      status: InvoiceStatus.finalized,
      updatedAt: DateTime.now(),
    );

    try {
      // First update the invoice status
      await updateInvoice(updatedInvoice);

      // Then update inventory with a stock movement for each item
      for (final item in invoice.items) {
        // Create a stock movement (negative quantity because products are going out)
        final movement = StockMovement(
          productId: item.productId,
          quantity: -item.quantity,
          type: MovementType.stockOut,
          reference: 'Invoice ${invoice.invoiceNumber}',
          notes: 'Finalized invoice',
        );

        await _inventoryProvider.recordStockMovement(movement);
      }

      // Refresh data to reflect changes
      await loadInvoices();
      await loadOverdueInvoices();
    } catch (e) {
      // If inventory update fails, revert the invoice status
      debugPrint('Error finalizing invoice: $e');
      await updateInvoice(invoice);
      throw Exception('Failed to update inventory: $e');
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

  // Get invoice by ID
  Future<Invoice?> getInvoice(int id) async {
    final invoice = await _db.getInvoiceById(id, includeItems: true);
    if (invoice == null) return null;
    return _convertMapToInvoice(invoice);
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

  // Helper method to convert database map to Invoice object
  Invoice _convertMapToInvoice(Map<String, dynamic> map) {
    final items = (map['items'] as List<dynamic>?)?.map((itemMap) {
          return InvoiceItem(
            id: itemMap['id'] as int?,
            invoiceId: itemMap['invoice_id'] as int?,
            productId: itemMap['product_id'] as int,
            quantity: itemMap['quantity'] as double,
            unitPrice: itemMap['unit_price'] as double,
            description: itemMap['description'] as String?,
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
    );
  }

  // New method to update warehouse inventory when items are sold
  Future<void> _updateInventoryForInvoice(List<InvoiceItem> items) async {
    final currentStock = _inventoryProvider.currentStock;

    for (final item in items) {
      final productId = item.productId;
      final quantityToDeduct = item.quantity;
      var remainingQuantity = quantityToDeduct;

      final productStock = currentStock
          .where((stock) => stock['product_id'] == productId)
          .toList();

      if (productStock.isEmpty) {
        throw Exception('No stock available for product ID: $productId');
      }

      for (final stock in productStock) {
        if (remainingQuantity <= 0) break;

        final stockId = stock['id'] as int?;
        final availableQuantity = (stock['quantity'] as num?)?.toDouble();
        final binId = stock['bin_id'] as int?;
        // Remove warehouseId and zoneId if you don't use them here

        if (stockId == null || availableQuantity == null || binId == null) {
          throw Exception('Invalid stock entry with null values');
        }

        final deduction = remainingQuantity > availableQuantity
            ? availableQuantity
            : remainingQuantity;

        await _db.updateStockQuantity(
          stockId,
          availableQuantity - deduction,

          0, // zoneId - unused
          binId,
          productId,
        );

        remainingQuantity -= deduction;
      }

      if (remainingQuantity > 0) {
        throw Exception(
            'Insufficient stock for product ID: $productId. Missing ${remainingQuantity.toStringAsFixed(2)} units');
      }
    }

    await _inventoryProvider.initialize();
  }
}
