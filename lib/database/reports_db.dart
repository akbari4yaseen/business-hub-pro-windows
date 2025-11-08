import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class ReportsDBHelper {
  static final ReportsDBHelper _instance = ReportsDBHelper._internal();

  factory ReportsDBHelper() {
    return _instance;
  }

  ReportsDBHelper._internal();

  Future<Database> get database async {
    return await DatabaseHelper().database;
  }

  /// Gets detailed stock values with proper additional cost distribution.
  ///
  /// This method focuses on additional cost calculation only.
  /// Unit conversions are handled in the UI for simplicity and accuracy.
  ///
  /// The calculation is simplified into clear steps:
  /// - Step 1: Get latest purchase prices and additional costs
  /// - Step 2: Calculate total purchase value for cost distribution
  /// - Step 3: Apply additional costs proportionally
  ///
  /// Benefits of this approach:
  /// - Easier to understand and maintain
  /// - Better performance with CTEs (Common Table Expressions)
  /// - Clear separation of concerns
  /// - Unit conversion handled in UI for better control
  /// - Simpler database queries
  /// - Easier to debug unit conversion issues
  ///
  /// Returns:
  /// - unit_price_with_additional_cost: Price with additional costs in purchase unit
  /// - purchase_unit_id: Unit ID from purchase
  /// - product_base_unit_id: Base unit ID from product
  /// - Unit conversion is applied in UI using these IDs
  ///
  /// IMPORTANT: The UI converts stock quantity from base unit to purchase unit
  /// before calculating value to ensure accuracy. Example:
  /// - Purchase: 20 tons × 447 per ton = 8,940 total
  /// - Stock: 200 burlap units (50kg each) = 10,000 kg = 10 tons
  /// - Correct calculation: 10 tons × 447 per ton = 4,470
  Future<List<Map<String, dynamic>>> getStockValues({
    int? productId,
    int? warehouseId,
  }) async {
    final db = await database;

    String whereClause = '1=1';
    List<Object?> whereArgs = [];

    if (productId != null) {
      whereClause += ' AND cs.product_id = ?';
      whereArgs.add(productId);
    }

    if (warehouseId != null) {
      whereClause += ' AND cs.warehouse_id = ?';
      whereArgs.add(warehouseId);
    }

    // Step 1: Get purchase items with latest prices and additional costs
    final purchaseItemsQuery = '''
      SELECT 
        pi.product_id,
        pi.unit_price,
        pi.quantity,
        pi.unit_id,
        pi.purchase_id,
        p.additional_cost,
        p.currency
      FROM purchase_items pi
      JOIN purchases p ON pi.purchase_id = p.id
      WHERE pi.id IN (
        SELECT MAX(id)
        FROM purchase_items
        GROUP BY product_id
      )
    ''';

    // Step 2: Calculate total purchase value for additional cost distribution
    final purchaseTotalsQuery = '''
      SELECT 
        purchase_id,
        SUM(unit_price * quantity) as total_purchase_value
      FROM purchase_items
      GROUP BY purchase_id
    ''';

    // Step 3: Main query with simplified calculations (no unit conversion)
    return await db.rawQuery('''
      WITH purchase_items_with_costs AS (
        $purchaseItemsQuery
      ),
      purchase_totals AS (
        $purchaseTotalsQuery
      )
      SELECT 
        cs.product_id,
        cs.warehouse_id,
        prod.name AS product_name,
        wh.name AS warehouse_name,
        COALESCE(pi.currency, 'USD') AS currency,
        cs.quantity,
        COALESCE(
          -- Base unit price + additional cost share per unit
          pi.unit_price +
          (COALESCE(pi.additional_cost, 0) * pi.unit_price * pi.quantity / 
           COALESCE(pt.total_purchase_value, 1)) / pi.quantity
        , 0) AS unit_price_with_additional_cost,
        pi.unit_id AS purchase_unit_id,
        prod.base_unit_id AS product_base_unit_id
      FROM current_stock cs
      JOIN products prod ON cs.product_id = prod.id
      JOIN warehouses wh ON cs.warehouse_id = wh.id
      LEFT JOIN purchase_items_with_costs pi ON pi.product_id = prod.id
      LEFT JOIN purchase_totals pt ON pt.purchase_id = pi.purchase_id
      WHERE $whereClause
      ORDER BY prod.name, wh.name
    ''', whereArgs);
  }

  /// Returns current stock levels by product and warehouse.
  Future<List<Map<String, dynamic>>> getCurrentStockLevels() async {
    final db = await database;

    final sql = '''
      SELECT 
        p.id AS product_id,
        p.name AS product_name,
        c.name AS category_name,
        w.id AS warehouse_id,
        w.name AS warehouse_name,
        cs.quantity
      FROM current_stock cs
      JOIN products p ON cs.product_id = p.id
      LEFT JOIN categories c ON p.category_id = c.id
      JOIN warehouses w ON cs.warehouse_id = w.id
      ORDER BY p.name, w.name
    ''';

    final result = await db.rawQuery(sql);

    return result;
  }

  Future<List<Map<String, dynamic>>> getStockValuesByWarehouse() async {
    final db = await database;

    String whereClause = '1=1';
    List<Object?> whereArgs = [];

    // Step 1: Get purchase items with latest prices and additional costs
    final purchaseItemsQuery = '''
      SELECT 
        pi.product_id,
        pi.unit_price,
        pi.quantity,
        pi.unit_id,
        pi.purchase_id,
        p.additional_cost,
        p.currency
      FROM purchase_items pi
      JOIN purchases p ON pi.purchase_id = p.id
      WHERE pi.id IN (
        SELECT MAX(id)
        FROM purchase_items
        GROUP BY product_id
      )
    ''';

    // Step 2: Calculate total purchase value for additional cost distribution
    final purchaseTotalsQuery = '''
      SELECT 
        purchase_id,
        SUM(unit_price * quantity) as total_purchase_value
      FROM purchase_items
      GROUP BY purchase_id
    ''';

    // Step 3: Main query with simplified calculations (no unit conversion)
    return await db.rawQuery('''
      WITH purchase_items_with_costs AS (
        $purchaseItemsQuery
      ),
      purchase_totals AS (
        $purchaseTotalsQuery
      )
      SELECT 
        wh.id AS warehouse_id,
        wh.name AS warehouse_name,
        COALESCE(pi.currency, 'USD') AS currency,
        COUNT(DISTINCT cs.product_id) AS product_count,
        SUM(cs.quantity) AS total_quantity,
        SUM(
          cs.quantity * 
          COALESCE(
            -- Base unit price + additional cost share per unit
            pi.unit_price +
            (COALESCE(pi.additional_cost, 0) * pi.unit_price * pi.quantity / 
             COALESCE(pt.total_purchase_value, 1)) / pi.quantity
          , 0)
        ) AS total_stock_value_raw
      FROM current_stock cs
      JOIN warehouses wh ON cs.warehouse_id = wh.id
      JOIN products prod ON cs.product_id = prod.id
      LEFT JOIN purchase_items_with_costs pi ON pi.product_id = prod.id
      LEFT JOIN purchase_totals pt ON pt.purchase_id = pi.purchase_id
      WHERE $whereClause
      GROUP BY wh.id, wh.name, COALESCE(pi.currency, 'USD')
      ORDER BY total_stock_value_raw DESC
    ''', whereArgs);
  }

  Future<List<Map<String, dynamic>>> getStockValuesByProduct() async {
    final db = await database;

    String whereClause = '1=1';
    List<Object?> whereArgs = [];

    // Step 1: Get purchase items with latest prices and additional costs
    final purchaseItemsQuery = '''
      SELECT 
        pi.product_id,
        pi.unit_price,
        pi.quantity,
        pi.unit_id,
        pi.purchase_id,
        p.additional_cost,
        p.currency
      FROM purchase_items pi
      JOIN purchases p ON pi.purchase_id = p.id
      WHERE pi.id IN (
        SELECT MAX(id)
        FROM purchase_items
        GROUP BY product_id
      )
    ''';

    // Step 2: Calculate total purchase value for additional cost distribution
    final purchaseTotalsQuery = '''
      SELECT 
        purchase_id,
        SUM(unit_price * quantity) as total_purchase_value
      FROM purchase_items
      GROUP BY purchase_id
    ''';

    // Step 3: Main query with simplified calculations (no unit conversion)
    return await db.rawQuery('''
      WITH purchase_items_with_costs AS (
        $purchaseItemsQuery
      ),
      purchase_totals AS (
        $purchaseTotalsQuery
      )
      SELECT 
        prod.id AS product_id,
        prod.name AS product_name,
        COALESCE(pi.currency, 'USD') AS currency,
        COUNT(DISTINCT cs.warehouse_id) AS warehouse_count,
        SUM(cs.quantity) AS total_quantity,
        SUM(
          cs.quantity * 
          COALESCE(
            -- Base unit price + additional cost share per unit
            pi.unit_price +
            (COALESCE(pi.additional_cost, 0) * pi.unit_price * pi.quantity / 
             COALESCE(pt.total_purchase_value, 1)) / pi.quantity
          , 0)
        ) AS total_stock_value_raw
      FROM current_stock cs
      JOIN products prod ON cs.product_id = prod.id
      LEFT JOIN purchase_items_with_costs pi ON pi.product_id = prod.id
      LEFT JOIN purchase_totals pt ON pt.purchase_id = pi.purchase_id
      WHERE $whereClause
      GROUP BY prod.id, prod.name, COALESCE(pi.currency, 'USD')
      ORDER BY total_stock_value_raw DESC
    ''', whereArgs);
  }

  Future<Map<String, dynamic>> getTotalStockValue() async {
    final db = await database;

    String whereClause = '1=1';
    List<Object?> whereArgs = [];

    final result = await db.rawQuery('''
      SELECT 
        COUNT(DISTINCT cs.product_id) AS total_products,
        COUNT(DISTINCT cs.warehouse_id) AS total_warehouses,
        SUM(cs.quantity) AS total_quantity
      FROM current_stock cs
      JOIN products prod ON cs.product_id = prod.id
      LEFT JOIN (
          SELECT product_id, unit_price, unit_id, purchase_id
          FROM purchase_items
          WHERE id IN (
              SELECT MAX(id)
              FROM purchase_items
              GROUP BY product_id
          )
      ) pi ON pi.product_id = prod.id
      LEFT JOIN purchases p ON pi.purchase_id = p.id
      LEFT JOIN unit_conversions uc 
        ON uc.from_unit_id = pi.unit_id AND uc.to_unit_id = prod.base_unit_id
      WHERE $whereClause
    ''', whereArgs);

    return result.isNotEmpty
        ? result.first
        : {
            'total_products': 0,
            'total_warehouses': 0,
            'total_quantity': 0.0,
          };
  }

  Future<List<Map<String, dynamic>>> getStockValuesByCurrency() async {
    final db = await database;

    String whereClause = '1=1';
    List<Object?> whereArgs = [];

    // Step 1: Get purchase items with latest prices and additional costs
    final purchaseItemsQuery = '''
      SELECT 
        pi.product_id,
        pi.unit_price,
        pi.quantity,
        pi.unit_id,
        pi.purchase_id,
        p.additional_cost,
        p.currency
      FROM purchase_items pi
      JOIN purchases p ON pi.purchase_id = p.id
      WHERE pi.id IN (
        SELECT MAX(id)
        FROM purchase_items
        GROUP BY product_id
      )
    ''';

    // Step 2: Calculate total purchase value for additional cost distribution
    final purchaseTotalsQuery = '''
      SELECT 
        purchase_id,
        SUM(unit_price * quantity) as total_purchase_value
      FROM purchase_items
      GROUP BY purchase_id
    ''';

    // Step 3: Main query with simplified calculations (no unit conversion)
    return await db.rawQuery('''
      WITH purchase_items_with_costs AS (
        $purchaseItemsQuery
      ),
      purchase_totals AS (
        $purchaseTotalsQuery
      )
      SELECT 
        COALESCE(pi.currency, 'USD') AS currency,
        COUNT(DISTINCT cs.product_id) AS product_count,
        COUNT(DISTINCT cs.warehouse_id) AS warehouse_count,
        SUM(cs.quantity) AS total_quantity,
        SUM(
          cs.quantity * 
          COALESCE(
            -- Base unit price + additional cost share per unit
            pi.unit_price +
            (COALESCE(pi.additional_cost, 0) * pi.unit_price * pi.quantity / 
             COALESCE(pt.total_purchase_value, 1)) / pi.quantity
          , 0)
        ) AS total_stock_value_raw
      FROM current_stock cs
      JOIN products prod ON cs.product_id = prod.id
      LEFT JOIN purchase_items_with_costs pi ON pi.product_id = prod.id
      LEFT JOIN purchase_totals pt ON pt.purchase_id = pi.purchase_id
      WHERE $whereClause
      GROUP BY COALESCE(pi.currency, 'USD')
      ORDER BY total_stock_value_raw DESC
    ''', whereArgs);
  }

  /// Returns a list of maps: each contains account_type and count, excluding 'system' types.
  Future<List<Map<String, dynamic>>> getAccountTypeCounts() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT account_type, COUNT(*) as count
      FROM accounts
      WHERE account_type != 'system'
      GROUP BY account_type
    ''');
    return result;
  }

  Future<List<Map<String, dynamic>>> getSystemAccounts() async {
    final db = await database;
    final rows = await db.rawQuery('''
    SELECT
      a.id,
      a.name,
      IFNULL(
        GROUP_CONCAT(
          ad.amount || '::' || ad.currency || '::' || ad.transaction_type,
          '||'
        ),
        ''
      ) AS details_blob
    FROM accounts a
    LEFT JOIN account_details ad
      ON a.id = ad.account_id
    WHERE a.id <> 2 AND a.account_type = ?
    GROUP BY a.id
  ''', ['system']);

    return rows.map((r) {
      final blob = r['details_blob'] as String;
      final details = blob.isEmpty
          ? <Map<String, dynamic>>[]
          : blob.split('||').map((segment) {
              final parts = segment.split('::');
              return {
                'amount': double.parse(parts[0]),
                'currency': parts[1],
                'transaction_type': parts[2],
              };
            }).toList();

      return {
        'id': r['id'],
        'name': r['name'],
        'details': details,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getAllDailyBalances({
    required String accountType,
    required String currency,
  }) async {
    final db = await database;

    final rows = await db.rawQuery('''
    SELECT 
      DATE(ad.date) AS date,
      SUM(
        CASE 
          WHEN ad.transaction_type = 'credit' THEN ad.amount
          WHEN ad.transaction_type = 'debit' THEN -ad.amount
          ELSE 0
        END
      ) AS net
    FROM account_details AS ad
    JOIN accounts AS a ON ad.account_id = a.id
    WHERE a.account_type = ?
      AND a.active = 1
      AND ad.currency = ?
    GROUP BY DATE(ad.date)
    ORDER BY DATE(ad.date);
  ''', [accountType, currency]);

    return rows;
  }

  /// Returns a list of maps: each contains account_type, currency, transaction_type, and sum of amount.
  Future<List<Map<String, dynamic>>> getAccountBalances() async {
    final db = await database;
    final sql = '''
      SELECT 
        a.account_type, 
        ad.currency, 
        ad.transaction_type, 
        SUM(ad.amount) AS total_amount
      FROM accounts a
      JOIN account_details ad ON a.id = ad.account_id
      WHERE a.account_type IN (
        'customer', 'supplier', 'exchanger', 'bank', 'income', 'expense', 'owner', 'company', 'employee'
      )
      GROUP BY a.account_type, ad.currency, ad.transaction_type
      ORDER BY a.account_type, ad.currency, ad.transaction_type
    ''';
    return await db.rawQuery(sql);
  }

  /// count the accounts by type
  Future<Map<String, int>> getAccountCountByType() async {
    final db = await database;
    final sql = '''
    SELECT 
      a.account_type, 
      COUNT(a.id) AS count
    FROM accounts a
    WHERE a.account_type IN (
      'customer', 'supplier', 'exchanger', 'bank', 'income', 'expense', 'owner', 'company', 'employee'
    )
    GROUP BY a.account_type
  ''';
    final rows = await db.rawQuery(sql);

    // Build a map: {account_type: count}
    final Map<String, int> counts = {};
    for (final row in rows) {
      counts[row['account_type'] as String] = row['count'] as int;
    }

    return counts;
  }

  /// Returns total credits and debits for accounts >10 filtered by type, currency and date range
  Future<List<Map<String, dynamic>>> getCreditDebitBalances({
    required String accountType,
    required String currency,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final sql = '''
      SELECT
        ad.transaction_type,
        SUM(ad.amount) AS total
      FROM account_details AS ad
      JOIN accounts AS a
        ON ad.account_id = a.id
      WHERE a.id > 10
        AND a.account_type = ?
        AND ad.currency = ?
        AND ad.date BETWEEN ? AND ?
      GROUP BY ad.transaction_type;
    ''';
    final rows = await db.rawQuery(sql, [
      accountType,
      currency,
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);
    return rows;
  }

  /// Returns active non-system accounts (id, name)
  Future<List<Map<String, dynamic>>> getActiveAccounts() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT id, name
      FROM accounts
      WHERE id > 10 AND active = 1
      ORDER BY name COLLATE NOCASE
    ''');
    return rows;
  }

  /// Returns total credits and debits for a specific account filtered by currency and date range
  Future<List<Map<String, dynamic>>> getCreditDebitBalancesForAccount({
    required int accountId,
    required String currency,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final sql = '''
      SELECT
        ad.transaction_type,
        SUM(ad.amount) AS total
      FROM account_details AS ad
      WHERE ad.account_id = ?
        AND ad.currency = ?
        AND ad.date BETWEEN ? AND ?
      GROUP BY ad.transaction_type;
    ''';
    final rows = await db.rawQuery(sql, [
      accountId,
      currency,
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);
    return rows;
  }
}
