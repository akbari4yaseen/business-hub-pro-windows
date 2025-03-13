import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'BusinessHub.db');
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username VARCHAR(32) UNIQUE,
        password VARCHAR(32) NOT NULL,
        is_logged_in BOOLEAN DEFAULT FALSE
      )
    ''');

    await db.insert(
      'user',
      {'id': 1, 'username': 'Admin', 'password': '8833560', 'is_logged_in': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(128) NOT NULL,
        email VARCHAR(64),
        whats_app VARCHAR(16),
        phone VARCHAR(16),
        address VARCHAR(255),
        logo TEXT
      )
    ''');

    await db.insert(
      'info',
      {
        'id': 1,
        'name': 'Default Business',
        'email': 'business@example.com',
        'whats_app': '',
        'phone': '',
        'address': 'Default Address',
        'logo': ''
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(32) UNIQUE,
        account_type VARCHAR(16) NOT NULL,
        phone VARCHAR(13),
        address VARCHAR(128),
        active BOOLEAN DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Insert Default Accounts Using Batch
    await insertAccounts(db, [
      {
        'id': 1,
        'name': 'treasure',
        'account_type': 'system',
        'phone': '',
        'address': ''
      },
      {
        'id': 2,
        'name': 'noTreasure',
        'account_type': 'system',
        'phone': '',
        'address': ''
      },
      {
        'id': 3,
        'name': 'asset',
        'account_type': 'system',
        'phone': '',
        'address': ''
      },
      {
        'id': 4,
        'name': 'profit',
        'account_type': 'system',
        'phone': '',
        'address': ''
      },
      {
        'id': 5,
        'name': 'loss',
        'account_type': 'system',
        'phone': '',
        'address': ''
      },
      {
        'id': 10,
        'name': 'expenses',
        'account_type': 'system',
        'phone': '',
        'address': ''
      }
    ]);

    await db.execute('''
      CREATE TABLE IF NOT EXISTS account_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date DATETIME NOT NULL,
        account_id INTEGER NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        currency VARCHAR(3) NOT NULL,
        transaction_type VARCHAR(8) NOT NULL,
        description VARCHAR(256),
        transaction_id INTEGER NOT NULL,
        transaction_group VARCHAR(16) NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id)
          ON DELETE CASCADE
          ON UPDATE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date DATETIME NOT NULL,
        account_id INTEGER NOT NULL,
        track_id INTEGER NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        currency VARCHAR(3) NOT NULL,
        transaction_type VARCHAR(8) NOT NULL,
        description VARCHAR(256)
      )
    ''');
  }

  Future<int> updateUserPassword(String newPassword) async {
    Database db = await database;
    return await db.update(
      'user',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<bool> validateUser(String password) async {
    Database db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'user',
      where: 'username = ? AND password = ?',
      whereArgs: ['Admin', password],
    );

    if (result.isNotEmpty) {
      await db.update(
        'user',
        {'is_logged_in': 1},
        where: 'id = ?',
        whereArgs: [1],
      );
      return true;
    } else {
      return false;
    }
  }

  Future<int> logoutUser() async {
    Database db = await database;
    return await db.update(
      'user',
      {'is_logged_in': 0},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<bool> isUserLoggedIn() async {
    Database db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'user',
      where: 'id = ? AND is_logged_in = ?',
      whereArgs: [1, 1],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    Database db = await database;
    return await db.query('accounts', orderBy: 'created_at DESC');
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
    Database db = await database;
    return await db.query('accounts', where: 'active = ?', whereArgs: [0]);
  }

  Future<void> insertAccount(Map<String, dynamic> account) async {
    Database db = await database;
    await db.insert('accounts', account,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAccount(int id, Map<String, dynamic> updatedData) async {
    Database db = await database;
    await db.update('accounts', updatedData, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAccount(int id) async {
    Database db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions(int limit) async {
    Database db = await database;
    return await db.query('account_details',
        orderBy: 'date DESC', limit: limit);
  }

// Fetch all journal entries (ordered by date)
  Future<List<Map<String, dynamic>>> getJournals() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT 
      j.*, 
      acc_account.name AS account_name, 
      acc_track.name AS track_name 
    FROM 
      journal j 
    INNER JOIN 
      accounts acc_account 
    ON 
      j.account_id = acc_account.id 
    INNER JOIN 
      accounts acc_track 
    ON 
      j.track_id = acc_track.id 
    ORDER BY 
      j.id DESC;
  ''');
    return result;
  }

// Fetch a single journal entry by ID
  Future<Map<String, dynamic>?> getJournalById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'journal',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

// Insert a new journal entry
  Future<int> insertJournal({
    required DateTime date,
    required int accountId,
    required int trackId,
    required double amount,
    required String currency,
    required String transactionType,
    String? description,
  }) async {
    final db = await database;
    return await db.insert(
      'journal',
      {
        'date': date.toIso8601String(),
        'account_id': accountId,
        'track_id': trackId,
        'amount': amount,
        'currency': currency,
        'transaction_type': transactionType,
        'description': description ?? '',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// Update an existing journal entry
  Future<int> updateJournal({
    required int id,
    required DateTime date,
    required int accountId,
    required int trackId,
    required double amount,
    required String currency,
    required String transactionType,
    String? description,
  }) async {
    final db = await database;
    return await db.update(
      'journal',
      {
        'date': date.toIso8601String(),
        'account_id': accountId,
        'track_id': trackId,
        'amount': amount,
        'currency': currency,
        'transaction_type': transactionType,
        'description': description ?? '',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

// Delete a journal entry by ID
  Future<int> deleteJournal(int id) async {
    final db = await database;
    return await db.delete(
      'journal',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

/// Insert Multiple Accounts Using Batch**
Future<void> insertAccounts(
    Database db, List<Map<String, dynamic>> accounts) async {
  final batch = db.batch();
  for (var account in accounts) {
    batch.insert('accounts', account,
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  await batch.commit(noResult: true);
}
