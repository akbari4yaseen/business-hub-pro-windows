import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class InvoiceDBHelper {
  static final InvoiceDBHelper _instance = InvoiceDBHelper._internal();
  factory InvoiceDBHelper() => _instance;
  InvoiceDBHelper._internal();

  Future<Database> get _db async => await DatabaseHelper().database;

  // Invoice Management
  Future<List<Map<String, dynamic>>> getInvoices({
    int? limit,
    int? offset,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? accountId,
    bool includeItems = false,
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <dynamic>[];

    if (status != null) {
      where.add('i.status = ?');
      args.add(status);
    }

    if (startDate != null) {
      where.add('i.date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where.add('i.date <= ?');
      args.add(endDate.toIso8601String());
    }

    if (accountId != null) {
      where.add('i.account_id = ?');
      args.add(accountId);
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ' + where.join(' AND ');

    final invoices = await db.rawQuery('''
      SELECT 
        i.*,
        a.name as account_name,
        (
          SELECT SUM(quantity * unit_price)
          FROM invoice_items
          WHERE invoice_id = i.id
        ) as total_amount
      FROM invoices i
      JOIN accounts a ON i.account_id = a.id
      $whereClause
      ORDER BY i.date DESC
    ''', args);

    if (!includeItems) return invoices;

    // If items are requested, fetch them for each invoice
    final result = <Map<String, dynamic>>[];
    for (final invoice in invoices) {
      final items = await db.rawQuery('''
        SELECT 
          ii.*,
          p.name as product_name,
          u.name as unit_name
        FROM invoice_items ii
        JOIN products p ON ii.product_id = p.id
        LEFT JOIN units u ON p.unit_id = u.id
        WHERE ii.invoice_id = ?
      ''', [invoice['id']]);

      result.add({
        ...invoice,
        'items': items,
      });
    }

    return result;
  }

  Future<Map<String, dynamic>?> getInvoiceById(int id,
      {bool includeItems = true}) async {
    final db = await _db;
    final invoices = await db.rawQuery('''
      SELECT 
        i.*,
        a.name as account_name,
        (
          SELECT SUM(quantity * unit_price)
          FROM invoice_items
          WHERE invoice_id = i.id
        ) as total_amount
      FROM invoices i
      JOIN accounts a ON i.account_id = a.id
      WHERE i.id = ?
    ''', [id]);

    if (invoices.isEmpty) return null;
    final invoice = invoices.first;

    if (!includeItems) return invoice;

    final items = await db.rawQuery('''
      SELECT 
        ii.*,
        p.name as product_name,
        u.name as unit_name
      FROM invoice_items ii
      JOIN products p ON ii.product_id = p.id
      LEFT JOIN units u ON p.unit_id = u.id
      WHERE ii.invoice_id = ?
    ''', [id]);

    return {
      ...invoice,
      'items': items,
    };
  }

  Future<String> generateInvoiceNumber() async {
    final db = await _db;
    final year = DateTime.now().year;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoices WHERE invoice_number LIKE ?',
      ['INV-$year-%'],
    );
    final count = (result.first['count'] as int) + 1;
    return 'INV-$year-${count.toString().padLeft(4, '0')}';
  }

  Future<int> createInvoice({
    required int accountId,
    required String invoiceNumber,
    required DateTime date,
    required String currency,
    String? notes,
    required String status,
    double? paidAmount,
    DateTime? dueDate,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await _db;
    return await db.transaction((txn) async {
      final invoiceId = await txn.insert(
        'invoices',
        {
          'account_id': accountId,
          'invoice_number': invoiceNumber,
          'date': date.toIso8601String(),
          'currency': currency,
          'notes': notes,
          'status': status,
          'paid_amount': paidAmount ?? 0.0,
          'due_date': dueDate?.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      for (final item in items) {
        await txn.insert(
          'invoice_items',
          {
            'invoice_id': invoiceId,
            'product_id': item['product_id'],
            'quantity': item['quantity'],
            'unit_price': item['unit_price'],
            'description': item['description'],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      }

      return invoiceId;
    });
  }

  Future<void> updateInvoice({
    required int id,
    int? accountId,
    DateTime? date,
    String? currency,
    String? notes,
    String? status,
    double? paidAmount,
    DateTime? dueDate,
    List<Map<String, dynamic>>? items,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (accountId != null) updates['account_id'] = accountId;
      if (date != null) updates['date'] = date.toIso8601String();
      if (currency != null) updates['currency'] = currency;
      if (notes != null) updates['notes'] = notes;
      if (status != null) updates['status'] = status;
      if (paidAmount != null) updates['paid_amount'] = paidAmount;
      if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();

      await txn.update(
        'invoices',
        updates,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (items != null) {
        // Delete existing items
        await txn.delete(
          'invoice_items',
          where: 'invoice_id = ?',
          whereArgs: [id],
        );

        // Insert new items
        for (final item in items) {
          await txn.insert(
            'invoice_items',
            {
              'invoice_id': id,
              'product_id': item['product_id'],
              'quantity': item['quantity'],
              'unit_price': item['unit_price'],
              'description': item['description'],
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
          );
        }
      }
    });
  }

  Future<void> deleteInvoice(int id) async {
    final db = await _db;
    await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getOverdueInvoices(
      {bool includeItems = true}) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    final invoices = await db.rawQuery('''
      SELECT 
        i.*,
        a.name as account_name,
        (
          SELECT SUM(quantity * unit_price)
          FROM invoice_items
          WHERE invoice_id = i.id
        ) as total_amount
      FROM invoices i
      JOIN accounts a ON i.account_id = a.id
      WHERE i.due_date < ? 
        AND i.status != 'paid'
        AND i.status != 'cancelled'
      ORDER BY i.due_date ASC
    ''', [now]);

    if (!includeItems) return invoices;

    final result = <Map<String, dynamic>>[];
    for (final invoice in invoices) {
      final items = await db.rawQuery('''
        SELECT 
          ii.*,
          p.name as product_name,
          u.name as unit_name
        FROM invoice_items ii
        JOIN products p ON ii.product_id = p.id
        LEFT JOIN units u ON p.unit_id = u.id
        WHERE ii.invoice_id = ?
      ''', [invoice['id']]);

      result.add({
        ...invoice,
        'items': items,
      });
    }

    return result;
  }

  Future<void> recordPayment(int invoiceId, double amount) async {
    final db = await _db;

    return await db.transaction((txn) async {
      // Get current invoice
      final invoiceResult = await txn.query(
        'invoices',
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      if (invoiceResult.isEmpty) {
        throw Exception('Invoice not found');
      }

      final invoice = invoiceResult.first;
      final currentPaidAmount = invoice['paid_amount'] as double? ?? 0.0;
      final newPaidAmount = currentPaidAmount + amount;

      // Get total amount
      final totalResult = await txn.rawQuery('''
        SELECT SUM(quantity * unit_price) as total 
        FROM invoice_items 
        WHERE invoice_id = ?
      ''', [invoiceId]);

      final totalAmount = totalResult.first['total'] as double? ?? 0.0;

      // Determine new status
      String newStatus;
      if (newPaidAmount >= totalAmount) {
        newStatus = 'paid';
      } else if (newPaidAmount > 0) {
        newStatus = 'partiallyPaid';
      } else {
        newStatus = 'finalized';
      }

      // Update the invoice
      await txn.update(
        'invoices',
        {
          'paid_amount': newPaidAmount,
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
    });
  }

  Future<void> updateStockQuantity(
      int stockId,
      double newQuantity,
      int zoneId, // Same here
      int binId,
      int productId) async {
    final db = await _db;

    // Update the stock record
    await db.update(
      'current_stock',
      {'quantity': newQuantity},
      where: 'id = ?',
      whereArgs: [stockId],
    );

    final now = DateTime.now().toIso8601String();

    // Insert a stock movement record for tracking
    await db.insert('stock_movements', {
      'product_id': productId,
      'quantity': -(newQuantity), // negative because stock reduced
      'type': 'SALE', // type matches column in table
      'reference': 'Invoice Sale',
      'notes': null,
      'expiry_date': null,
      'created_at': now,
      'updated_at': now,
    });
  }
}
