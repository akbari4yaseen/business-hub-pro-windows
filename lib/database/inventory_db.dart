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

  Future<void> updateCurrentStock({
    required int productId,
    required int warehouseId,
    required double quantity,
    DateTime? expiryDate,
  }) async {
    final db = await _db;

    String whereClause;
    List<Object?> whereArgs;

    if (expiryDate == null) {
      whereClause =
          'product_id = ? AND warehouse_id = ? AND expiry_date IS NULL';
      whereArgs = [productId, warehouseId];
    } else {
      whereClause = 'product_id = ? AND warehouse_id = ? AND expiry_date = ?';
      whereArgs = [productId, warehouseId, expiryDate.toIso8601String()];
    }

    // Check if stock record exists
    final existing = await db.query(
      'current_stock',
      where: whereClause,
      whereArgs: whereArgs,
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
        where: whereClause,
        whereArgs: whereArgs,
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
  Future<int> recordStockMovement(StockMovement movement) async {
    final db = await _db;
    return await db.transaction((txn) async {
      // Insert the movement record
      final movementId = await txn.insert(
        'stock_movements',
        {
          'product_id': movement.productId,
          'source_warehouse_id': movement.sourceWarehouseId,
          'destination_warehouse_id': movement.destinationWarehouseId,
          'quantity': movement.quantity,
          'type': movement.type.toString().split('.').last,
          'reference': movement.reference,
          'notes': movement.notes,
          'date': movement.date.toIso8601String(),
          'expiry_date': movement.expiryDate?.toIso8601String(),
          'created_at': movement.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      // Update source warehouse stock
      if (movement.sourceWarehouseId != null) {
        await txn.rawUpdate('''
          UPDATE current_stock
          SET quantity = quantity - ?
          WHERE product_id = ? AND warehouse_id = ?
        ''', [
          movement.quantity,
          movement.productId,
          movement.sourceWarehouseId,
        ]);
      }

      // Update destination warehouse stock
      if (movement.destinationWarehouseId != null) {
        // Check if stock record exists
        final existingStock = await txn.query(
          'current_stock',
          where: 'product_id = ? AND warehouse_id = ?',
          whereArgs: [movement.productId, movement.destinationWarehouseId],
        );

        if (existingStock.isEmpty) {
          // Create new stock record
          await txn.insert(
            'current_stock',
            {
              'product_id': movement.productId,
              'warehouse_id': movement.destinationWarehouseId,
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
            movement.destinationWarehouseId,
          ]);
        }
      }

      return movementId;
    });
  }

  Future<List<StockMovement>> getStockMovements({
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    final args = <dynamic>[];

    // Add pagination parameters
    if (limit != null) {
      args.add(limit);
      if (offset != null) {
        args.add(offset);
      }
    } else if (offset != null) {
      args.add(offset);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        sm.*,
        p.name as product_name,
        u.name as unit_name,
        sw.name as source_warehouse_name,
        dw.name as destination_warehouse_name
      FROM stock_movements sm
      JOIN products p ON sm.product_id = p.id
      LEFT JOIN units u ON p.base_unit_id = u.id
      LEFT JOIN warehouses sw ON sm.source_warehouse_id = sw.id
      LEFT JOIN warehouses dw ON sm.destination_warehouse_id = dw.id
      ORDER BY sm.created_at DESC
      ${limit != null ? 'LIMIT ?' : ''}
      ${offset != null ? 'OFFSET ?' : ''}
    ''', args);

    return maps.map((map) => StockMovement.fromMap(map)).toList();
  }

Future<int> deleteStockMovement(int id) async {
  final db = await _db;

  return await db.transaction((txn) async {
    // Get the movement to be deleted
    final movementList = await txn.query(
      'stock_movements',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (movementList.isEmpty) return 0;

    final movement = movementList.first;
    final productId = movement['product_id'] as int;
    final quantity = movement['quantity'] as double;
    final type = movement['type'] as String;
    final sourceWarehouseId = movement['source_warehouse_id'] as int?;
    final destinationWarehouseId = movement['destination_warehouse_id'] as int?;

    // Helper to safely add/subtract stock
    Future<void> updateStock({
      required int warehouseId,
      required double deltaQuantity,
    }) async {
      final stockExists = Sqflite.firstIntValue(await txn.rawQuery(
        'SELECT COUNT(*) FROM current_stock WHERE product_id = ? AND warehouse_id = ?',
        [productId, warehouseId],
      ))! > 0;

      if (stockExists) {
        await txn.rawUpdate(
          'UPDATE current_stock SET quantity = quantity + ? WHERE product_id = ? AND warehouse_id = ?',
          [deltaQuantity, productId, warehouseId],
        );
      } else {
        if (deltaQuantity > 0) {
          await txn.insert('current_stock', {
            'product_id': productId,
            'warehouse_id': warehouseId,
            'quantity': deltaQuantity,
          });
        }
      }
    }

    // Reverse the movement's effect on stock
    switch (type) {
      case 'stockIn':
      case 'purchase':
        if (destinationWarehouseId != null) {
          await updateStock(
            warehouseId: destinationWarehouseId,
            deltaQuantity: -quantity,
          );
        }
        break;

      case 'stockOut':
      case 'sale':
        if (sourceWarehouseId != null) {
          await updateStock(
            warehouseId: sourceWarehouseId,
            deltaQuantity: quantity,
          );
        }
        break;

      case 'transfer':
        if (sourceWarehouseId != null) {
          await updateStock(
            warehouseId: sourceWarehouseId,
            deltaQuantity: quantity,
          );
        }
        if (destinationWarehouseId != null) {
          await updateStock(
            warehouseId: destinationWarehouseId,
            deltaQuantity: -quantity,
          );
        }
        break;

      case 'adjustment':
        // Assume positive quantity = added; reverse by subtracting
        if (destinationWarehouseId != null) {
          await updateStock(
            warehouseId: destinationWarehouseId,
            deltaQuantity: -quantity,
          );
        } else if (sourceWarehouseId != null) {
          await updateStock(
            warehouseId: sourceWarehouseId,
            deltaQuantity: -quantity,
          );
        }
        break;

      default:
        // Unknown movement type
        throw Exception('Unknown movement type: $type');
    }

    // Delete the stock movement record
    return await txn.delete(
      'stock_movements',
      where: 'id = ?',
      whereArgs: [id],
    );
  });
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
        u.id as unit_id,
        u.name as unit_name,
        u.symbol as unit_symbol,
        w.name as warehouse_name
      FROM current_stock cs
      JOIN products p ON cs.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      JOIN units u ON p.base_unit_id = u.id
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

  // Unit Conversion operations
  Future<int> insertUnitConversion(UnitConversion conversion) async {
    final db = await _db;
    return await db.insert('unit_conversions', conversion.toMap());
  }

  Future<int> updateUnitConversion(UnitConversion conversion) async {
    final db = await _db;
    return await db.update(
      'unit_conversions',
      conversion.toMap(),
      where: 'id = ?',
      whereArgs: [conversion.id],
    );
  }

  Future<int> deleteUnitConversion(int id) async {
    final db = await _db;
    return await db.delete(
      'unit_conversions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<UnitConversion>> getUnitConversions() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('unit_conversions');
    return List.generate(maps.length, (i) => UnitConversion.fromMap(maps[i]));
  }

  Future<UnitConversion?> getUnitConversionBetweenUnits(
      int fromUnitId, int toUnitId) async {
    final db = await _db;
    final maps = await db.query(
      'unit_conversions',
      where: 'from_unit_id = ? AND to_unit_id = ?',
      whereArgs: [fromUnitId, toUnitId],
    );
    if (maps.isNotEmpty) {
      return UnitConversion.fromMap(maps.first);
    }
    return null;
  }
}
