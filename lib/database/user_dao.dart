import 'package:sqflite/sqflite.dart';

class UserDao {
  final Database db;
  UserDao(this.db);

  Future<bool> updatePassword(String current, String newPass) async {
    final rows = await db.rawUpdate(
      'UPDATE user SET password = ? WHERE id = ? AND password = ?',
      [newPass, 1, current],
    );
    return rows > 0;
  }

  Future<bool> validate(String password) async {
    final result = await db.query(
      'user',
      where: 'username = ? AND password = ?',
      whereArgs: ['Admin', password],
    );
    if (result.isNotEmpty) {
      await db.update('user', {'is_logged_in': 1},
          where: 'id = ?', whereArgs: [1]);
      return true;
    }
    return false;
  }

  Future<int> logout() async {
    return await db.update('user', {'is_logged_in': 0},
        where: 'id = ?', whereArgs: [1]);
  }

  Future<bool> isLoggedIn() async {
    final result = await db
        .query('user', where: 'id = ? AND is_logged_in = ?', whereArgs: [1, 1]);
    return result.isNotEmpty;
  }
}
