import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class AccountDBHelper {
  // Pagination for active accounts
  Future<List<Map<String, dynamic>>> getActiveAccountsPage({
    int offset = 0,
    int limit = 30,
    String? searchQuery,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    where.add('accounts.id <> 2 AND accounts.active = 1');
    if (searchQuery?.isNotEmpty ?? false) {
      where.add(
          '(LOWER(accounts.name) LIKE ? OR LOWER(accounts.address) LIKE ? OR LOWER(accounts.phone) LIKE ?)');
      final q = '%${searchQuery!.toLowerCase()}%';
      args.addAll([q, q, q]);
    }
    final whereClause = where.isEmpty ? '' : 'WHERE ' + where.join(' AND ');
    final sql = '''
      SELECT 
        accounts.id, 
        accounts.name, 
        accounts.phone, 
        accounts.account_type, 
        accounts.address, 
        accounts.active, 
        accounts.created_at,
        SUM(account_details.amount) AS amount, 
        account_details.currency, 
        account_details.transaction_type 
      FROM accounts 
      LEFT JOIN account_details ON accounts.id = account_details.account_id 
      $whereClause
      GROUP BY accounts.id, account_details.currency, account_details.transaction_type 
      ORDER BY accounts.id DESC
      LIMIT ? OFFSET ?;
    ''';
    args.addAll([limit, offset]);
    final rows = await db.rawQuery(sql, args);
    Map<int, Map<String, dynamic>> accountDataMap = {};
    for (var row in rows) {
      int accountId = row['id'] as int;
      accountDataMap.putIfAbsent(accountId, () {
        return {
          'id': row['id'],
          'name': row['name'],
          'phone': row['phone'],
          'account_type': row['account_type'],
          'address': row['address'],
          'active': row['active'],
          'created_at': row['created_at'],
          'account_details': [],
        };
      });
      if (row['amount'] != null &&
          row['currency'] != null &&
          row['transaction_type'] != null) {
        accountDataMap[accountId]!['account_details'].add({
          'amount': row['amount'],
          'currency': row['currency'],
          'transaction_type': row['transaction_type'],
        });
      }
    }
    return accountDataMap.values.toList();
  }

  // Pagination for deactivated accounts
  Future<List<Map<String, dynamic>>> getDeactivatedAccountsPage({
    int offset = 0,
    int limit = 30,
    String? searchQuery,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    where.add('accounts.active = 0');
    if (searchQuery?.isNotEmpty ?? false) {
      where.add(
          '(LOWER(accounts.name) LIKE ? OR LOWER(accounts.address) LIKE ? OR LOWER(accounts.phone) LIKE ?)');
      final q = '%${searchQuery!.toLowerCase()}%';
      args.addAll([q, q, q]);
    }
    final whereClause = where.isEmpty ? '' : 'WHERE ' + where.join(' AND ');
    final sql = '''
      SELECT 
        accounts.id, 
        accounts.name, 
        accounts.phone, 
        accounts.account_type, 
        accounts.address, 
        accounts.active, 
        accounts.created_at,
        SUM(account_details.amount) AS amount, 
        account_details.currency, 
        account_details.transaction_type 
      FROM accounts 
      LEFT JOIN account_details ON accounts.id = account_details.account_id 
      $whereClause
      GROUP BY accounts.id, account_details.currency, account_details.transaction_type 
      ORDER BY accounts.id DESC
      LIMIT ? OFFSET ?;
    ''';
    args.addAll([limit, offset]);
    final rows = await db.rawQuery(sql, args);
    Map<int, Map<String, dynamic>> accountDataMap = {};
    for (var row in rows) {
      int accountId = row['id'] as int;
      accountDataMap.putIfAbsent(accountId, () {
        return {
          'id': row['id'],
          'name': row['name'],
          'phone': row['phone'],
          'account_type': row['account_type'],
          'address': row['address'],
          'active': row['active'],
          'created_at': row['created_at'],
          'account_details': [],
        };
      });
      if (row['amount'] != null &&
          row['currency'] != null &&
          row['transaction_type'] != null) {
        accountDataMap[accountId]!['account_details'].add({
          'amount': row['amount'],
          'currency': row['currency'],
          'transaction_type': row['transaction_type'],
        });
      }
    }
    return accountDataMap.values.toList();
  }

  static final AccountDBHelper _instance = AccountDBHelper._internal();

  factory AccountDBHelper() {
    return _instance;
  }

  AccountDBHelper._internal();

  Future<Database> get database async {
    return await DatabaseHelper().database;
  }

  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    Database db = await database;
    return await db.query('accounts', orderBy: 'created_at DESC');
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

  Future<List<Map<String, dynamic>>> getActiveAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT 
        accounts.id, 
        accounts.name, 
        accounts.phone, 
        accounts.account_type, 
        accounts.address, 
        accounts.active, 
        accounts.created_at,
        SUM(account_details.amount) AS amount, 
        account_details.currency, 
        account_details.transaction_type 
      FROM accounts 
      LEFT JOIN account_details ON accounts.id = account_details.account_id 
      WHERE accounts.id <> 2 AND accounts.active = 1 
      GROUP BY accounts.id, account_details.currency, account_details.transaction_type 
      ORDER BY accounts.id DESC;
    ''');

    Map<int, Map<String, dynamic>> accountDataMap = {};

    for (var row in rows) {
      int accountId = row['id'] as int;
      accountDataMap.putIfAbsent(accountId, () {
        return {
          'id': row['id'],
          'name': row['name'],
          'phone': row['phone'],
          'account_type': row['account_type'],
          'address': row['address'],
          'active': row['active'],
          'created_at': row['created_at'],
          'account_details': [],
        };
      });

      if (row['amount'] != null &&
          row['currency'] != null &&
          row['transaction_type'] != null) {
        accountDataMap[accountId]!['account_details'].add({
          'amount': row['amount'],
          'currency': row['currency'],
          'transaction_type': row['transaction_type'],
        });
      }
    }

    return accountDataMap.values.toList();
  }

  Future<List<Map<String, dynamic>>> getDeactivatedAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT 
        accounts.id, 
        accounts.name, 
        accounts.phone, 
        accounts.account_type, 
        accounts.address, 
        accounts.active, 
        accounts.created_at,
        SUM(account_details.amount) AS amount, 
        account_details.currency, 
        account_details.transaction_type 
      FROM accounts 
      LEFT JOIN account_details ON accounts.id = account_details.account_id 
      WHERE accounts.active = 0 
      GROUP BY accounts.id, account_details.currency, account_details.transaction_type 
      ORDER BY accounts.id DESC;
    ''');

    Map<int, Map<String, dynamic>> accountDataMap = {};

    for (var row in rows) {
      int accountId = row['id'] as int;
      accountDataMap.putIfAbsent(accountId, () {
        return {
          'id': row['id'],
          'name': row['name'],
          'phone': row['phone'],
          'account_type': row['account_type'],
          'address': row['address'],
          'active': row['active'],
          'created_at': row['created_at'],
          'account_details': [],
        };
      });

      if (row['amount'] != null &&
          row['currency'] != null &&
          row['transaction_type'] != null) {
        accountDataMap[accountId]!['account_details'].add({
          'amount': row['amount'],
          'currency': row['currency'],
          'transaction_type': row['transaction_type'],
        });
      }
    }

    return accountDataMap.values.toList();
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

  Future<List<Map<String, dynamic>>> getRecentTransactions(int limit) async {
    Database db = await database;

    String query = '''
    SELECT 
      account_details.id, 
      account_details.date, 
      account_details.description, 
      account_details.amount, 
      account_details.transaction_type, 
      account_details.currency,
      accounts.name AS account_name
    FROM account_details
    JOIN accounts ON account_details.account_id = accounts.id
    WHERE accounts.id > 2
    ORDER BY account_details.date DESC, account_details.id DESC
    LIMIT ?;
  ''';

    List<Map<String, dynamic>> rows = await db.rawQuery(query, [limit]);

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

  /// Fetch transactions with filters and running balance (descending order)
  Future<List<Map<String, dynamic>>> _fetchTransactions(
    int? accountId, {
    int offset = 0,
    int limit = 30,
    String? searchQuery,
    String? transactionType,
    String? currency,
    DateTime? exactDate,
  }) async {
    final db = await database;
    final List<String> where = [];
    final List<dynamic> args = [];
    if (accountId != null) {
      where.add('account_id = ?');
      args.add(accountId);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('(LOWER(description) LIKE ?)');
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
      // Accept both 'YYYY-MM-DD' and full ISO string
      where.add("DATE(date) = DATE(?)");
      args.add(exactDate.toIso8601String().substring(0, 10));
    }
    final whereClause = where.isEmpty ? '' : 'WHERE ' + where.join(' AND ');

    final query = '''
      SELECT * FROM account_details
      $whereClause
      ORDER BY date DESC, id DESC
      LIMIT ? OFFSET ?
    ''';
    args.addAll([limit, offset]);

    final rows = await db.rawQuery(query, args);

    // Calculate running balance for each currency (descending order)
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
    return results;
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
}
