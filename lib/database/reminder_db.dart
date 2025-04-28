import 'package:sqflite/sqflite.dart';
import '../models/reminder.dart';
import 'database_helper.dart';

/// Singleton database access for reminders
class ReminderDB {
  ReminderDB._internal();
  static final ReminderDB _instance = ReminderDB._internal();
  factory ReminderDB() => _instance;

  /// Provides the underlying SQLite database
  Future<Database> get _db async => await DatabaseHelper().database;

  /// Inserts a new reminder and returns its generated id
  Future<int> insertReminder(Reminder r) async {
    final db = await _db;
    return await db.insert(
      'reminders',
      r.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all reminders ordered by scheduled time ascending
  Future<List<Reminder>> getReminders() async {
    final db = await _db;
    final maps = await db.query(
      'reminders',
      orderBy: 'scheduled_at ASC',
    );
    return maps.map((m) => Reminder.fromMap(m)).toList();
  }

  /// Updates an existing reminder by id
  Future<int> updateReminder(Reminder r) async {
    final db = await _db;
    return await db.update(
      'reminders',
      r.toMap(),
      where: 'id = ?',
      whereArgs: [r.id],
    );
  }

  /// Deletes a reminder by id
  Future<int> deleteReminder(int id) async {
    final db = await _db;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
