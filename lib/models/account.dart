import 'dart:convert';

class Account {
  final int? id;
  final String name;
  final String accountType;
  final String? phone;
  final String? address;
  final bool active;
  final DateTime createdAt;

  Account({
    this.id,
    required this.name,
    required this.accountType,
    this.phone,
    this.address,
    this.active = true,
    required this.createdAt,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      accountType: map['account_type'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      active: map['active'] == 1 || map['active'] == true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'account_type': accountType,
      'phone': phone,
      'address': address,
      'active': active ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Account.fromJson(String source) => Account.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());
}