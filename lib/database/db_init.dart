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
        description TEXT,
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
      CREATE TABLE IF NOT EXISTS reminders (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        title            VARCHAR(128)    NOT NULL,
        description      TEXT    DEFAULT '',
        scheduled_at     INTEGER NOT NULL,               -- ms since UNIX epoch
        is_repeating     INTEGER NOT NULL DEFAULT 0,      -- 0 = false, 1 = true
        repeat_interval  INTEGER,                         -- interval in milliseconds
        created_at       INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
        updated_at       INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications(
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT UNIQUE NOT NULL,
        message TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        read INTEGER NOT NULL,
        routeName TEXT,      
        payload TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL
      )
    ''');

    // Inventory Management Tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        symbol TEXT,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        category_id INTEGER NOT NULL,
        unit_id INTEGER NOT NULL,
        minimum_stock REAL NOT NULL,
        reorder_point REAL DEFAULT 0,
        maximum_stock REAL,
        has_expiry_date INTEGER NOT NULL,
        barcode TEXT,
        sku TEXT,
        brand TEXT,
        custom_fields TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (unit_id) REFERENCES units (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        source_warehouse_id INTEGER,
        destination_warehouse_id INTEGER,
        quantity REAL NOT NULL,
        type TEXT NOT NULL,
        reference TEXT,
        notes TEXT,
        expiry_date TEXT,
        date DATETIME NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id),
        FOREIGN KEY (source_warehouse_id) REFERENCES warehouses (id),
        FOREIGN KEY (destination_warehouse_id) REFERENCES warehouses (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS exchanges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_account_id INTEGER NOT NULL,
        to_account_id INTEGER NOT NULL,
        from_currency VARCHAR(3) NOT NULL,
        to_currency VARCHAR(3) NOT NULL,
        operator VARCHAR(1) NOT NULL,
        amount REAL NOT NULL,
        rate REAL NOT NULL,
        result_amount REAL NOT NULL,
        expected_rate REAL,
        profit_loss REAL DEFAULT 0,
        transaction_type TEXT NOT NULL, -- e.g. 'exchange', 'cash_in', 'cash_out', 'cash_swap'
        description TEXT,
        date DATETIME NOT NULL,
        FOREIGN KEY (from_account_id) REFERENCES accounts(id) ON DELETE CASCADE,
        FOREIGN KEY (to_account_id) REFERENCES accounts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS current_stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        warehouse_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        expiry_date TEXT,
        FOREIGN KEY (product_id) REFERENCES products (id),
        FOREIGN KEY (warehouse_id) REFERENCES warehouses (id),
        UNIQUE(product_id, warehouse_id, expiry_date)
      )
    ''');

    // Invoice Management Tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        invoice_number TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        currency TEXT NOT NULL,
        notes TEXT,
        status TEXT NOT NULL,
        paid_amount REAL DEFAULT 0.0,
        due_date TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
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
