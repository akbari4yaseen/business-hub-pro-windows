// models/journal.dart
import 'dart:convert';

class Journal {
  final int? id;
  final DateTime date;
  final int accountId;
  final int trackId;
  final double amount;
  final String currency;
  final String transactionType;
  final String? description;

  Journal({
    this.id,
    required this.date,
    required this.accountId,
    required this.trackId,
    required this.amount,
    required this.currency,
    required this.transactionType,
    this.description,
  });

  factory Journal.fromMap(Map<String, dynamic> map) {
    return Journal(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      accountId: map['account_id'] as int,
      trackId: map['track_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      transactionType: map['transaction_type'] as String,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'account_id': accountId,
      'track_id': trackId,
      'amount': amount,
      'currency': currency,
      'transaction_type': transactionType,
      'description': description,
    };
  }

  factory Journal.fromJson(String source) => Journal.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());
}