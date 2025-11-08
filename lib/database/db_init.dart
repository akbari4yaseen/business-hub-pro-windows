import 'package:sqflite/sqflite.dart';

class DbInit {
  static Future<void> createTables(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS user (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE,
      password TEXT NOT NULL,
      is_logged_in INTEGER DEFAULT 0 -- 0 = false, 1 = true
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS companyInfo (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT,
      whats_app TEXT,
      phone TEXT,
      address TEXT,
      logo TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE,
      account_type TEXT NOT NULL,
      phone TEXT,
      address TEXT,
      active INTEGER DEFAULT 1,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS account_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date INTEGER NOT NULL,
      account_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      currency TEXT NOT NULL,
      transaction_type TEXT NOT NULL,
      description TEXT,
      transaction_id INTEGER NOT NULL,
      transaction_group TEXT NOT NULL,
      FOREIGN KEY (account_id) REFERENCES accounts(id)
        ON DELETE CASCADE ON UPDATE CASCADE
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS journal (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date INTEGER NOT NULL,
      account_id INTEGER NOT NULL,
      track_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      currency TEXT NOT NULL,
      transaction_type TEXT NOT NULL,
      description TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS reminders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT DEFAULT '',
      scheduled_at INTEGER NOT NULL,          -- ms since UNIX epoch
      is_repeating INTEGER NOT NULL DEFAULT 0,
      repeat_interval INTEGER,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
      updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS notifications (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      title TEXT UNIQUE NOT NULL,
      message TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      read INTEGER NOT NULL DEFAULT 0,
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

    await db.execute('''
    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      description TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS units (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      symbol TEXT UNIQUE,
      description TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS unit_conversions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      from_unit_id INTEGER NOT NULL,
      to_unit_id INTEGER NOT NULL,
      factor REAL NOT NULL,
      FOREIGN KEY (from_unit_id) REFERENCES units(id),
      FOREIGN KEY (to_unit_id) REFERENCES units(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      category_id INTEGER NOT NULL,
      base_unit_id INTEGER NOT NULL,
      minimum_stock REAL NOT NULL,
      reorder_point REAL DEFAULT 0,
      maximum_stock REAL,
      has_expiry_date INTEGER NOT NULL DEFAULT 0,
      barcode TEXT,
      sku TEXT UNIQUE,
      brand TEXT,
      custom_fields TEXT,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (category_id) REFERENCES categories(id),
      FOREIGN KEY (base_unit_id) REFERENCES units(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS warehouses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      address TEXT NOT NULL,
      description TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS stock_movements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      source_warehouse_id INTEGER,
      destination_warehouse_id INTEGER,
      quantity REAL NOT NULL,
      type TEXT NOT NULL CHECK (type IN ('stockIn','stockOut','transfer')),
      reference TEXT,
      notes TEXT,
      expiry_date INTEGER,
      date INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (product_id) REFERENCES products(id),
      FOREIGN KEY (source_warehouse_id) REFERENCES warehouses(id),
      FOREIGN KEY (destination_warehouse_id) REFERENCES warehouses(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS exchanges (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      from_account_id INTEGER NOT NULL,
      to_account_id INTEGER NOT NULL,
      from_account_name TEXT,
      to_account_name TEXT,
      from_currency TEXT NOT NULL,
      to_currency TEXT NOT NULL,
      operator TEXT NOT NULL,
      amount REAL NOT NULL,
      rate REAL NOT NULL,
      result_amount REAL NOT NULL,
      expected_rate REAL,
      profit_loss REAL DEFAULT 0,
      transaction_type TEXT NOT NULL,
      description TEXT,
      date INTEGER NOT NULL,
      FOREIGN KEY (from_account_id) REFERENCES accounts(id) ON DELETE CASCADE,
      FOREIGN KEY (to_account_id) REFERENCES accounts(id) ON DELETE CASCADE
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS current_stock (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      warehouse_id INTEGER NOT NULL,
      date INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
      type TEXT NOT NULL CHECK (type IN ('stockIn','stockOut')),
      quantity REAL NOT NULL CHECK (quantity >= 0),
      source_type TEXT NOT NULL CHECK (source_type IN ('invoice','stock_movement')),
      source_id INTEGER NOT NULL,
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
      FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE
      )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_id INTEGER NOT NULL,
      invoice_number TEXT NOT NULL UNIQUE,
      date INTEGER NOT NULL,
      currency TEXT NOT NULL,
      notes TEXT,
      status TEXT NOT NULL,
      paid_amount REAL DEFAULT 0.0,
      due_date INTEGER,
      user_entered_total REAL,
      is_pre_sale INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
      updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
      FOREIGN KEY (account_id) REFERENCES accounts(id)
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
      unit_id INTEGER,
      warehouse_id INTEGER NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
      updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
      FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
      FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS purchases (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      supplier_id INTEGER NOT NULL,
      invoice_number TEXT,
      date INTEGER NOT NULL,
      currency TEXT NOT NULL,
      notes TEXT,
      total_amount REAL DEFAULT 0,
      paid_amount REAL DEFAULT 0,
      additional_cost REAL DEFAULT 0,
      due_date INTEGER,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
      updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
      FOREIGN KEY (supplier_id) REFERENCES accounts(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS purchase_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      purchase_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity REAL NOT NULL,
      unit_id INTEGER NOT NULL,
      unit_price REAL NOT NULL,
      expiry_date INTEGER,
      notes TEXT,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
      updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
      FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products(id),
      FOREIGN KEY (unit_id) REFERENCES units(id)
    )
  ''');

    await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_stock_movements_date ON stock_movements(date)
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_stock_movements_product ON stock_movements(product_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_stock_movements_source ON stock_movements(source_warehouse_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_stock_movements_dest ON stock_movements(destination_warehouse_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoice_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_invoice_items_product ON invoice_items(product_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_invoice_items_warehouse ON invoice_items(warehouse_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase ON purchase_items(purchase_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_purchase_items_product ON purchase_items(product_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_purchase_items_unit ON purchase_items(unit_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_current_stock_product_wh ON current_stock(product_id, warehouse_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_current_stock_source ON current_stock(source_type, source_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_account_details_account ON account_details(account_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_account_details_txn ON account_details(transaction_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_accounts_name ON accounts(name)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_journal_account ON journal(account_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_journal_track ON journal(track_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_journal_date ON journal(date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_invoices_account ON invoices(account_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_purchases_supplier ON purchases(supplier_id)');
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
