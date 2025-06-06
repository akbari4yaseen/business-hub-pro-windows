class Exchange {
  final int? id;
  final int fromAccountId;
  final int toAccountId;
  final String fromCurrency;
  final String toCurrency;
  final String operator;
  final double amount;
  final double rate;
  final double resultAmount;
  final double? expectedRate;
  final double profitLoss;
  final String transactionType;
  final String? description;
  final String date;

  Exchange({
    this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.fromCurrency,
    required this.toCurrency,
    required this.operator,
    required this.amount,
    required this.rate,
    required this.resultAmount,
    this.expectedRate,
    this.profitLoss = 0,
    required this.transactionType,
    this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'from_currency': fromCurrency,
      'to_currency': toCurrency,
      'operator': operator,
      'amount': amount,
      'rate': rate,
      'result_amount': resultAmount,
      'expected_rate': expectedRate,
      'profit_loss': profitLoss,
      'transaction_type': transactionType,
      'description': description,
      'date': date,
    };
  }

  factory Exchange.fromMap(Map<String, dynamic> map) {
    return Exchange(
      id: map['id'],
      fromAccountId: map['from_account_id'],
      toAccountId: map['to_account_id'],
      fromCurrency: map['from_currency'],
      toCurrency: map['to_currency'],
      operator: map['operator'],
      amount: map['amount'],
      rate: map['rate'],
      resultAmount: map['result_amount'],
      expectedRate: map['expected_rate'],
      profitLoss: map['profit_loss'],
      transactionType: map['transaction_type'],
      description: map['description'],
      date: map['date'],
    );
  }
}
