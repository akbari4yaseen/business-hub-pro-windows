import 'package:flutter/foundation.dart';
import '../database/purchase_db.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';

class PurchaseProvider with ChangeNotifier {
  final PurchaseDBHelper _db = PurchaseDBHelper();

  List<Purchase> _purchases = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 30;

  // Search and filter state
  String? _searchQuery;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  int? _selectedSupplierId;

  // Getters
  List<Purchase> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String? get searchQuery => _searchQuery;
  DateTime? get selectedStartDate => _selectedStartDate;
  DateTime? get selectedEndDate => _selectedEndDate;
  int? get selectedSupplierId => _selectedSupplierId;

  // Initialize provider
  Future<void> initialize() async {
    try {
      await loadPurchases();
    } catch (e) {
      debugPrint('Error initializing PurchaseProvider: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load purchases with pagination
  Future<void> loadPurchases({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _purchases.clear();
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newPurchases = await _db.getPurchases(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        searchQuery: _searchQuery,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        supplierId: _selectedSupplierId,
      );

      if (refresh) {
        _purchases = newPurchases.map((map) => Purchase.fromMap(map)).toList();
      } else {
        _purchases.addAll(newPurchases.map((map) => Purchase.fromMap(map)));
      }

      _currentPage++;
      _hasMore = newPurchases.length == _pageSize;
    } catch (e) {
      debugPrint('Error loading purchases: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new purchase
  Future<int> createPurchase(
      Purchase purchase, List<PurchaseItem> items) async {
    try {
      _isLoading = true;
      notifyListeners();

      final purchaseId = await _db.createPurchase(purchase);

      // Create purchase items
      for (var item in items) {
        await _db.createPurchaseItem(
          PurchaseItem(
            purchaseId: purchaseId,
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            unitId: item.unitId,
            unitName: item.unitName,
            unitPrice: item.unitPrice,
            expiryDate: item.expiryDate,
            notes: item.notes,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      await loadPurchases(refresh: true);
      return purchaseId;
    } catch (e) {
      debugPrint('Error creating purchase: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update purchase
  Future<void> updatePurchase(
      Purchase purchase, List<PurchaseItem> items) async {
    if (purchase.id == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _db.transaction((txn) async {
        // Update purchase
        await txn.update(
          'purchases',
          purchase.toMap(),
          where: 'id = ?',
          whereArgs: [purchase.id],
        );

        // Get existing items
        final existingItems = await _db.getPurchaseItems(purchase.id);

        // Delete removed items
        for (var item in existingItems) {
          if (!items.any((i) => i.id == item['id'])) {
            await txn.delete(
              'purchase_items',
              where: 'id = ?',
              whereArgs: [item['id']],
            );
          }
        }

        // Update or insert items
        for (var item in items) {
          if (item.id == 0) {
            // New item
            await txn.insert('purchase_items', {
              ...item.toMap(),
              'purchase_id': purchase.id,
            });
          } else {
            // Existing item
            await txn.update(
              'purchase_items',
              item.toMap(),
              where: 'id = ?',
              whereArgs: [item.id],
            );
          }
        }
      });

      await loadPurchases(refresh: true);
    } catch (e) {
      debugPrint('Error updating purchase: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete purchase
  Future<void> deletePurchase(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.deletePurchase(id);
      await loadPurchases(refresh: true);
    } catch (e) {
      debugPrint('Error deleting purchase: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get purchase by ID
  Future<Map<String, dynamic>?> getPurchaseById(int? id) async {
    if (id == null) return null;

    return await _db.getPurchaseById(id);
  }

  // Set search query
  void setSearchQuery(String? query) {
    _searchQuery = query;
    loadPurchases(refresh: true);
  }

  // Set date range
  void setDateRange(DateTime? start, DateTime? end) {
    _selectedStartDate = start;
    _selectedEndDate = end;
    loadPurchases(refresh: true);
  }

  // Set supplier filter
  void setSupplierFilter(int? supplierId) {
    _selectedSupplierId = supplierId;
    loadPurchases(refresh: true);
  }

  // Get purchase items
  Future<List<PurchaseItem>> getPurchaseItems(int? purchaseId) async {
    if (purchaseId == null) return [];

    final items = await _db.getPurchaseItems(purchaseId);
    return items.map((item) => PurchaseItem.fromMap(item)).toList();
  }

  // Refresh purchases
  Future<void> refreshPurchases() async {
    await loadPurchases(refresh: true);
  }

  // Add purchase
  Future<void> addPurchase(Purchase purchase, List<PurchaseItem> items) async {
    await createPurchase(purchase, items);
  }
}
