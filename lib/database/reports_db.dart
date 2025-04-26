import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class ReportsDBHelper {
  static final ReportsDBHelper _instance = ReportsDBHelper._internal();

  factory ReportsDBHelper() {
    return _instance;
  }

  ReportsDBHelper._internal();

  Future<Database> get database async {
    return await DatabaseHelper().database;
  }

  /// Returns a list of maps: each contains account_type and count, excluding 'system' types.
  Future<List<Map<String, dynamic>>> getAccountTypeCounts() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT account_type, COUNT(*) as count
      FROM accounts
      WHERE account_type != 'system'
      GROUP BY account_type
    ''');
    return result;
  }

  Future<List<Map<String, dynamic>>> getSystemAccounts() async {
    final db = await database;
    final rows = await db.rawQuery('''
    SELECT
      a.id,
      a.name,
      IFNULL(
        GROUP_CONCAT(
          ad.amount || '::' || ad.currency || '::' || ad.transaction_type,
          '||'
        ),
        ''
      ) AS details_blob
    FROM accounts a
    LEFT JOIN account_details ad
      ON a.id = ad.account_id
    WHERE a.id <> 2 AND a.account_type = ?
    GROUP BY a.id
  ''', ['system']);

    return rows.map((r) {
      final blob = r['details_blob'] as String;
      final details = blob.isEmpty
          ? <Map<String, dynamic>>[]
          : blob.split('||').map((segment) {
              final parts = segment.split('::');
              return {
                'amount': double.parse(parts[0]),
                'currency': parts[1],
                'transaction_type': parts[2],
              };
            }).toList();

      return {
        'id': r['id'],
        'name': r['name'],
        'details': details,
      };
    }).toList();
  }

  /// Returns daily net change (credits minus debits) per date for the given filters.
  Future<List<Map<String, dynamic>>> getDailyBalances({
    required String accountType,
    required String currency,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final sql = '''
      SELECT 
        DATE(ad.date) AS date,
        SUM(
          CASE 
            WHEN ad.transaction_type = 'credit' THEN ad.amount
            WHEN ad.transaction_type = 'debit' THEN -ad.amount
            ELSE 0
          END
        ) AS net
      FROM account_details AS ad
      JOIN accounts AS a
        ON ad.account_id = a.id
      WHERE a.account_type = ?
        AND a.active = 1
        AND ad.currency = ?
        AND ad.date BETWEEN ? AND ?
      GROUP BY DATE(ad.date)
      ORDER BY DATE(ad.date);
    ''';

    final rows = await db.rawQuery(sql, [
      accountType,
      currency,
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);

    return rows;
  }
}
