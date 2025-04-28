import 'package:sqflite/sqflite.dart';
import '../models/reminder.dart';
import 'database_helper.dart';

class ReminderDB {
  // Singleton instance
  static final ReminderDB _instance = ReminderDB._internal();
  factory ReminderDB() => _instance;
  ReminderDB._internal();

  // Get the database from DatabaseHelper
  Future<Database> get database async {
    return await DatabaseHelper().database;
  }

  Future<int> insertReminder(Reminder r) async {
    final db = await database;
    return await db.insert('reminders', r.toMap());
  }

  Future<List<Reminder>> getReminders() async {
    final db = await database;
    final maps = await db.query(
      'reminders',
      orderBy: 'scheduled_at ASC',
    );
    return maps.map((m) => Reminder.fromMap(m)).toList();
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
