import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/company_info_dao.dart';
import '../models/company_info.dart';

/// A ChangeNotifier that loads and updates company information.
class InfoProvider extends ChangeNotifier {
  CompanyInfo _info = CompanyInfo();
  CompanyInfo get info => _info;

  InfoProvider() {
    loadInfo();
  }

  /// Load the company info from the local database.
  Future<void> loadInfo() async {
    final db = await DatabaseHelper().database;
    final dao = CompanyInfoDao(db);
    final data = await dao.loadInfo();

    if (data != null) {
      _info = CompanyInfo.fromMap(data);
      notifyListeners();
    }
  }

  /// Update both local DB and provider state.
  Future<bool> updateInfo(CompanyInfo updatedInfo) async {
    final db = await DatabaseHelper().database;
    final dao = CompanyInfoDao(db);

    bool success = await dao.updateInfo(
      name: updatedInfo.name ?? '',
      email: updatedInfo.email,
      whatsApp: updatedInfo.whatsApp,
      phone: updatedInfo.phone,
      address: updatedInfo.address,
      logo: updatedInfo.logo,
    );

    if (success) {
      _info = updatedInfo;
      notifyListeners();
    }

    return success;
  }
}
