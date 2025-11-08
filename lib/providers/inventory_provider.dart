import 'package:flutter/foundation.dart';
import '../database/inventory_db.dart';
import '../models/product.dart';
import '../models/warehouse.dart';
import '../models/stock_movement.dart';
import '../models/category.dart' as inventory_models;
import '../models/unit.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryDB _db = InventoryDB();

  List<Map<String, dynamic>> _currentStock = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  List<Map<String, dynamic>> _expiringProducts = [];
  List<inventory_models.Category> _categories = [];
  List<Unit> _units = [];
  List<UnitConversion> _unitConversions = [];
  List<Warehouse> _warehouses = [];
  List<StockMovement> _stockMovements = [];
  List<Product> _allProducts = [];
  bool _isLoading = false;
  String? _error;
  bool _isLoadingMovements = false;
  bool _hasMoreMovements = true;
  int _currentMovementsPage = 0;
  static const int _movementsPageSize = 30;

  List<Map<String, dynamic>> get currentStock => _currentStock;
  List<Map<String, dynamic>> get lowStockProducts => _lowStockProducts;
  List<Map<String, dynamic>> get expiringProducts => _expiringProducts;
  List<inventory_models.Category> get categories => _categories;
  List<Unit> get units => _units;
  List<UnitConversion> get unitConversions => _unitConversions;
  List<Warehouse> get warehouses => _warehouses;
  List<StockMovement> get stockMovements => _stockMovements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoadingMovements => _isLoadingMovements;
  bool get hasMoreMovements => _hasMoreMovements;

  // Added method to get category name
  String getCategoryName(int? categoryId) {
    if (categoryId == null) return 'Unknown Category';
    try {
      final category = _categories.firstWhere((c) => c.id == categoryId);
      return category.name;
    } catch (e) {
      return 'Unknown Category';
    }
  }

  // Added method to get unit name
  String getUnitName(int? unitId) {
    if (unitId == null) return 'Unknown Unit';
    try {
      final unit = _units.firstWhere((u) => u.id == unitId);
      return unit.name;
    } catch (e) {
      return 'Unknown Unit';
    }
  }

  // Update the products getter to return all products from database
  List<Product> get products => _allProducts;

  // Original method renamed to productsWithStock for backwards compatibility
  List<Product> get productsWithStock {
    final productMap = <int, Product>{};

    // Extract unique products from current stock
    for (final item in _currentStock) {
      final productId = item['product_id'] as int;
      if (!productMap.containsKey(productId)) {
        try {
          productMap[productId] = Product(
            id: productId,
            name: item['product_name'] as String,
            categoryId: item['category_id'] as int? ?? 0,
            baseUnitId: item['unit_id'] as int? ??
                0, // This is correct - the query returns unit_id from the join
            description: item['product_description'] as String? ?? '',
            minimumStock: item['minimum_stock'] as double? ?? 0,
            hasExpiryDate: item['has_expiry_date'] == 1,
            barcode: item['barcode'] as String?,
            isActive: item['is_active'] as bool? ?? true,
            createdAt: item['created_at'] as DateTime? ?? DateTime.now(),
            updatedAt: item['updated_at'] as DateTime? ?? DateTime.now(),
          );
        } catch (e) {
          debugPrint('Error creating product from stock: $e');
        }
      }
    }

    return productMap.values.toList();
  }

  /// Get current stock for a specific product
  /// Returns a list of stock entries with warehouse information and quantities
  List<Map<String, dynamic>> getCurrentStockForProduct(int productId) {
    if (_currentStock.isEmpty) return [];

    return _currentStock
        .where((item) => (item['product_id'] as int?) == productId)
        .map<Map<String, dynamic>>((item) => {
              'product_id': item['product_id'] as int,
              'warehouse_id': item['warehouse_id'] as int,
              'warehouse_name':
                  (item['warehouse_name'] as String?) ?? 'Unknown',
              'quantity': (item['current_quantity'] as num?)?.toDouble() ?? 0.0,
              'unit': (item['unit_symbol'] as String?) ?? 'pcs',
              'total_in': (item['total_in'] as num?)?.toDouble() ?? 0.0,
              'total_out': (item['total_out'] as num?)?.toDouble() ?? 0.0,
            })
        .toList();
  }

  // Product operations
  Future<void> addProduct(Product product) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.insertProduct(product);
      await refreshData();
    } catch (e) {
      debugPrint('Error adding product: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.updateProduct(product);
      await refreshData();
    } catch (e) {
      debugPrint('Error updating product: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _db.deleteProduct(id);
      await refreshData();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  // Warehouse operations
  Future<int> addWarehouse(Warehouse warehouse) async {
    try {
      final id = await _db.insertWarehouse(warehouse);
      await refreshData();
      return id;
    } catch (e) {
      debugPrint('Error adding warehouse: $e');
      rethrow;
    }
  }

  Future<void> updateWarehouse(Warehouse warehouse) async {
    try {
      await _db.updateWarehouse(warehouse);
      await refreshData();
    } catch (e) {
      debugPrint('Error updating warehouse: $e');
      rethrow;
    }
  }

  Future<void> deleteWarehouse(int id) async {
    try {
      await _db.deleteWarehouse(id);
      await refreshData();
    } catch (e) {
      debugPrint('Error deleting warehouse: $e');
      rethrow;
    }
  }

  // Stock movement operations
  Future<void> recordStockMovement(StockMovement movement) async {
    try {
      await _db.recordStockMovement(movement);
      await _refreshCurrentStock();
      await _refreshStockMovements();
      notifyListeners();
    } catch (e) {
      debugPrint('Error recording stock movement: $e');
      rethrow;
    }
  }

  Future<void> deleteStockMovement(int id) async {
    try {
      await _db.deleteStockMovement(id);
      await _refreshStockMovements();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting stock movement: $e');
      rethrow;
    }
  }

  // Update stock level
  Future<void> updateStock({
    required int productId,
    required double quantity,
    required String reference,
  }) async {
    try {
      final movement = StockMovement(
        id: 0,
        productId: productId,
        quantity: quantity,
        type: quantity > 0 ? MovementType.stockIn : MovementType.stockOut,
        reference: reference,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await recordStockMovement(movement);
    } catch (e) {
      debugPrint('Error updating stock: $e');
      rethrow;
    }
  }

  // Category operations
  Future<void> addCategory(inventory_models.Category category) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.insertCategory(category);
      await _refreshCategories();
    } catch (e) {
      debugPrint('Error adding category: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCategory(inventory_models.Category category) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.updateCategory(category);
      await _refreshCategories();
    } catch (e) {
      debugPrint('Error updating category: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.deleteCategory(categoryId);
      await _refreshCategories();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Unit operations
  Future<void> addUnit(Unit unit) async {
    try {
      final id = await _db.insertUnit(unit);
      _units.add(Unit(
        id: id,
        name: unit.name,
        symbol: unit.symbol,
        description: unit.description,
        createdAt: unit.createdAt,
        updatedAt: unit.updatedAt,
      ));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding unit: $e');
      rethrow;
    }
  }

  Future<void> updateUnit(Unit unit) async {
    try {
      await _db.updateUnit(unit);
      final index = _units.indexWhere((u) => u.id == unit.id);
      if (index != -1) {
        _units[index] = unit;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating unit: $e');
      rethrow;
    }
  }

  Future<void> deleteUnit(int id) async {
    try {
      await _db.deleteUnit(id);
      _units.removeWhere((u) => u.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting unit: $e');
      rethrow;
    }
  }

  // Unit Conversion operations
  Future<void> addUnitConversion(UnitConversion conversion) async {
    await _db.insertUnitConversion(conversion);
    await refreshUnitConversions();
    notifyListeners();
  }

  Future<void> updateUnitConversion(UnitConversion conversion) async {
    await _db.updateUnitConversion(conversion);
    await refreshUnitConversions();
    notifyListeners();
  }

  Future<void> deleteUnitConversion(int id) async {
    await _db.deleteUnitConversion(id);
    await refreshUnitConversions();
    notifyListeners();
  }

  Future<void> refreshUnitConversions() async {
    _unitConversions = await _db.getUnitConversions();
    notifyListeners();
  }

  /// Returns the conversion factor from fromUnitId to toUnitId, using multi-step path if needed.
  /// Returns null if no path exists.
  double? getMultiStepConversionFactor(int fromUnitId, int toUnitId) {
    if (fromUnitId == toUnitId) return 1.0;
    // Build adjacency list
    final Map<int, List<Map<String, dynamic>>> graph = {};
    for (final conv in _unitConversions) {
      graph
          .putIfAbsent(conv.fromUnitId, () => [])
          .add({'to': conv.toUnitId, 'factor': conv.factor});
      // Add reverse edge
      graph
          .putIfAbsent(conv.toUnitId, () => [])
          .add({'to': conv.fromUnitId, 'factor': 1 / conv.factor});
    }
    // BFS
    final queue = <MapEntry<int, double>>[MapEntry(fromUnitId, 1.0)];
    final visited = <int>{fromUnitId};
    while (queue.isNotEmpty) {
      final entry = queue.removeAt(0);
      final current = entry.key;
      final factorSoFar = entry.value;
      if (current == toUnitId) return factorSoFar;
      for (final edge in graph[current] ?? []) {
        final next = edge['to'] as int;
        final nextFactor = edge['factor'] as double;
        if (!visited.contains(next)) {
          visited.add(next);
          queue.add(MapEntry(next, factorSoFar * nextFactor));
        }
      }
    }
    return null;
  }

  // Convert quantity between units (multi-step)
  double convertQuantity({
    required int productId,
    required double quantity,
    required int fromUnitId,
    required int toUnitId,
  }) {
    if (fromUnitId == toUnitId) return quantity;
    final factor = getMultiStepConversionFactor(fromUnitId, toUnitId);
    if (factor != null) return quantity * factor;
    return quantity;
  }

  // Individual refresh methods to reduce memory pressure
  Future<void> _refreshCurrentStock() async {
    try {
      _currentStock = await _db.getCurrentStock();
    } catch (e) {
      debugPrint('Error refreshing current stock: $e');
    }
  }

  Future<void> _refreshLowStockProducts() async {
    try {
      _lowStockProducts = await _db.getLowStockProducts();
    } catch (e) {
      debugPrint('Error refreshing low stock products: $e');
    }
  }

  Future<void> _refreshExpiringProducts() async {
    try {
      _expiringProducts = await _db.getExpiringProducts(30);
    } catch (e) {
      debugPrint('Error refreshing expiring products: $e');
    }
  }

  Future<void> _refreshCategories() async {
    try {
      _categories = await _db.getCategories();
    } catch (e) {
      debugPrint('Error refreshing categories: $e');
    }
  }

  Future<void> _refreshUnits() async {
    try {
      _units = await _db.getUnits();
    } catch (e) {
      debugPrint('Error refreshing units: $e');
    }
  }

  Future<void> _refreshWarehouses() async {
    try {
      _warehouses = await _db.getWarehouses();
    } catch (e) {
      debugPrint('Error refreshing warehouses: $e');
    }
  }

  Future<void> _refreshProducts() async {
    try {
      _allProducts = await _db.getProducts();
    } catch (e) {
      debugPrint('Error refreshing products: $e');
    }
  }

  Future<void> _refreshStockMovements() async {
    try {
      _stockMovements = await _db.getStockMovements();
    } catch (e) {
      debugPrint('Error refreshing stock movements: $e');
    }
  }

  // Full data refresh with memory optimization
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _refreshCurrentStock(),
        _refreshLowStockProducts(),
        _refreshExpiringProducts(),
        _refreshCategories(),
        _refreshUnits(),
        _refreshWarehouses(),
        _refreshProducts(),
        _refreshStockMovements(),
      ]);
    } catch (e) {
      debugPrint('Error refreshing inventory data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialize data
  Future<void> initialize() async {
    await refreshData();
    await refreshUnitConversions();
  }

  // Public method to refresh warehouses
  Future<void> refreshWarehouses() async {
    await _refreshWarehouses();
    notifyListeners();
  }

  // Public refresh methods
  Future<void> refreshProducts() async {
    await _refreshProducts();
    notifyListeners();
  }

  // Load stock movements with pagination
  Future<void> loadStockMovements({bool refresh = false}) async {
    if (refresh) {
      _currentMovementsPage = 0;
      _stockMovements.clear();
      _hasMoreMovements = true;
    }

    if (!_hasMoreMovements || _isLoadingMovements) return;

    _isLoadingMovements = true;
    notifyListeners();

    try {
      final newMovements = await _db.getStockMovements(
        limit: _movementsPageSize,
        offset: _currentMovementsPage * _movementsPageSize,
      );

      if (refresh) {
        _stockMovements = newMovements;
      } else {
        _stockMovements.addAll(newMovements);
      }

      _currentMovementsPage++;
      _hasMoreMovements = newMovements.length == _movementsPageSize;

      notifyListeners();
    } finally {
      _isLoadingMovements = false;
      notifyListeners();
    }
  }

  // Get product units
  List<Unit> getProductUnits(int productId) {
    final product = _allProducts.firstWhere((p) => p.id == productId);
    if (product.baseUnitId == null) return [];
    final unit = _units.firstWhere((u) => u.id == product.baseUnitId);
    return [unit];
  }

  // Get base unit for a product
  Unit? getBaseUnit(int productId) {
    final product = _allProducts.firstWhere((p) => p.id == productId);
    if (product.baseUnitId == null) return null;
    return _units.firstWhere((u) => u.id == product.baseUnitId);
  }
}
