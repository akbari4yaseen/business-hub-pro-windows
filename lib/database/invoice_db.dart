import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'package:flutter/foundation.dart';

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
    String? searchQuery,
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

    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('(LOWER(i.invoice_number) LIKE ? OR LOWER(a.name) LIKE ?)');
      final query = '%${searchQuery.toLowerCase()}%';
      args.addAll([query, query]);
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ' + where.join(' AND ');

    // Add pagination parameters
    if (limit != null) {
      args.add(limit);
      if (offset != null) {
        args.add(offset);
      }
    } else if (offset != null) {
      args.add(offset);
    }

    try {
      final invoices = await db.rawQuery('''
        SELECT 
          i.*,
          a.name as account_name,
          CASE 
            WHEN i.user_entered_total IS NOT NULL THEN i.user_entered_total
            ELSE CAST(COALESCE(
              (SELECT SUM(quantity * unit_price)
              FROM invoice_items
              WHERE invoice_id = i.id),
              0
            ) AS REAL)
          END as total_amount
        FROM invoices i
        JOIN accounts a ON i.account_id = a.id
        $whereClause
        ORDER BY i.date DESC
        ${limit != null ? 'LIMIT ?' : ''}
        ${offset != null ? 'OFFSET ?' : ''}
      ''', args);

      if (!includeItems) return invoices;

      // If items are requested, fetch them for each invoice in a single query

      final invoiceIds = invoices.map((i) => i['id'] as int).toList();
      if (invoiceIds.isEmpty) return invoices;

      final items = await db.rawQuery('''
        SELECT 
          ii.*,
          p.name as product_name,
          u.name as unit_name
        FROM invoice_items ii
        JOIN products p ON ii.product_id = p.id
        LEFT JOIN units u ON p.unit_id = u.id
        WHERE ii.invoice_id IN (${List.filled(invoiceIds.length, '?').join(',')})
      ''', invoiceIds);

      // Group items by invoice_id
      final itemsByInvoice = <int, List<Map<String, dynamic>>>{};
      for (final item in items) {
        final invoiceId = item['invoice_id'] as int;
        itemsByInvoice.putIfAbsent(invoiceId, () => []).add(item);
      }

      // Combine invoices with their items
      final result = invoices.map((invoice) {
        final invoiceId = invoice['id'] as int;
        return {
          ...invoice,
          'items': itemsByInvoice[invoiceId] ?? [],
        };
      }).toList();

      return result;
    } catch (e) {
      debugPrint('Error in getInvoices: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getInvoiceById(int id,
      {bool includeItems = true}) async {
    final db = await _db;
    try {
      final invoices = await db.rawQuery('''
        SELECT 
          i.*,
          a.name as account_name,
          CASE 
            WHEN i.user_entered_total IS NOT NULL THEN i.user_entered_total
            ELSE COALESCE(
              (SELECT SUM(quantity * unit_price)
              FROM invoice_items
              WHERE invoice_id = i.id),
              0
            )
          END as total_amount
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
    } catch (e) {
      debugPrint('Error in getInvoiceById: $e');
      rethrow;
    }
  }

  Future<String> generateInvoiceNumber() async {
    final db = await _db;
    try {
      final year = DateTime.now().year;

      // Get the max invoice number for current year
      final result = await db.rawQuery(
        '''
      SELECT invoice_number FROM invoices
      WHERE invoice_number LIKE ?
      ORDER BY invoice_number DESC
      LIMIT 1
      ''',
        ['INV-$year-%'],
      );

      int nextNumber = 1;

      if (result.isNotEmpty) {
        final lastInvoiceNumber = result.first['invoice_number'] as String;

        // Extract the last 4 digits
        final match =
            RegExp(r'INV-\d{4}-(\d{4})').firstMatch(lastInvoiceNumber);
        if (match != null) {
          final lastNumber = int.tryParse(match.group(1)!) ?? 0;
          nextNumber = lastNumber + 1;
        }
      }

      return 'INV-$year-${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      debugPrint('Error generating invoice number: $e');
      rethrow;
    }
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
    double? userEnteredTotal,
    required List<Map<String, dynamic>> items,
    bool isPreSale = false,
  }) async {
    final db = await _db;
    try {
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
            'user_entered_total': userEnteredTotal,
            'is_pre_sale': isPreSale ? 1 : 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );

        // Batch insert items
        final batch = txn.batch();
        for (final item in items) {
          batch.insert(
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
        await batch.commit();

        return invoiceId;
      });
    } catch (e) {
      debugPrint('Error creating invoice: $e');
      rethrow;
    }
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
    double? userEnteredTotal,
    List<Map<String, dynamic>>? items,
    bool? isPreSale,
  }) async {
    final db = await _db;
    try {
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

        // Always update userEnteredTotal (can be null to remove manual adjustment)
        updates['user_entered_total'] = userEnteredTotal;
        
        // Update isPreSale if provided
        if (isPreSale != null) updates['is_pre_sale'] = isPreSale ? 1 : 0;

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

          // Batch insert new items
          final batch = txn.batch();
          for (final item in items) {
            batch.insert(
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
          await batch.commit();
        }
      });
    } catch (e) {
      debugPrint('Error updating invoice: $e');
      rethrow;
    }
  }

  Future<void> deleteInvoice(int id) async {
    final db = await _db;
    try {
      await db.transaction((txn) async {
        // Delete items first due to foreign key constraint
        await txn.delete(
          'invoice_items',
          where: 'invoice_id = ?',
          whereArgs: [id],
        );

        // Then delete the invoice
        await txn.delete(
          'invoices',
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getOverdueInvoices(
      {bool includeItems = true}) async {
    try {
      final db = await _db;
      final now = DateTime.now().toIso8601String();

      final invoices = await db.rawQuery('''
        SELECT 
          i.*,
          a.name as account_name,
          CASE 
            WHEN i.user_entered_total IS NOT NULL THEN i.user_entered_total
            ELSE CAST(COALESCE(
              (SELECT SUM(quantity * unit_price)
              FROM invoice_items
              WHERE invoice_id = i.id),
              0
            ) AS REAL)
          END as total_amount
        FROM invoices i
        JOIN accounts a ON i.account_id = a.id
        WHERE i.due_date < ? 
          AND i.status != 'paid'
          AND i.status != 'cancelled'
        ORDER BY i.due_date ASC
      ''', [now]);

      if (!includeItems) return invoices;

      // Fetch all items in a single query
      final invoiceIds = invoices.map((i) => i['id'] as int).toList();
      if (invoiceIds.isEmpty) return invoices;

      final items = await db.rawQuery('''
        SELECT 
          ii.*,
          p.name as product_name,
          u.name as unit_name
        FROM invoice_items ii
        JOIN products p ON ii.product_id = p.id
        LEFT JOIN units u ON p.unit_id = u.id
        WHERE ii.invoice_id IN (${List.filled(invoiceIds.length, '?').join(',')})
      ''', invoiceIds);

      // Group items by invoice_id
      final itemsByInvoice = <int, List<Map<String, dynamic>>>{};
      for (final item in items) {
        final invoiceId = item['invoice_id'] as int;
        itemsByInvoice.putIfAbsent(invoiceId, () => []).add(item);
      }

      // Combine invoices with their items
      final result = invoices.map((invoice) {
        final invoiceId = invoice['id'] as int;
        return {
          ...invoice,
          'items': itemsByInvoice[invoiceId] ?? [],
        };
      }).toList();

      return result;
    } catch (e) {
      debugPrint('Error in getOverdueInvoices: $e');
      rethrow;
    }
  }

  Future<void> recordPayment(
    int invoiceId,
    double amount, {
    required String localizedDescription,
  }) async {
    final db = await _db;
    try {
      await db.transaction((txn) async {
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
        final accountId = invoice['account_id'] as int;
        final currency = invoice['currency'] as String;
        final invoiceNumber = invoice['invoice_number'] as String;

        // Get total amount - use userEnteredTotal if available, otherwise calculate from items
        double totalAmount;
        final userEnteredTotal = invoice['user_entered_total'] as double?;

        if (userEnteredTotal != null) {
          totalAmount = userEnteredTotal;
        } else {
          final totalResult = await txn.rawQuery('''
            SELECT COALESCE(SUM(quantity * unit_price), 0) as total 
            FROM invoice_items 
            WHERE invoice_id = ?
          ''', [invoiceId]);
          totalAmount = totalResult.first['total'] as double? ?? 0.0;
        }

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

        // Record payment in account_details
        await txn.insert(
          'account_details',
          {
            'date': DateTime.now().toIso8601String(),
            'account_id': accountId,
            'amount': amount,
            'currency': currency,
            'transaction_type': 'credit',
            'description': '${localizedDescription} $invoiceNumber',
            'transaction_id': invoiceId,
            'transaction_group': 'invoice_payment',
          },
        );
        await txn.insert(
          'account_details',
          {
            'date': DateTime.now().toIso8601String(),
            'account_id': 1,
            'amount': amount,
            'currency': currency,
            'transaction_type': 'credit',
            'description': '${localizedDescription} $invoiceNumber',
            'transaction_id': invoiceId,
            'transaction_group': 'invoice_payment',
          },
        );
      });
    } catch (e) {
      debugPrint('Error recording payment: $e');
      rethrow;
    }
  }

  Future<void> finalizeInvoice(
    int invoiceId, {
    required String localizedDescription,
  }) async {
    final db = await _db;
    try {
      await db.transaction((txn) async {
        // Get invoice details
        final invoiceResult = await txn.query(
          'invoices',
          where: 'id = ?',
          whereArgs: [invoiceId],
        );

        if (invoiceResult.isEmpty) {
          throw Exception('Invoice not found');
        }

        final invoice = invoiceResult.first;
        final accountId = invoice['account_id'] as int;
        final currency = invoice['currency'] as String;
        final invoiceNumber = invoice['invoice_number'] as String;

        // Get total amount - use userEnteredTotal if available, otherwise calculate from items
        double totalAmount;
        final userEnteredTotal = invoice['user_entered_total'] as double?;

        if (userEnteredTotal != null) {
          totalAmount = userEnteredTotal;
        } else {
          final totalResult = await txn.rawQuery('''
            SELECT COALESCE(SUM(quantity * unit_price), 0) as total 
            FROM invoice_items 
            WHERE invoice_id = ?
          ''', [invoiceId]);
          totalAmount = totalResult.first['total'] as double? ?? 0.0;
        }

        // Update invoice status
        await txn.update(
          'invoices',
          {
            'status': 'finalized',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [invoiceId],
        );

        // Record invoice amount in account_details
        await txn.insert(
          'account_details',
          {
            'date': DateTime.now().toIso8601String(),
            'account_id': accountId,
            'amount': totalAmount,
            'currency': currency,
            'transaction_type': 'debit',
            'description': '${localizedDescription} $invoiceNumber',
            'transaction_id': invoiceId,
            'transaction_group': 'invoice',
          },
        );
      });
    } catch (e) {
      debugPrint('Error finalizing invoice: $e');
      rethrow;
    }
  }

  Future<void> updateStockQuantity(int stockId, double newQuantity,
      int warehouse_id, int productId, String invoiceNumber) async {
    final db = await _db;
    try {
      await db.transaction((txn) async {
        // Update the stock record
        await txn.update(
          'current_stock',
          {'quantity': newQuantity},
          where: 'id = ?',
          whereArgs: [stockId],
        );

        // Insert a stock movement record for tracking
        // await txn.insert(
        //   'stock_movements',
        //   {
        //     'product_id': productId,
        //     'source_warehouse_id': warehouse_id,
        //     'destination_warehouse_id': null,
        //     'quantity': newQuantity,
        //     'type': 'SALE',
        //     'reference': invoiceNumber,
        //     'notes': '',
        //     'expiry_date': null,
        //     'date': DateTime.now().toIso8601String(),
        //     'created_at': DateTime.now().toIso8601String(),
        //     'updated_at': DateTime.now().toIso8601String(),
        //   },
        // );
      });
    } catch (e) {
      debugPrint('Error updating stock quantity: $e');
      rethrow;
    }
  }

  // Add search method
  Future<List<Map<String, dynamic>>> searchInvoices({
    required String query,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? accountId,
  }) async {
    return getInvoices(
      searchQuery: query,
      status: status,
      startDate: startDate,
      endDate: endDate,
      accountId: accountId,
      includeItems: true,
    );
  }

  Future<void> cancelInvoice(int invoiceId,
      {required String localizedDescription}) async {
    final db = await _db;
    try {
      await db.transaction((txn) async {
        // Get invoice details
        final invoiceResult = await txn.query(
          'invoices',
          where: 'id = ?',
          whereArgs: [invoiceId],
        );

        if (invoiceResult.isEmpty) {
          throw Exception('Invoice not found');
        }

        final invoice = invoiceResult.first;
        final accountId = invoice['account_id'] as int;
        final currency = invoice['currency'] as String;
        final invoiceNumber = invoice['invoice_number'] as String;
        final status = invoice['status'] as String;

        // Only allow cancellation of finalized or partially paid invoices
        if (status != 'finalized' && status != 'partiallyPaid') {
          throw Exception(
              'Only finalized or partially paid invoices can be cancelled');
        }

        // Update invoice status to cancelled
        await txn.update(
          'invoices',
          {
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [invoiceId],
        );

        // If the invoice was finalized, remove the debit entry from account_details
        if (status == 'finalized') {
          await txn.delete(
            'account_details',
            where: 'transaction_id = ? AND transaction_group = ?',
            whereArgs: [invoiceId, 'invoice'],
          );
        }

        // If the invoice was partially paid, add a credit entry to account_details
        if (status == 'partiallyPaid') {
          final paidAmount = invoice['paid_amount'] as double? ?? 0.0;
          if (paidAmount > 0) {
            await txn.insert(
              'account_details',
              {
                'date': DateTime.now().toIso8601String(),
                'account_id': accountId,
                'amount': paidAmount,
                'currency': currency,
                'transaction_type': 'credit',
                'description':
                    '${localizedDescription} $invoiceNumber (Cancellation)',
                'transaction_id': invoiceId,
                'transaction_group': 'invoice_cancellation',
              },
            );
          }
        }

        // Get invoice items to revert stock
        final items = await txn.query(
          'invoice_items',
          where: 'invoice_id = ?',
          whereArgs: [invoiceId],
        );

        // Revert stock for each item
        for (final item in items) {
          final productId = item['product_id'] as int;
          final quantity = item['quantity'] as double;

          // Get current stock
          final stockResult = await txn.query(
            'current_stock',
            where: 'product_id = ?',
            whereArgs: [productId],
          );

          if (stockResult.isNotEmpty) {
            final stock = stockResult.first;
            final currentQuantity = stock['quantity'] as double;
            final stockId = stock['id'] as int;

            // Update stock quantity
            await txn.update(
              'current_stock',
              {'quantity': currentQuantity + quantity},
              where: 'id = ?',
              whereArgs: [stockId],
            );
          }
        }
      });
    } catch (e) {
      debugPrint('Error cancelling invoice: $e');
      rethrow;
    }
  }

  Future<List<String>> getCurrencies() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT DISTINCT currency
      FROM invoices
      WHERE currency IS NOT NULL AND currency != ''
      ORDER BY currency
    ''');

    return result.map((row) => row['currency'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT DISTINCT 
        a.id,
        a.name
      FROM accounts a
      JOIN invoices i ON a.id = i.account_id
      WHERE a.account_type = 'customer'
      ORDER BY a.name
    ''');
  }
}
