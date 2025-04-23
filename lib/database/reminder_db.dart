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

  // Table name
  static const String tableReminders = 'reminders';

  // Insert a reminder
  Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    return await db.insert(tableReminders, reminder.toMap());
  }

  // Fetch all reminders, ordered by scheduledTime
  Future<List<Reminder>> getReminders() async {
    final db = await database;
    final maps = await db.query(
      tableReminders,
      orderBy: 'scheduledTime ASC',
    );
    return maps.map((m) => Reminder.fromMap(m)).toList();
  }

  // Update an existing reminder
  Future<int> updateReminder(Reminder reminder) async {
    final db = await database;
    return await db.update(
      tableReminders,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  // Delete a reminder by id
  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete(
      tableReminders,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
