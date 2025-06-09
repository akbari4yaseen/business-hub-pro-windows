import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/product.dart';
import '../models/warehouse.dart';
import '../models/stock_movement.dart';
import '../models/category.dart';
import '../models/unit.dart';
import '../models/product_unit.dart';

class InventoryDB {
  static final InventoryDB _instance = InventoryDB._internal();
  factory InventoryDB() => _instance;
  InventoryDB._internal();

  Future<Database> get _db async => await DatabaseHelper().database;

  // Product operations
  Future<int> insertProduct(Product product) async {
    final db = await _db;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await _db;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await _db;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getProducts() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Product Unit operations
  Future<int> insertProductUnit(ProductUnit productUnit) async {
    final db = await _db;
    return await db.insert('product_units', productUnit.toMap());
  }

  Future<int> updateProductUnit(ProductUnit productUnit) async {
    final db = await _db;
    return await db.update(
      'product_units',
      productUnit.toMap(),
      where: 'id = ?',
      whereArgs: [productUnit.id],
    );
  }

  Future<int> deleteProductUnit(int id) async {
    final db = await _db;
    return await db.delete(
      'product_units',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ProductUnit>> getProductUnits(int productId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'product_units',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return List.generate(maps.length, (i) => ProductUnit.fromMap(maps[i]));
  }

  // Current Stock operations
  Future<List<Map<String, dynamic>>> getCurrentStock() async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT 
        cs.*,
        p.name as product_name,
        p.description as product_description,
        p.category_id,
        p.unit_id,
        p.minimum_stock,
        p.has_expiry_date,
        p.barcode,
        w.name as warehouse_name
      FROM current_stock cs
      JOIN products p ON cs.product_id = p.id
      JOIN warehouses w ON cs.warehouse_id = w.id
      ORDER BY p.name, w.name
    ''');
  }

  Future<void> updateCurrentStock({
    required int productId,
    required int warehouseId,
    required double quantity,
    DateTime? expiryDate,
  }) async {
    final db = await _db;
    
    // Check if stock record exists
    final existing = await db.query(
      'current_stock',
      where: 'product_id = ? AND warehouse_id = ? AND expiry_date IS ?',
      whereArgs: [productId, warehouseId, expiryDate?.toIso8601String()],
    );

    if (existing.isEmpty) {
      // Insert new record
      await db.insert('current_stock', {
        'product_id': productId,
        'warehouse_id': warehouseId,
        'quantity': quantity,
        'expiry_date': expiryDate?.toIso8601String(),
      });
    } else {
      // Update existing record
      await db.update(
        'current_stock',
        {'quantity': quantity},
        where: 'product_id = ? AND warehouse_id = ? AND expiry_date IS ?',
        whereArgs: [productId, warehouseId, expiryDate?.toIso8601String()],
      );
    }
  }

  // Warehouse operations
  Future<int> insertWarehouse(Warehouse warehouse) async {
    final db = await _db;
    return await db.insert('warehouses', warehouse.toMap());
  }

  Future<int> updateWarehouse(Warehouse warehouse) async {
    final db = await _db;
    return await db.update(
      'warehouses',
      warehouse.toMap(),
      where: 'id = ?',
      whereArgs: [warehouse.id],
    );
  }

  Future<int> deleteWarehouse(int id) async {
    final db = await _db;
    return await db.delete(
      'warehouses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Warehouse>> getWarehouses() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('warehouses');
    return List.generate(maps.length, (i) => Warehouse.fromMap(maps[i]));
  }

  // Stock movement operations
  Future<void> recordStockMovement(StockMovement movement) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Insert movement record
      await txn.insert('stock_movements', movement.toMap());

      // Update current stock
      if (movement.sourceWarehouseId != null) {
        await updateCurrentStock(
          productId: movement.productId,
          warehouseId: movement.sourceWarehouseId!,
          quantity: -movement.quantity,
          expiryDate: movement.expiryDate,
        );
      }

      if (movement.destinationWarehouseId != null) {
        await updateCurrentStock(
          productId: movement.productId,
          warehouseId: movement.destinationWarehouseId!,
          quantity: movement.quantity,
          expiryDate: movement.expiryDate,
        );
      }
    });
  }

  Future<List<StockMovement>> getStockMovements({
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movements',
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) => StockMovement.fromMap(maps[i]));
  }

  // Category operations
  Future<int> insertCategory(Category category) async {
    final db = await _db;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await _db;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _db;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Category>> getCategories() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  // Unit operations
  Future<int> insertUnit(Unit unit) async {
    final db = await _db;
    return await db.insert('units', unit.toMap());
  }

  Future<int> updateUnit(Unit unit) async {
    final db = await _db;
    return await db.update(
      'units',
      unit.toMap(),
      where: 'id = ?',
      whereArgs: [unit.id],
    );
  }

  Future<int> deleteUnit(int id) async {
    final db = await _db;
    return await db.delete(
      'units',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Unit>> getUnits() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('units');
    return List.generate(maps.length, (i) => Unit.fromMap(maps[i]));
  }

  // Helper methods
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT 
        p.*,
        cs.quantity as current_stock,
        w.name as warehouse_name
      FROM products p
      JOIN current_stock cs ON p.id = cs.product_id
      JOIN warehouses w ON cs.warehouse_id = w.id
      WHERE cs.quantity <= p.minimum_stock
      ORDER BY cs.quantity ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getExpiringProducts(int days) async {
    final db = await _db;
    final expiryDate = DateTime.now().add(Duration(days: days));
    return await db.rawQuery('''
      SELECT 
        p.*,
        cs.quantity as current_stock,
        cs.expiry_date,
        w.name as warehouse_name
      FROM products p
      JOIN current_stock cs ON p.id = cs.product_id
      JOIN warehouses w ON cs.warehouse_id = w.id
      WHERE p.has_expiry_date = 1
        AND cs.expiry_date IS NOT NULL
        AND cs.expiry_date <= ?
      ORDER BY cs.expiry_date ASC
    ''', [expiryDate.toIso8601String()]);
  }
}
