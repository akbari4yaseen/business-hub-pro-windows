import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class AccountDBHelper {
  static final AccountDBHelper _instance = AccountDBHelper._internal();

  factory AccountDBHelper() {
    return _instance;
  }

  AccountDBHelper._internal();

  Future<Database> get database async {
    return await DatabaseHelper().database;
  }

  Future<List<Map<String, dynamic>>> getOptionAccounts() async {
    Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT 
      id,
      name,
      account_type
    FROM accounts
    WHERE id <> 2 AND active = 1 
    ORDER BY 
      id DESC;
  ''');
    return result;
  }

  /// Fetches a paginated list of accounts with optional filters for active status, search query, type, and currency.
  Future<List<Map<String, dynamic>>> getAccountsPage({
    int offset = 0,
    int limit = 30,
    bool? isActive,
    String? searchQuery,
    String? accountType,
    String? currency,
  }) async {
    final db = await database;

    // Build WHERE clauses
    final where = <String>[];
    final args = <dynamic>[];

    // Active filter
    if (isActive != null) {
      where.add('a.active = ?');
      args.add(isActive ? 1 : 0);
    }

    // Exclude system account
    where.add('a.id <> 2');

    // Search by name or address
    if (searchQuery?.isNotEmpty ?? false) {
      where.add('(LOWER(a.name) LIKE ? OR LOWER(a.address) LIKE ?)');
      final q = '%${searchQuery!.toLowerCase()}%';
      args.addAll([q, q]);
    }

    // Account type filter
    if (accountType != null && accountType != 'all') {
      where.add('a.account_type = ?');
      args.add(accountType);
    }

    // Currency filter: ensure at least one transaction in that currency
    if (currency != null && currency != 'all') {
      where.add('EXISTS ('
          ' SELECT 1 FROM account_details ad '
          ' WHERE ad.account_id = a.id AND ad.currency = ?'
          ')');
      args.add(currency);
    }

    // 1) Fetch paged IDs matching filters
    final idQuery = '''
      SELECT a.id
      FROM accounts AS a
      LEFT JOIN (
        SELECT account_id, COALESCE(SUM(amount), 0) AS total_balance
        FROM account_details
        GROUP BY account_id
      ) AS b ON a.id = b.account_id
      ${where.isNotEmpty ? 'WHERE ' + where.join(' AND ') : ''}
      ORDER BY a.id DESC
      LIMIT ? OFFSET ?;
    ''';
    final idArgs = List.of(args)..addAll([limit, offset]);
    final idRows = await db.rawQuery(idQuery, idArgs);
    final ids = idRows.map((r) => r['id'] as int).toList();
    if (ids.isEmpty) return [];

    // 2) Fetch details for those IDs
    final placeholders = List.filled(ids.length, '?').join(',');
    final detailQuery = '''
      SELECT
        a.id,
        a.name,
        a.phone,
        a.account_type,
        a.address,
        a.active,
        a.created_at,
        ad.amount,
        ad.currency,
        ad.transaction_type
      FROM accounts AS a
      LEFT JOIN account_details AS ad
        ON a.id = ad.account_id
      WHERE a.id IN ($placeholders)
      ORDER BY a.id DESC;
    ''';
    final detailRows = await db.rawQuery(detailQuery, ids);

    // 3) Reassemble into structured list
    final Map<int, Map<String, dynamic>> map = {};
    for (final row in detailRows) {
      final id = row['id'] as int;
      if (!map.containsKey(id)) {
        map[id] = {
          'id': id,
          'name': row['name'],
          'phone': row['phone'],
          'account_type': row['account_type'],
          'address': row['address'],
          'active': row['active'],
          'created_at': row['created_at'],
          'account_details': <Map<String, dynamic>>[],
        };
      }
      if (row['amount'] != null) {
        map[id]!['account_details'].add({
          'amount': row['amount'],
          'currency': row['currency'],
          'transaction_type': row['transaction_type'],
        });
      }
    }

    return map.values.toList();
  }

  Future<void> insertAccount(Map<String, dynamic> account) async {
    Database db = await database;
    await db.insert(
      'accounts',
      account,
      conflictAlgorithm: ConflictAlgorithm.fail, // Fails if duplicate entry
    );
  }

  Future<void> updateAccount(int id, Map<String, dynamic> updatedData) async {
    // do not update system accounts
    if (id < 11) {
      return;
    }

    Database db = await database;
    await db.update('accounts', updatedData, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAccount(int id) async {
    // do not delete system accounts
    if (id < 11) {
      return;
    }
    Database db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertAccountDetail(Map<String, dynamic> details) async {
    Database db = await database;
    return await db.insert('account_details', details,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateAccountDetail(
      int id, Map<String, dynamic> updatedData) async {
    Database db = await database;
    return await db.update('account_details', updatedData,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAccountDetail(int id) async {
    Database db = await database;
    return await db.delete('account_details', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> activateAccount(int id) async {
    if (id < 11) {
      return; // Prevent modifying system accounts
    }
    Database db = await database;
    await db.update(
      'accounts',
      {'active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Method to deactivate an account
  Future<void> deactivateAccount(int id) async {
    if (id < 11) {
      return; // Prevent modifying system accounts
    }
    Database db = await database;
    await db.update(
      'accounts',
      {'active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions(
    int? limit,
  ) async {
    final db = await database;

    // First pull the most recent `limit` rows (with offset) from account_details,
    // then join to accounts for the name and apply the id>2 + active filter.
    final sql = '''
    SELECT 
      d.id,
      d.date,
      d.description,
      d.amount,
      d.transaction_type,
      d.currency,
      a.name AS account_name
    FROM (
      SELECT 
        id,
        account_id,
        date,
        description,
        amount,
        transaction_type,
        currency
      FROM account_details
      ORDER BY date DESC, id DESC
    ) AS d
    JOIN accounts AS a
      ON d.account_id = a.id
    WHERE a.id > 2
      AND a.active = 1
    ORDER BY d.date DESC, d.id DESC
    LIMIT ?;
  ''';

    final rows = await db.rawQuery(sql, [limit]);
    return rows;
  }

  Future<List<Map<String, dynamic>>> getTransactions(
    int accountId, {
    int offset = 0,
    int limit = 30,
    String? searchQuery,
    String? transactionType,
    String? currency,
    DateTime? exactDate,
  }) async {
    return await _fetchTransactions(
      accountId,
      offset: offset,
      limit: limit,
      searchQuery: searchQuery,
      transactionType: transactionType,
      currency: currency,
      exactDate: exactDate,
    );
  }

  /// Fetch transactions with filters and running balance
  Future<List<Map<String, dynamic>>> _fetchTransactions(
    int? accountId, {
    int offset =
        0, // number of rows to skip (pageOffset = pageIndex * pageSize)
    int limit = 30, // pageSize
    String? searchQuery,
    String? transactionType,
    String? currency,
    DateTime? exactDate,
  }) async {
    final db = await database;

    // 1) Build your WHERE clause & base args exactly as before :contentReference[oaicite:0]{index=0}:contentReference[oaicite:1]{index=1}
    final List<String> where = [];
    final List<dynamic> args = [];
    if (accountId != null) {
      where.add('account_id = ?');
      args.add(accountId);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('LOWER(description) LIKE ?');
      args.add('%${searchQuery.toLowerCase()}%');
    }
    if (transactionType != null && transactionType.isNotEmpty) {
      where.add('transaction_type = ?');
      args.add(transactionType);
    }
    if (currency != null && currency.isNotEmpty) {
      where.add('currency = ?');
      args.add(currency);
    }
    if (exactDate != null) {
      where.add("DATE(date) = DATE(?)");
      args.add(exactDate.toIso8601String().substring(0, 10));
    }
    final whereClause = where.isEmpty ? '' : 'WHERE ' + where.join(' AND ');

    // 2) Figure out how many total rows match (for reverse-offset pagination)
    final countQ = 'SELECT COUNT(*) AS cnt FROM account_details $whereClause';
    final countRow = await db.rawQuery(countQ, List.from(args));
    final totalCount = (countRow.first['cnt'] as num).toInt();

    // 3) Compute the **ascending** OFFSET & LIMIT that give you the correct slice
    //    when you want newest-first pages of size `limit`, skipping `offset` rows.
    int pageSize = limit;
    int pageOffset = offset; // e.g. pageIndex * pageSize
    int ascOffset = totalCount - pageOffset - pageSize;
    int ascLimit = pageSize;
    if (ascOffset < 0) {
      // last page may be smaller
      ascLimit = pageSize + ascOffset;
      ascOffset = 0;
    }

    // 4) Seed your runningBalance from *all* rows before this slice
    final Map<String, double> runningBalance = {};
    if (ascOffset > 0) {
      final seedQ = '''
      SELECT currency,
             SUM(
               CASE WHEN transaction_type = 'credit' THEN amount
                    ELSE -amount
               END
             ) AS balance
      FROM (
        SELECT currency, transaction_type, amount
        FROM account_details
        $whereClause
        ORDER BY date, id
        LIMIT ?
        OFFSET 0
      )
      GROUP BY currency
    ''';
      final seedArgs = [...args, ascOffset];
      final seedRows = await db.rawQuery(seedQ, seedArgs);
      for (final row in seedRows) {
        runningBalance[row['currency'] as String] =
            (row['balance'] as num).toDouble();
      }
    }

    // 5) Grab the actual page slice (ascending), then apply deltas
    final pageQ = '''
    SELECT * FROM account_details
    $whereClause
    ORDER BY date, id
    LIMIT ? OFFSET ?
  ''';
    final pageArgs = [...args, ascLimit, ascOffset];
    final rows = await db.rawQuery(pageQ, pageArgs);

    final List<Map<String, dynamic>> results = [];
    for (final row in rows) {
      final curr = row['currency'] as String;
      final type = row['transaction_type'] as String;
      final amount = (row['amount'] as num).toDouble();
      final prev = runningBalance[curr] ?? 0.0;
      final newBal = prev + (type == 'credit' ? amount : -amount);
      runningBalance[curr] = newBal;

      results.add({
        'id': row['id'],
        'date': row['date'],
        'description': row['description'],
        'transaction_group': row['transaction_group'],
        'transaction_id': row['transaction_id'],
        'amount': amount,
        'transaction_type': type,
        'balance': newBal,
        'currency': curr,
      });
    }

    // 6) Reverse *this page* so it’s newest-first within the slice
    return results.reversed.toList();
  }

  Future<List<Map<String, dynamic>>> getTransactionsForPrint(
      int? accountId) async {
    final db = await database;

    final query = '''
      SELECT * FROM account_details
      WHERE account_id = ?
      ORDER BY date, id
    ''';

    final rows = await db.rawQuery(query, [accountId]);

    // Calculate running balance for each currency
    final Map<String, double> runningBalance = {};
    final List<Map<String, dynamic>> results = [];
    for (final row in rows) {
      final String curr = row['currency'] as String;
      final String type = row['transaction_type'] as String;
      final double amount = (row['amount'] as num).toDouble();
      double prevBalance = runningBalance[curr] ?? 0.0;
      double balance = prevBalance;
      if (type == 'credit') {
        balance += amount;
      } else if (type == 'debit') {
        balance -= amount;
      }
      runningBalance[curr] = balance;
      results.add({
        'id': row['id'],
        'date': row['date'],
        'description': row['description'],
        'transaction_group': row['transaction_group'],
        'transaction_id': row['transaction_id'],
        'amount': amount,
        'transaction_type': type,
        'balance': balance,
        'currency': curr,
      });
    }
    return results.toList();
  }

  Future<Map<String, int>> getAccountCounts() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT 
      COUNT(*) AS total,
      SUM(CASE WHEN active = 1 THEN 1 ELSE 0 END) AS activated,
      SUM(CASE WHEN active = 0 THEN 1 ELSE 0 END) AS deactivated
    FROM accounts
    WHERE id > 2;
  ''');

    if (result.isNotEmpty) {
      final row = result.first;
      return {
        'total_accounts': row['total'] as int,
        'activated_accounts': row['activated'] as int,
        'deactivated_accounts': row['deactivated'] as int,
      };
    } else {
      return {
        'total_accounts': 0,
        'activated_accounts': 0,
        'deactivated_accounts': 0,
      };
    }
  }

  /// Fetch accounts for printing, grouped with details per currency and transaction type
  /// Pass accountType = 'all' to include every active account.
  Future<List<Map<String, dynamic>>> getAccountsForPrint({
    required String accountType,
  }) async {
    final db = await database;

    // Build WHERE clause: always require active = 1,
    // and only filter by account_type if not 'all'.
    var where = 'a.active = 1';
    final args = <dynamic>[];
    if (accountType != 'all') {
      where += ' AND a.account_type = ?';
      args.add(accountType);
    }

    final sql = '''
    SELECT 
      a.id,
      a.name,
      a.phone,
      a.account_type,
      SUM(ad.amount) AS amount,
      ad.currency,
      ad.transaction_type
    FROM accounts AS a
    LEFT JOIN account_details AS ad
      ON a.id = ad.account_id
    WHERE $where
    GROUP BY a.id, ad.currency, ad.transaction_type
    ORDER BY a.id DESC;
  ''';

    final rows = await db.rawQuery(sql, args);

    // Re-assemble into one entry per account with its list of details
    final Map<int, Map<String, dynamic>> accountDataMap = {};
    for (final row in rows) {
      final id = row['id'] as int;
      accountDataMap.putIfAbsent(id, () {
        return {
          'id': id,
          'name': row['name'],
          'phone': row['phone'],
          'account_type': row['account_type'],
          'account_details': <Map<String, dynamic>>[],
        };
      });
      if (row['amount'] != null &&
          row['currency'] != null &&
          row['transaction_type'] != null) {
        accountDataMap[id]!['account_details'].add({
          'amount': row['amount'],
          'currency': row['currency'],
          'transaction_type': row['transaction_type'],
        });
      }
    }

    return accountDataMap.values.toList();
  }

  /// Returns all active accounts (id > 10) that have had **no** transactions
  /// in the past [days] days.
  Future<List<Map<String, dynamic>>> getAccountsNoTransactionsSince({
    int days = 30,
  }) async {
    final db = await database;
    // build the modifier for SQLite’s DATE function, e.g. "-30 days"
    final modifier = '-$days days';

    final sql = '''
    SELECT 
      a.id,
      a.name,
      a.account_type,
      a.active
    FROM accounts AS a
    WHERE 
      a.id > 10 
      AND a.active = 1
      AND NOT EXISTS (
        SELECT 1 
        FROM account_details AS ad
        WHERE 
          ad.account_id = a.id
          AND DATE(ad.date) >= DATE('now', ?)
      )
    ORDER BY a.id DESC;
  ''';

    // pass the modifier as the only argument
    final rows = await db.rawQuery(sql, [modifier]);
    return rows;
  }
}
