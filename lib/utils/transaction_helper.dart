Map<String, Map<String, dynamic>> aggregateTransactions(
  List<Map<String, dynamic>>? transactions,
) {
  if (transactions == null) return {};

  // First pass: sum credits & debits per currency
  final sums = <String, Map<String, double>>{};
  for (var tx in transactions) {
    final currency = tx['currency'] as String;
    final amount = (tx['amount'] as num).toDouble();
    final type = tx['transaction_type'] as String;

    sums.update(
      currency,
      (existing) {
        existing[type] = (existing[type] ?? 0) + amount;
        return existing;
      },
      ifAbsent: () => {
        'credit': type == 'credit' ? amount : 0.0,
        'debit': type == 'debit' ? amount : 0.0,
      },
    );
  }

  // Second pass: build the final structure with balances
  return sums.map((currency, summary) {
    final credit = summary['credit']!;
    final debit = summary['debit']!;
    return MapEntry(currency, {
      'currency': currency,
      'summary': {
        'credit': credit,
        'debit': debit,
        'balance': credit - debit,
      },
    });
  });
}
