import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class JournalDBHelper {
  static final JournalDBHelper _instance = JournalDBHelper._internal();

  factory JournalDBHelper() {
    return _instance;
  }

  JournalDBHelper._internal();

  Future<Database> get database async {
    return await DatabaseHelper().database;
  }

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

  Future<Map<String, dynamic>?> getJournalById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'journal',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

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
          'description': description ?? '',
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
              'description': description ?? '',
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
              'description': description ?? '',
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
              'description': description ?? '',
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
              'description': description ?? '',
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
              'description': description ?? '',
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
              'description': description ?? '',
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
              'description': description ?? '',
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
              'description': description ?? '',
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
              'description': description ?? '',
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
              'description': description ?? '',
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

Future<int> deleteJournal(int id) async {
  final db = await database;
  return await db.transaction((txn) async {
    // Delete from journal
    await txn.delete(
      'journal',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Delete from account_details
    return await txn.delete(
      'account_details',
      where: 'transaction_group = ? AND transaction_id = ?',
      whereArgs: ['journal', id],
    );
  });
}
}
