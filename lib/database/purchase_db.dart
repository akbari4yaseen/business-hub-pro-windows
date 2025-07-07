import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';

class PurchaseDBHelper {
  static final PurchaseDBHelper _instance = PurchaseDBHelper._internal();
  factory PurchaseDBHelper() => _instance;
  PurchaseDBHelper._internal();

  Future<Database> get _db async => await DatabaseHelper().database;

  // Transaction helper
  Future<void> transaction(
      Future<void> Function(Transaction txn) action) async {
    final db = await _db;
    await db.transaction(action);
  }

// Purchase operations
  Future<int> createPurchase(Purchase purchase) async {
    final db = await _db;
    return await db.transaction((txn) async {
      // Insert purchase and get ID
      final purchaseId = await txn.insert('purchases', purchase.toMap());

      // Fetch supplier name from accounts table
      final supplierResult = await txn.query(
        'accounts',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [purchase.supplierId],
        limit: 1,
      );

      final supplierName = supplierResult.isNotEmpty
          ? supplierResult.first['name'] as String
          : 'Unknown Supplier';

      // Insert into account_details
      await txn.insert('account_details', {
        'date': purchase.date.toString(),
        'account_id': purchase.supplierId,
        'amount': purchase.totalAmount,
        'currency': purchase.currency,
        'transaction_type': 'credit',
        'description':
            'Purchase of Invoice ${purchase.invoiceNumber} from $supplierName',
        'transaction_id': purchaseId,
        'transaction_group': 'purchase',
      });

      return purchaseId;
    });
  }

  Future<List<Map<String, dynamic>>> getPurchases({
    int? limit,
    int? offset,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    int? supplierId,
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <dynamic>[];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('(LOWER(p.invoice_number) LIKE ? OR LOWER(a.name) LIKE ?)');
      final query = '%${searchQuery.toLowerCase()}%';
      args.addAll([query, query]);
    }

    if (startDate != null) {
      where.add('p.date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where.add('p.date <= ?');
      args.add(endDate.toIso8601String());
    }

    if (supplierId != null) {
      where.add('p.supplier_id = ?');
      args.add(supplierId);
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ' + where.join(' AND ');

    final sql = '''
      SELECT 
        p.*,
        a.name as supplier_name
      FROM purchases p
      LEFT JOIN accounts a ON p.supplier_id = a.id
      $whereClause
      ORDER BY p.date DESC
      ${limit != null ? 'LIMIT ?' : ''}
      ${offset != null ? 'OFFSET ?' : ''}
    ''';

    if (limit != null) {
      args.add(limit);
      if (offset != null) {
        args.add(offset);
      }
    }

    return await db.rawQuery(sql, args);
  }

  Future<Map<String, dynamic>?> getPurchaseById(int? id) async {
    if (id == null) return null;

    final db = await _db;
    final result = await db.rawQuery('''
      SELECT 
        p.*,
        a.name as supplier_name
      FROM purchases p
      LEFT JOIN accounts a ON p.supplier_id = a.id
      WHERE p.id = ?
    ''', [id]);

    if (result.isEmpty) return null;

    final purchase = result.first;
    final items = await getPurchaseItems(id);
    purchase['items'] = items;

    return purchase;
  }

  Future<void> updatePurchase(Purchase purchase) async {
    final db = await _db;
    await db.update(
      'purchases',
      purchase.toMap(),
      where: 'id = ?',
      whereArgs: [purchase.id],
    );
  }

  Future<void> deletePurchase(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Delete purchase items first
      await txn.delete(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [id],
      );

      // Delete account details for this purchase
      await txn.delete(
        'account_details',
        where: 'transaction_group = ? AND transaction_id = ?',
        whereArgs: ['purchase', id],
      );

      // Delete the purchase
      await txn.delete(
        'purchases',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // Purchase item operations
  Future<int> createPurchaseItem(PurchaseItem item) async {
    final db = await _db;
    return await db.insert('purchase_items', item.toMap());
  }

  Future<List<Map<String, dynamic>>> getPurchaseItems(int? purchaseId) async {
    if (purchaseId == null) return [];

    final db = await _db;
    return await db.rawQuery('''
      SELECT 
        pi.*,
        p.name as product_name,
        u.name as unit_name
      FROM purchase_items pi
      LEFT JOIN products p ON pi.product_id = p.id
      LEFT JOIN units u ON pi.unit_id = u.id
      WHERE pi.purchase_id = ?
      ORDER BY pi.id
    ''', [purchaseId]);
  }

  Future<void> updatePurchaseItem(PurchaseItem item) async {
    final db = await _db;
    await db.update(
      'purchase_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deletePurchaseItem(int id) async {
    final db = await _db;
    await db.delete(
      'purchase_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Report helper methods
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT DISTINCT 
        a.id,
        a.name
      FROM accounts a
      JOIN purchases p ON a.id = p.supplier_id
      WHERE a.account_type = 'supplier'
      ORDER BY a.name
    ''');
  }

  Future<List<String>> getCurrencies() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT DISTINCT currency
      FROM purchases
      WHERE currency IS NOT NULL AND currency != ''
      ORDER BY currency
    ''');
    
    return result.map((row) => row['currency'] as String).toList();
  }
}
