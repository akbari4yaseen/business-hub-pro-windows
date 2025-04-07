import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class CompanyInfo {
  final String? name;
  final String? whatsApp;
  final String? phone;
  final String? email;
  final String? address;

  CompanyInfo({
    this.name,
    this.whatsApp,
    this.phone,
    this.email,
    this.address,
  });

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      name: map['name'],
      whatsApp: map['whats_app'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'whats_app': whatsApp,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  CompanyInfo copyWith({
    String? name,
    String? whatsApp,
    String? phone,
    String? email,
    String? address,
  }) {
    return CompanyInfo(
      name: name ?? this.name,
      whatsApp: whatsApp ?? this.whatsApp,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }
}

class InfoProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  CompanyInfo _info = CompanyInfo(); // default empty

  CompanyInfo get info => _info;

  /// Load info from local database
  Future<void> loadInfo() async {
    final data = await _dbHelper.loadCompanyInfo();
    if (data != null) {
      _info = CompanyInfo.fromMap(data);
      notifyListeners();
    }
  }

  /// Update both local DB and provider
  Future<bool> updateInfo(CompanyInfo updatedInfo) async {
    bool success = await _dbHelper.updateCompanyInfo(
      name: updatedInfo.name ?? '',
      email: updatedInfo.email,
      whatsApp: updatedInfo.whatsApp,
      phone: updatedInfo.phone,
      address: updatedInfo.address,
      logo: null, // Optional: handle logo if you need
    );

    if (success) {
      _info = updatedInfo;
      notifyListeners();
    }

    return success;
  }
}
