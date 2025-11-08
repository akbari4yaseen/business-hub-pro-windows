import 'package:flutter/foundation.dart' show debugPrint;
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
    return await db.transaction((txn) async {
      // First delete related stock movements
      await txn.delete(
        'stock_movements',
        where: 'product_id = ?',
        whereArgs: [id],
      );

      // Delete current stock records
      await txn.delete(
        'current_stock',
        where: 'product_id = ?',
        whereArgs: [id],
      );

      // Finally delete the product
      return await txn.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<Product>> getProducts() async {
    try {
      final db = await _db;

      // Query with explicit column selection for better error detection
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: 'is_active = ?',
        whereArgs: [1], // Only get active products
      );

      final products = <Product>[];
      for (final map in maps) {
        try {
          products.add(Product.fromMap(map));
        } catch (e) {
          debugPrint('Error parsing product: $e');
        }
      }

      return products;
    } catch (e) {
      debugPrint('Error in getProducts: $e');
      rethrow;
    }
  }

  Future<void> updateCurrentStock({
    required int productId,
    required int warehouseId,
    required double quantity,
    required String type, // 'stockIn' or 'stockOut' or 'transfer'
    required String sourceType, // 'invoice' or 'stock_movement'
    required int sourceId,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than 0');
    }

    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // Check if a record with the same source and type exists
      final existing = await txn.rawQuery('''
        SELECT id, quantity 
        FROM current_stock 
        WHERE source_type = ?
          AND source_id = ?
          AND product_id = ? 
          AND warehouse_id = ? 
          AND type = ?
      ''', [sourceType, sourceId, productId, warehouseId, type]);

      if (existing.isEmpty) {
        // Insert new record
        await txn.insert('current_stock', {
          'product_id': productId,
          'warehouse_id': warehouseId,
          'date': now,
          'type': type,
          'quantity': quantity,
          'source_type': sourceType,
          'source_id': sourceId,
        });
      } else {
        // Update existing record
        final currentId = existing.first['id'] as int;
        await txn.update(
          'current_stock',
          {
            'quantity':
                quantity, // Override instead of adding to prevent duplicates
            'date': now,
          },
          where: 'id = ?',
          whereArgs: [currentId],
        );
      }
    });
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

    // Check if warehouse has any stock
    final stockCount = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM current_stock 
      WHERE warehouse_id = ?
    ''', [id]);

    if ((stockCount.first['count'] as int) > 0) {
      throw Exception('Cannot delete warehouse with existing stock');
    }

    return await db.transaction((txn) async {
      // Delete related stock movements
      await txn.delete(
        'stock_movements',
        where: 'source_warehouse_id = ? OR destination_warehouse_id = ?',
        whereArgs: [id, id],
      );

      // Delete warehouse
      return await txn.delete(
        'warehouses',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<Warehouse>> getWarehouses() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('warehouses');
    return List.generate(maps.length, (i) => Warehouse.fromMap(maps[i]));
  }

  // Stock movement operations
  /// Updates stock by only creating a 'stockOut' entry in current_stock
  /// without creating a stock movement record
  Future<void> updateStockWithStockOut({
    required int productId,
    required int warehouseId,
    required double quantity,
    required int invoiceId,
    String? notes,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than 0');
    }

    final db = await _db;
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // Get current stock
      final stockMovements = await txn.query(
        'current_stock',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [productId, warehouseId],
      );

      // Calculate current stock
      double currentStock = 0.0;
      for (final movement in stockMovements) {
        if (movement['type'] == 'stockIn') {
          currentStock += (movement['quantity'] as num).toDouble();
        } else if (movement['type'] == 'stockOut') {
          currentStock -= (movement['quantity'] as num).toDouble();
        }
      }

      // Check if we have enough stock
      if (currentStock < quantity) {
        throw Exception(
            'Insufficient stock. Available: $currentStock, Requested: $quantity');
      }

      // Insert new stockOut record
      await txn.insert(
        'current_stock',
        {
          'product_id': productId,
          'warehouse_id': warehouseId,
          'quantity': quantity,
          'type': 'stockOut',
          'date': nowMs,
          'source_type': 'invoice',
          'source_id': invoiceId, // Use the invoice ID as source ID
          'reference': 'invoice',
          'notes': notes,
          'created_at': nowMs,
          'updated_at': nowMs,
        },
      );
    });
  }

  Future<int> recordStockMovement(StockMovement movement) async {
    final db = await _db;
    final now = DateTime.now();

    // Map MovementType to database type values
    final String dbType = switch (movement.type) {
      MovementType.stockIn => 'stockIn',
      MovementType.stockOut => 'stockOut',
      MovementType.transfer => 'transfer',
    };

    final dateMs = (movement.date).millisecondsSinceEpoch;
    final createdAtMs = movement.createdAt.millisecondsSinceEpoch;
    final nowMs = now.millisecondsSinceEpoch;
    final expiryDateMs = movement.expiryDate?.millisecondsSinceEpoch;

    return await db.transaction((txn) async {
      // Insert the movement record
      final movementId = await txn.insert(
        'stock_movements',
        {
          'product_id': movement.productId,
          'source_warehouse_id': movement.sourceWarehouseId,
          'destination_warehouse_id': movement.destinationWarehouseId,
          'quantity': movement.quantity,
          'type': dbType, // Use the mapped database type value
          'reference': movement.reference,
          'notes': movement.notes,
          'date': dateMs,
          'expiry_date': expiryDateMs,
          'created_at': createdAtMs,
          'updated_at': nowMs,
        },
      );

      // Update source warehouse stock (out movement)
      if (movement.sourceWarehouseId != null) {
        await _updateStockForMovement(
          txn,
          movement.productId,
          movement.sourceWarehouseId!,
          movement.quantity,
          'stockOut',
          now,
          sourceType: 'stock_movement',
          sourceId: movementId,
        );
      }

      // Update destination warehouse stock (in movement)
      if (movement.destinationWarehouseId != null) {
        await _updateStockForMovement(
          txn,
          movement.productId,
          movement.destinationWarehouseId!,
          movement.quantity,
          'stockIn',
          now,
          sourceType: 'stock_movement',
          sourceId: movementId,
        );
      }

      return movementId;
    });
  }

  // Helper method to update stock for a movement
  Future<void> _updateStockForMovement(
    Transaction txn,
    int productId,
    int warehouseId,
    double quantity,
    String type,
    DateTime timestamp, {
    required String sourceType,
    required int sourceId,
  }) async {
    final timestampMs = timestamp.millisecondsSinceEpoch;

    // Get all stock movements for this product and warehouse
    final stockMovements = await txn.query(
      'current_stock',
      where: 'product_id = ? AND warehouse_id = ?',
      whereArgs: [productId, warehouseId],
    );

    // Calculate current stock
    double currentStock = 0.0;
    for (final movement in stockMovements) {
      if (movement['type'] == 'stockIn') {
        currentStock += (movement['quantity'] as num).toDouble();
      } else if (movement['type'] == 'stockOut') {
        currentStock -= (movement['quantity'] as num).toDouble();
      }
    }

    // Check if we have enough stock for stockOut
    if (type == 'stockOut' && currentStock < quantity) {
      throw Exception(
          'Insufficient stock. Available: $currentStock, Requested: $quantity');
    }

    // Check if a record with the same source and type exists
    final existing = await txn.rawQuery('''
      SELECT id, quantity 
      FROM current_stock 
      WHERE source_type = ?
        AND source_id = ?
        AND product_id = ? 
        AND warehouse_id = ? 
        AND type = ?
    ''', [sourceType, sourceId, productId, warehouseId, type]);

    if (existing.isEmpty) {
      // Insert new record
      await txn.insert('current_stock', {
        'product_id': productId,
        'warehouse_id': warehouseId,
        'date': timestampMs,
        'type': type,
        'quantity': quantity,
        'source_type': sourceType,
        'source_id': sourceId,
      });
    } else {
      // Update existing record
      final currentId = existing.first['id'] as int;
      await txn.update(
        'current_stock',
        {
          'quantity': quantity,
          'date': timestampMs,
        },
        where: 'id = ?',
        whereArgs: [currentId],
      );
    }
  }

  Future<List<StockMovement>> getStockMovements({
    int? limit,
    int? offset,
    int? productId,
    int? warehouseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;
    final args = <dynamic>[];
    final whereClauses = <String>[];

    // Build where clause
    if (productId != null) {
      whereClauses.add('sm.product_id = ?');
      args.add(productId);
    }

    if (warehouseId != null) {
      whereClauses.add(
          '(sm.source_warehouse_id = ? OR sm.destination_warehouse_id = ?)');
      args.addAll([warehouseId, warehouseId]);
    }

    final where =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final limitClause = limit != null ? 'LIMIT ?' : '';
    final offsetClause =
        offset != null ? (limit != null ? 'OFFSET ?' : 'OFFSET ?') : '';

    // Add pagination parameters
    if (limit != null) {
      args.add(limit);
      if (offset != null) {
        args.add(offset);
      }
    } else if (offset != null) {
      args.add(offset);
    }

    // Calculate date boundaries once
    final startTs = startDate?.millisecondsSinceEpoch;
    final endTs = endDate != null
        ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
            .millisecondsSinceEpoch
        : null;

    // Build the query with date filtering in SQL when possible
    final dateWhereClauses = <String>[];
    if (startTs != null) {
      dateWhereClauses.add('''
        (CASE 
          WHEN typeof(sm.date) = 'integer' THEN sm.date >= $startTs
          WHEN typeof(sm.date) = 'text' AND sm.date GLOB '[0-9]*' THEN CAST(sm.date AS INTEGER) >= $startTs
          ELSE strftime('%s', sm.date) * 1000 >= $startTs
        END)
      ''');
    }
    if (endTs != null) {
      dateWhereClauses.add('''
        (CASE 
          WHEN typeof(sm.date) = 'integer' THEN sm.date <= $endTs
          WHEN typeof(sm.date) = 'text' AND sm.date GLOB '[0-9]*' THEN CAST(sm.date AS INTEGER) <= $endTs
          ELSE strftime('%s', sm.date) * 1000 <= $endTs
        END)
      ''');
    }

    final combinedWhere = [
      if (where.isNotEmpty) where,
      if (dateWhereClauses.isNotEmpty) dateWhereClauses.join(' AND ')
    ].where((s) => s.isNotEmpty).join(' AND ');

    final query = '''
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
    ${combinedWhere.isNotEmpty ? 'WHERE $combinedWhere' : ''}
    ORDER BY 
      CASE 
        WHEN typeof(sm.date) = 'integer' THEN sm.date
        WHEN typeof(sm.date) = 'text' AND sm.date GLOB '[0-9]*' THEN CAST(sm.date AS INTEGER)
        ELSE strftime('%s', sm.date) * 1000
      END DESC
    $limitClause
    $offsetClause
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return maps.map((map) => StockMovement.fromMap(map)).toList();
  }

  Future<int> deleteStockMovement(int id) async {
    final db = await _db;

    return await db.transaction((txn) async {
      // delete the stock movement
      final deletedMovementCount = await txn.delete(
        'stock_movements',
        where: 'id = ?',
        whereArgs: [id],
      );

      // delete linked current_stock entries
      final deletedStockCount = await txn.delete(
        'current_stock',
        where: 'source_type = ? AND source_id = ?',
        whereArgs: ['stock_movement', id],
      );

      // return total rows deleted
      return deletedMovementCount + deletedStockCount;
    });
  }

  // Query operations
  Future<List<Map<String, dynamic>>> getCurrentStock() async {
    final db = await _db;

    try {
      // First, get all active products with their details
      final products = await db.rawQuery('''
        SELECT 
          p.*, 
          c.name as category_name, 
          u.name as unit_name, 
          u.symbol as unit_symbol
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN units u ON p.base_unit_id = u.id
        WHERE p.is_active = 1
      ''');

      // Get all warehouses
      final warehouses = await db.query('warehouses');

      final List<Map<String, dynamic>> result = [];

      // Get all stock movements and process them in Dart
      final stockMovements = await db.query('current_stock');

      // Process stock movements to calculate totals
      final stockSummaryMap = <String, Map<String, dynamic>>{};

      for (final movement in stockMovements) {
        final productId = movement['product_id'] as int;
        final warehouseId = movement['warehouse_id'] as int;
        final type = movement['type'] as String;
        final quantity = (movement['quantity'] as num).toDouble();

        final key = '${productId}_$warehouseId';

        if (!stockSummaryMap.containsKey(key)) {
          stockSummaryMap[key] = {
            'product_id': productId,
            'warehouse_id': warehouseId,
            'total_in': 0.0,
            'total_out': 0.0,
          };
        }

        if (type == 'stockIn') {
          stockSummaryMap[key]!['total_in'] += quantity;
        } else if (type == 'stockOut') {
          stockSummaryMap[key]!['total_out'] += quantity;
        }
      }

      // Convert to list and filter out zero/negative stock
      final stockSummary = stockSummaryMap.values.where((stock) {
        final totalIn = (stock['total_in'] as num).toDouble();
        final totalOut = (stock['total_out'] as num).toDouble();
        return (totalIn - totalOut) > 0;
      }).toList();

      // Create a map for faster lookups
      final stockMap = <String, Map<String, dynamic>>{};
      for (final stock in stockSummary) {
        final key = '${stock['product_id']}_${stock['warehouse_id']}';
        stockMap[key] = {
          'total_in': stock['total_in'],
          'total_out': stock['total_out'],
          'current_quantity':
              (stock['total_in'] as num) - (stock['total_out'] as num)
        };
      }

      // Build the result
      for (final product in products) {
        final productId = product['id'] as int;

        for (final warehouse in warehouses) {
          final warehouseId = warehouse['id'] as int;
          final stockKey = '${productId}_$warehouseId';

          if (stockMap.containsKey(stockKey)) {
            final stock = stockMap[stockKey]!;
            result.add({
              'product_id': productId,
              'product_name': product['name'],
              'product_description': product['description'],
              'minimum_stock': product['minimum_stock'],
              'maximum_stock': product['maximum_stock'],
              'has_expiry_date': product['has_expiry_date'],
              'barcode': product['barcode'],
              'sku': product['sku'],
              'brand': product['brand'],
              'category_name': product['category_name'],
              'unit_id': product['base_unit_id'],
              'unit_name': product['unit_name'],
              'unit_symbol': product['unit_symbol'],
              'warehouse_id': warehouseId,
              'warehouse_name': warehouse['name'],
              'total_in': stock['total_in'],
              'total_out': stock['total_out'],
              'current_quantity': stock['current_quantity'],
            });
          }
        }
      }

      // Sort the result by product name and warehouse name
      result.sort((a, b) {
        final nameCompare = (a['product_name'] as String)
            .compareTo(b['product_name'] as String);
        if (nameCompare != 0) return nameCompare;
        return (a['warehouse_name'] as String)
            .compareTo(b['warehouse_name'] as String);
      });

      return result
          .map((row) => row.map((key, value) {
                // Convert numeric values to the correct type
                if (key == 'minimum_stock' ||
                    key == 'maximum_stock' ||
                    key == 'total_in' ||
                    key == 'total_out' ||
                    key == 'current_quantity') {
                  return MapEntry(key, (value as num?)?.toDouble() ?? 0.0);
                } else if (key == 'has_expiry_date') {
                  return MapEntry(key, value == 1);
                }
                return MapEntry(key, value);
              }))
          .toList();
    } catch (e) {
      debugPrint('Error in getCurrentStock: $e');
      rethrow;
    }
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
    final thresholdMs = thresholdDate.millisecondsSinceEpoch;

    // First, get all products with their current stock in each warehouse
    final currentStock = await db.rawQuery('''
      SELECT 
        p.id as product_id,
        p.name as product_name,
        w.id as warehouse_id,
        w.name as warehouse_name,
        SUM(CASE WHEN cs.type = 'stockIn' THEN cs.quantity ELSE 0 END) - 
        SUM(CASE WHEN cs.type = 'stockOut' THEN cs.quantity ELSE 0 END) as current_quantity
      FROM products p
      JOIN current_stock cs ON p.id = cs.product_id
      LEFT JOIN warehouses w ON cs.warehouse_id = w.id
      GROUP BY p.id, w.id
      HAVING current_quantity > 0
    ''');

    // Then get all products with expiry dates in the threshold
    final expiringProducts = await db.rawQuery('''
      SELECT DISTINCT
        sm.product_id,
        p.name as product_name,
        w.id as warehouse_id,
        w.name as warehouse_name,
        sm.expiry_date,
        sm.quantity as movement_quantity
      FROM stock_movements sm
      JOIN products p ON sm.product_id = p.id
      LEFT JOIN warehouses w ON sm.destination_warehouse_id = w.id
      WHERE sm.expiry_date IS NOT NULL
        AND sm.expiry_date <= ?
      ORDER BY sm.expiry_date
    ''', [thresholdMs]);

    // Combine the results to show only products that have both current stock and are expiring
    final result = <Map<String, dynamic>>[];

    for (final expiring in expiringProducts) {
      final productId = expiring['product_id'] as int;
      final warehouseId = expiring['warehouse_id'] as int?;

      // Find matching current stock entry
      final stockEntry = currentStock.firstWhere(
        (stock) =>
            stock['product_id'] == productId &&
            stock['warehouse_id'] == warehouseId,
        orElse: () => <String, dynamic>{},
      );

      if (stockEntry.isNotEmpty) {
        result.add({
          'product_name': expiring['product_name'],
          'warehouse_name': expiring['warehouse_name'],
          'current_quantity': stockEntry['current_quantity'],
          'expiry_date': expiring['expiry_date'],
        });
      }
    }

    return result;
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
