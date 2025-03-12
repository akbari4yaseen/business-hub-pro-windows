Map<String, Map<String, dynamic>> aggregateTransactions(List<Map<String, dynamic>>? transactions) {
  Map<String, Map<String, dynamic>> result = {};

  transactions?.forEach((transaction) {
    String currency = transaction['currency'];
    double amount = (transaction['amount'] as num).toDouble();
    String transactionType = transaction['transaction_type'];

    // Initialize the object for the current currency if not already present
    result[currency] ??= {'credit': 0.0, 'debit': 0.0};

    // Update the credit or debit amount based on the transaction type
    if (transactionType == 'credit') {
      result[currency]!['credit'] += amount;
    } else if (transactionType == 'debit') {
      result[currency]!['debit'] += amount;
    }
  });

  // Format the final output
  return result.map((currency, summary) {
    return MapEntry(currency, {
      'currency': currency,
      'summary': {
        'credit': summary['credit'],
        'debit': summary['debit'],
        'balance': summary['credit'] - summary['debit'],
      },
    });
  });
}
