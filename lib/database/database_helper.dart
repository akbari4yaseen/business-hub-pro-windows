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
