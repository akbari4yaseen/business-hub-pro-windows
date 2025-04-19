enum TransactionType { credit, debit }

class Journal {
  final int id;
  final String? description;
  final DateTime date;
  final double amount;
  final String currency;
  final TransactionType transactionType;
  final String accountName;
  final String trackName;

  Journal({
    required this.id,
    this.description,
    required this.date,
    required this.amount,
    required this.currency,
    required this.transactionType,
    required this.accountName,
    required this.trackName,
  });

  factory Journal.fromMap(Map<String, dynamic> m) {
    return Journal(
      id: m['id'] as int,
      description: m['description'] as String?,
      date: DateTime.parse(m['date'] as String),
      amount: (m['amount'] as num).toDouble(),
      currency: m['currency'] as String,
      transactionType: m['transaction_type'] == 'credit'
          ? TransactionType.credit
          : TransactionType.debit,
      accountName: m['account_name'] as String,
      trackName: m['track_name'] as String,
    );
  }
}
