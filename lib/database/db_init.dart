import 'package:sqflite/sqflite.dart';

class DbInit {
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username VARCHAR(32) UNIQUE,
        password VARCHAR(32) NOT NULL,
        is_logged_in BOOLEAN DEFAULT FALSE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS companyInfo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(128) NOT NULL,
        email VARCHAR(64),
        whats_app VARCHAR(16),
        phone VARCHAR(16),
        address VARCHAR(255),
        logo TEXT
      )
    ''');

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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS account_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date DATETIME NOT NULL,
        account_id INTEGER NOT NULL,
        amount DECIMAL(15,2) NOT NULL,
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
        amount DECIMAL(15,2) NOT NULL,
        currency VARCHAR(3) NOT NULL,
        transaction_type VARCHAR(8) NOT NULL,
        description VARCHAR(256)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> seedDefaults(Database db) async {
    await db.insert(
      'user',
      {'id': 1, 'username': 'Admin', 'password': '8833560', 'is_logged_in': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.insert(
      'companyInfo',
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
        'id': 9,
        'name': 'profit',
        'account_type': 'system',
        'phone': '',
        'address': ''
      },
      {
        'id': 10,
        'name': 'loss',
        'account_type': 'system',
        'phone': '',
        'address': ''
      },
    ]);
  }
}

Future<void> insertAccounts(
    Database db, List<Map<String, dynamic>> accounts) async {
  final batch = db.batch();
  for (var acct in accounts) {
    batch.insert('accounts', acct, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  await batch.commit(noResult: true);
}
