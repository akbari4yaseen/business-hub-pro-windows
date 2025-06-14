import 'package:sqflite/sqflite.dart';
import '../models/exchange.dart';
import 'database_helper.dart';

class ExchangeDBHelper {
  static final ExchangeDBHelper _instance = ExchangeDBHelper._internal();
  factory ExchangeDBHelper() => _instance;
  ExchangeDBHelper._internal();

  Future<Database> get _db async => await DatabaseHelper().database;

  Future<int> createExchange(Exchange exchange) async {
    final db = await _db;
    return await db.insert('exchanges', exchange.toMap());
  }

  Future<List<Exchange>> getExchanges({
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
    String? fromCurrency,
    String? toCurrency,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await _db;
    final offset = (page - 1) * pageSize;
    final where = <String>[];
    final args = <dynamic>[];

    // Build filters
    if (searchQuery?.isNotEmpty ?? false) {
      where.add('(LOWER(e.description) LIKE ? OR LOWER(acc_from.name) LIKE ? OR LOWER(acc_to.name) LIKE ?)');
      final q = '%${searchQuery!.toLowerCase()}%';
      args.addAll([q, q, q]);
    }
    if (fromCurrency != null && fromCurrency != 'all') {
      where.add('e.from_currency = ?');
      args.add(fromCurrency);
    }
    if (toCurrency != null && toCurrency != 'all') {
      where.add('e.to_currency = ?');
      args.add(toCurrency);
    }
    if (fromDate != null) {
      where.add('DATE(e.date) >= DATE(?)');
      args.add(fromDate.toIso8601String());
    }
    if (toDate != null) {
      where.add('DATE(e.date) <= DATE(?)');
      args.add(toDate.toIso8601String());
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ' + where.join(' AND ');

    // Inner subquery: filter+order+page the exchange rows
    final innerSql = '''
      SELECT
        e.*
      FROM exchanges e
      JOIN accounts acc_from ON e.from_account_id = acc_from.id
      JOIN accounts acc_to ON e.to_account_id = acc_to.id
      $whereClause
      ORDER BY e.date DESC
      LIMIT ? OFFSET ?
    ''';
    args.addAll([pageSize, offset]);

    // Outer query: attach account names, preserve ordering
    final sql = '''
      SELECT
        e2.*,
        acc_from.name AS from_account_name,
        acc_to.name AS to_account_name
      FROM (
        $innerSql
      ) AS e2
      JOIN accounts acc_from ON e2.from_account_id = acc_from.id
      JOIN accounts acc_to ON e2.to_account_id = acc_to.id
      ORDER BY e2.date DESC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
    return List.generate(maps.length, (i) => Exchange.fromMap(maps[i]));
  }

  Future<List<Exchange>> searchExchanges({
    required String query,
    String? fromCurrency,
    String? toCurrency,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return getExchanges(
      searchQuery: query,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<List<Exchange>> getExchangesByAccount(int accountId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'exchanges',
      where: 'from_account_id = ? OR to_account_id = ?',
      whereArgs: [accountId, accountId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Exchange.fromMap(maps[i]));
  }

  Future<Exchange?> getExchange(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'exchanges',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Exchange.fromMap(maps.first);
  }

  Future<void> updateExchange(Exchange exchange) async {
    final db = await _db;
    await db.update(
      'exchanges',
      exchange.toMap(),
      where: 'id = ?',
      whereArgs: [exchange.id],
    );
  }

  Future<void> deleteExchange(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'exchanges',
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'account_details',
        where: 'transaction_id = ? AND transaction_group = ?',
        whereArgs: [id, 'exchange'],
      );
    });
  }

  Future<void> performExchange({
    required int fromAccountId,
    required int toAccountId,
    required String fromCurrency,
    required String toCurrency,
    required double amount,
    required double rate,
    required double resultAmount,
    required String operator,
    String? description,
    double? expectedRate,
    required String transactionType,
    required DateTime date,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
     

      double profitLoss = 0;
      if (expectedRate != null) {
        double expectedAmount;
        if (operator == '*') {
          expectedAmount = resultAmount / rate * expectedRate;
        } else {
          expectedAmount = resultAmount * rate / expectedRate;
        }
        profitLoss = resultAmount - expectedAmount;
      }

      final exchange = Exchange(
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        operator: operator,
        amount: amount,
        rate: rate,
        resultAmount: resultAmount,
        expectedRate: expectedRate,
        profitLoss: profitLoss,
        transactionType: transactionType,
        description: description,
        date: date.toString(),
      );

      final exchangeId = await txn.insert('exchanges', exchange.toMap());

      await txn.insert('account_details', {
        'date': date.toString(),
        'account_id': fromAccountId,
        'amount': amount,
        'currency': fromCurrency,
        'transaction_type': 'debit',
        'description': description ?? 'Currency exchange to $toCurrency',
        'transaction_id': exchangeId,
        'transaction_group': 'exchange',
      });

      await txn.insert('account_details', {
        'date': date.toString(),
        'account_id': toAccountId,
        'amount': resultAmount,
        'currency': toCurrency,
        'transaction_type': 'credit',
        'description': description ?? 'Currency exchange from $fromCurrency',
        'transaction_id': exchangeId,
        'transaction_group': 'exchange',
      });

      if (profitLoss > 0) {
        await txn.insert('account_details', {
          'date': date.toString(),
          'account_id': 9, // profit account
          'amount': profitLoss.abs(),
          'currency': toCurrency,
          'transaction_type': 'credit',
          'description': description ?? 'Profit from currency exchange',
          'transaction_id': exchangeId,
          'transaction_group': 'exchange',
        });
      } else if (profitLoss < 0) {
        await txn.insert('account_details', {
          'date': date.toString(),
          'account_id': 10, // loss account
          'amount': profitLoss.abs(),
          'currency': toCurrency,
          'transaction_type': 'debit',
          'description': description ?? 'Loss from currency exchange',
          'transaction_id': exchangeId,
          'transaction_group': 'exchange',
        });
      }
    });
  }
}
