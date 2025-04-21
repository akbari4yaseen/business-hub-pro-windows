import 'package:sqflite/sqflite.dart';

class CompanyInfoDao {
  final Database db;
  CompanyInfoDao(this.db);

  Future<bool> updateInfo({
    required String name,
    String? email,
    String? whatsApp,
    String? phone,
    String? address,
    String? logo,
  }) async {
    final rows = await db.update(
      'companyInfo',
      {
        'name': name,
        'email': email,
        'whats_app': whatsApp,
        'phone': phone,
        'address': address,
        'logo': logo,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
    return rows > 0;
  }

  Future<Map<String, dynamic>?> loadInfo() async {
    final result = await db.query(
      'companyInfo',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }
}
