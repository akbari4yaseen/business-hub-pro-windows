import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/notification_model.dart';

/// Singleton class to handle SQLite operations for AppNotification.
class NotificationDB {
  NotificationDB._internal();
  static final NotificationDB _instance = NotificationDB._internal();
  factory NotificationDB() => _instance;

  Future<Database> get _db async => await DatabaseHelper().database;

  /// Fetch all notifications ordered by timestamp desc.
  Future<List<AppNotification>> fetchAll() async {
    final db = await _db;
    final rows = await db.query(
      'notifications',
      orderBy: 'timestamp DESC',
    );

    return rows.map((m) {
      final casted = Map<String, dynamic>.from(m);
      return AppNotification.fromMap(casted);
    }).toList();
  }

  /// Insert a new notification with conflict resolution.
  Future<void> insert(AppNotification notification) async {
    final db = await _db;
    await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update the "read" flag of a notification.
  Future<void> updateRead(String id, bool read) async {
    final db = await _db;
    await db.update(
      'notifications',
      {'read': read ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Count how many notifications are still unread.
  Future<int> countUnread() async {
    final db = await _db;
    // Use Sqflite helper to retrieve the count efficiently
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM notifications WHERE "read" = ?',
      [0],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete a notification by id.
  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Remove all notifications.
  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('notifications');
  }
}
