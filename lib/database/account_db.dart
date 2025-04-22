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

  Future<List<Map<String, dynamic>>> getTransactions(int accountId) async {
    return await _fetchTransactions(accountId);
  }

// Private method to fetch transactions with balance calculations
  Future<List<Map<String, dynamic>>> _fetchTransactions(int? accountId) async {
    Database db = await database;

    String query = '''
    SELECT * FROM account_details
    ${accountId != null ? "WHERE account_id = ?" : ""}
    ORDER BY date ASC, id ASC
  
  ''';

    List<dynamic> args = [];
    if (accountId != null) args.add(accountId);

    List<Map<String, dynamic>> rows = await db.rawQuery(query, args);

    Map<String, double> balanceMap = {};
    List<Map<String, dynamic>> transactionDetails = [];

    for (var row in rows) {
      double creditAmount = 0.0;
      double debitAmount = 0.0;

      if (row['transaction_type'] == 'credit') {
        creditAmount = (row['amount'] as num).toDouble();
      } else if (row['transaction_type'] == 'debit') {
        debitAmount = (row['amount'] as num).toDouble();
      }

      double balance =
          (balanceMap[row['currency']] ?? 0.0) + creditAmount - debitAmount;
      balanceMap[row['currency']] = balance;

      transactionDetails.add({
        'id': row['id'],
        'date': row['date'],
        'description': row['description'],
        'transaction_group': row['transaction_group'],
        'transaction_id': row['transaction_id'],
        'amount': (row['amount'] as num).toDouble(),
        'transaction_type': row['transaction_type'],
        'balance': balance,
        'currency': row['currency'],
      });
    }

    return transactionDetails.reversed
        .toList(); // Show latest transactions first
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
