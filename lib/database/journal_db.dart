import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class JournalDBHelper {
  // Singleton boilerplate
  static final JournalDBHelper _instance = JournalDBHelper._internal();
  factory JournalDBHelper() => _instance;
  JournalDBHelper._internal();

  Future<Database> get _db async => await DatabaseHelper().database;

  Future<List<Map<String, dynamic>>> getJournals({
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    final args = <dynamic>[];

    // Build the inner SELECT on journal
    var inner = StringBuffer('SELECT * FROM journal ORDER BY id DESC');
    if (limit != null) {
      inner.write(' LIMIT ?');
      args.add(limit);
      if (offset != null) {
        inner.write(' OFFSET ?');
        args.add(offset);
      }
    } else if (offset != null) {
      // SQLite requires LIMIT if you want OFFSET alone
      inner.write(' LIMIT -1 OFFSET ?');
      args.add(offset);
    }

    // Now join account names to that paginated journal set
    final sql = '''
    SELECT
      j2.*,
      acc_account.name AS account_name,
      acc_track.name   AS track_name
    FROM (
      ${inner.toString()}
    ) AS j2
    JOIN accounts acc_account ON j2.account_id = acc_account.id
    JOIN accounts acc_track   ON j2.track_id   = acc_track.id
    ORDER BY j2.id DESC;
  ''';

    return db.rawQuery(sql, args);
  }

  Future<Map<String, dynamic>?> getJournalById(int id) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT
        j.*,
        acc_account.name AS account_name,
        acc_track.name   AS track_name
      FROM journal j
      JOIN accounts acc_account ON j.account_id = acc_account.id
      JOIN accounts acc_track   ON j.track_id   = acc_track.id
      WHERE j.id = ?
    ''', [id]);
    return result.isEmpty ? null : result.first;
  }

  Future<int> insertJournal({
    required DateTime date,
    required int accountId,
    required int trackId,
    required double amount,
    required String currency,
    required String transactionType,
    String description = '',
  }) async {
    final db = await _db;
    return await db.transaction((txn) async {
      int journalId = await txn.insert(
        'journal',
        {
          'date': date.toIso8601String(),
          'account_id': accountId,
          'track_id': trackId,
          'amount': amount,
          'currency': currency,
          'transaction_type': transactionType,
          'description': description,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (transactionType.toLowerCase() == 'debit') {
        if (trackId == 2 || accountId == 1) {
          await txn.insert(
            'account_details',
            {
              'account_id': accountId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': journalId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else if (trackId == 1) {
          await txn.insert(
            'account_details',
            {
              'account_id': accountId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': journalId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          await txn.insert(
            'account_details',
            {
              'account_id': trackId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': journalId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          await txn.insert(
            'account_details',
            {
              'account_id': accountId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': journalId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          await txn.insert(
            'account_details',
            {
              'account_id': trackId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': "credit",
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': journalId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } else {
        if (trackId == 2 || accountId == 1) {
          await txn.insert(
            'account_details',
            {
              'account_id': accountId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': journalId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else if (trackId == 1) {
          await txn.insert(
            'account_details',
            {
              'account_id': accountId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': journalId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          await txn.insert(
            'account_details',
            {
              'account_id': trackId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': journalId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          await txn.insert(
            'account_details',
            {
              'account_id': accountId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': 'credit',
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': journalId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          await txn.insert(
            'account_details',
            {
              'account_id': trackId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': "debit",
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': journalId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      return journalId;
    });
  }

  Future<int> updateJournal({
    required int id,
    required DateTime date,
    required int accountId,
    required int trackId,
    required double amount,
    required String currency,
    required String transactionType,
    String description = '',
  }) async {
    final db = await _db;
    return await db.transaction((txn) async {
      // Delete old account_details for this journal
      await txn.delete(
        'account_details',
        where: 'transaction_group = ? AND transaction_id = ?',
        whereArgs: ['journal', id],
      );

      // Update the journal entry
      await txn.update(
        'journal',
        {
          'date': date.toIso8601String(),
          'account_id': accountId,
          'track_id': trackId,
          'amount': amount,
          'currency': currency,
          'transaction_type': transactionType,
          'description': description,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // Re-insert updated account_details
      if (transactionType.toLowerCase() == 'debit') {
        if (trackId == 2 || accountId == 1) {
          await txn.insert(
            'account_details',
            {
              'account_id': accountId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': id,
            },
          );
        } else if (trackId == 1) {
          await txn.insert(
            'account_details',
            {
              'account_id': accountId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': id,
            },
          );

          await txn.insert(
            'account_details',
            {
              'account_id': trackId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': id,
            },
          );
        } else {
          await txn.insert(
            'account_details',
            {
              'account_id': accountId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': id,
            },
          );

          await txn.insert(
            'account_details',
            {
              'account_id': trackId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': "credit",
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': id,
            },
          );
        }
      } else {
        if (trackId == 2 || accountId == 1) {
          await txn.insert(
            'account_details',
            {
              'account_id': accountId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': id,
            },
          );
        } else if (trackId == 1) {
          await txn.insert(
            'account_details',
            {
              'account_id': accountId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': id,
            },
          );

          await txn.insert(
            'account_details',
            {
              'account_id': trackId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': transactionType,
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': id,
            },
          );
        } else {
          await txn.insert(
            'account_details',
            {
              'account_id': accountId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': 'credit',
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': id,
            },
          );

          await txn.insert(
            'account_details',
            {
              'account_id': trackId,
              'date': date.toIso8601String(),
              'amount': amount,
              'currency': currency,
              'transaction_type': "debit",
              'description': description,
              'transaction_group': 'journal',
              'transaction_id': id,
            },
          );
        }
      }

      return id;
    });
  }

  Future<void> deleteJournal(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'journal',
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'account_details',
        where: 'transaction_group = ? AND transaction_id = ?',
        whereArgs: ['journal', id],
      );
    });
  }
}

// Optional pagination/search extension
extension JournalPaging on JournalDBHelper {
  Future<List<Map<String, dynamic>>> getJournalsPage({
    int offset = 0,
    int limit = 30,
    String? searchQuery,
    String? transactionType,
    String? currency,
    DateTime? exactDate,
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <dynamic>[];

    // Build filters
    if (searchQuery?.isNotEmpty ?? false) {
      where.add('(LOWER(j.description) LIKE ? '
          'OR LOWER(acc_account.name) LIKE ? '
          'OR LOWER(acc_track.name) LIKE ?)');
      final q = '%${searchQuery!.toLowerCase()}%';
      args.addAll([q, q, q]);
    }
    if (transactionType != null && transactionType != 'all') {
      where.add('j.transaction_type = ?');
      args.add(transactionType);
    }
    if (currency != null && currency != 'all') {
      where.add('j.currency = ?');
      args.add(currency);
    }
    if (exactDate != null) {
      where.add('DATE(j.date) = DATE(?)');
      args.add(exactDate.toIso8601String());
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ' + where.join(' AND ');

    // Inner subquery: filter+order+page the journal rows (with joins for filtering by names)
    final innerSql = '''
      SELECT
        j.*
      FROM journal j
      JOIN accounts acc_account ON j.account_id = acc_account.id
      JOIN accounts acc_track   ON j.track_id   = acc_track.id
      $whereClause
      ORDER BY j.id DESC
      LIMIT ? OFFSET ?
    ''';
    args.addAll([limit, offset]);

    // Outer query: attach account_name & track_name, preserve ordering
    final sql = '''
      SELECT
        j2.*,
        acc_account.name AS account_name,
        acc_track.name   AS track_name
      FROM (
        $innerSql
      ) AS j2
      JOIN accounts acc_account ON j2.account_id = acc_account.id
      JOIN accounts acc_track   ON j2.track_id   = acc_track.id
      ORDER BY j2.id DESC
    ''';

    return await db.rawQuery(sql, args);
  }

  Future<List<Map<String, dynamic>>> searchJournals({
    required String query,
    String? transactionType,
    String? currency,
    DateTime? exactDate,
  }) async {
    return getJournalsPage(
      searchQuery: query,
      transactionType: transactionType,
      currency: currency,
      exactDate: exactDate,
    );
  }
}
