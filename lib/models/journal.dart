class Journal {
  final int id;
  final String description;
  final DateTime date;
  final double amount;
  final String currency;
  final String transactionType;
  final String accountName;
  final String trackName;

  Journal({
    required this.id,
    required this.description,
    required this.date,
    required this.amount,
    required this.currency,
    required this.transactionType,
    required this.accountName,
    required this.trackName,
  });

  factory Journal.fromMap(Map<String, dynamic> m) => Journal(
        id: m['id'],
        description: m['description'] ?? '',
        date: DateTime.parse(m['date']),
        amount: m['amount'],
        currency: m['currency'],
        transactionType: m['transaction_type'],
        accountName: m['account_name'],
        trackName: m['track_name'],
      );
}
