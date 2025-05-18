import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/product.dart';
import '../models/warehouse.dart';
import '../models/stock_movement.dart';
import '../models/category.dart';
import '../models/unit.dart';

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
    // Just delete the warehouse
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
  Future<int> recordStockMovement(StockMovement movement) async {
    final db = await _db;
    return await db.transaction((txn) async {
      // Insert the movement record
      final movementId = await txn.insert(
        'stock_movements',
        {
          'product_id': movement.productId,
          'source_warehouse_id': movement.sourceBinId,
          'destination_warehouse_id': movement.destinationBinId,
          'quantity': movement.quantity,
          'type': movement.type.toString().split('.').last,
          'reference': movement.reference,
          'notes': movement.notes,
          'expiry_date': movement.expiryDate?.toIso8601String(),
          'created_at': movement.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      // Update source warehouse stock
      if (movement.sourceBinId != null) {
        await txn.rawUpdate('''
          UPDATE current_stock
          SET quantity = quantity - ?
          WHERE product_id = ? AND warehouse_id = ?
        ''', [
          movement.quantity,
          movement.productId,
          movement.sourceBinId,
        ]);
      }

      // Update destination warehouse stock
      if (movement.destinationBinId != null) {
        // Check if stock record exists
        final existingStock = await txn.query(
          'current_stock',
          where: 'product_id = ? AND warehouse_id = ?',
          whereArgs: [movement.productId, movement.destinationBinId],
        );

        if (existingStock.isEmpty) {
          // Create new stock record
          await txn.insert(
            'current_stock',
            {
              'product_id': movement.productId,
              'warehouse_id': movement.destinationBinId,
              'quantity': movement.quantity,
              'expiry_date': movement.expiryDate?.toIso8601String(),
            },
          );
        } else {
          // Update existing stock record
          await txn.rawUpdate('''
            UPDATE current_stock
            SET quantity = quantity + ?
            WHERE product_id = ? AND warehouse_id = ?
          ''', [
            movement.quantity,
            movement.productId,
            movement.destinationBinId,
          ]);
        }
      }

      return movementId;
    });
  }

  Future<List<StockMovement>> getStockMovements() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movements',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => StockMovement.fromMap(maps[i]));
  }

  // Query operations
  Future<List<Map<String, dynamic>>> getCurrentStock() async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT 
        cs.*,
        p.name as product_name,
        p.description as product_description,
        p.minimum_stock,
        p.maximum_stock,
        p.has_expiry_date,
        p.barcode,
        p.sku,
        p.brand,
        c.name as category_name,
        u.name as unit_name,
        u.symbol as unit_symbol,
        w.name as warehouse_name
      FROM current_stock cs
      JOIN products p ON cs.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      JOIN units u ON p.unit_id = u.id
      LEFT JOIN warehouses w ON cs.warehouse_id = w.id
      WHERE p.is_active = 1
    ''');
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT 
        p.name as product_name,
        p.minimum_stock,
        COALESCE(SUM(cs.quantity), 0) as current_stock
      FROM products p
      LEFT JOIN current_stock cs ON p.id = cs.product_id
      GROUP BY p.id
      HAVING current_stock <= p.minimum_stock
      ORDER BY p.name
    ''');
  }

  Future<List<Map<String, dynamic>>> getExpiringProducts(
      int daysThreshold) async {
    final db = await _db;
    final thresholdDate = DateTime.now().add(Duration(days: daysThreshold));
    return await db.rawQuery('''
      SELECT 
        p.name as product_name,
        w.name as warehouse_name,
        cs.quantity,
        cs.expiry_date
      FROM current_stock cs
      JOIN products p ON cs.product_id = p.id
      LEFT JOIN warehouses w ON cs.warehouse_id = w.id
      WHERE cs.expiry_date IS NOT NULL 
        AND cs.expiry_date <= ?
      ORDER BY cs.expiry_date
    ''', [thresholdDate.toIso8601String()]);
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
}
