class Purchase {
  final int? id;
  final int supplierId;
  final String? invoiceNumber;
  final DateTime date;
  final String currency;
  final String? notes;
  final double totalAmount;
  final double paidAmount;
  final double additionalCost;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Purchase({
    this.id,
    required this.supplierId,
    this.invoiceNumber,
    required this.date,
    required this.currency,
    this.notes,
    required this.totalAmount,
    required this.paidAmount,
    this.additionalCost = 0,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'supplier_id': supplierId,
      'invoice_number': invoiceNumber,
      'date': date.toIso8601String(),
      'currency': currency,
      'notes': notes,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'additional_cost': additionalCost,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    // Only include id if it's not null
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as int?,
      supplierId: map['supplier_id'] as int,
      invoiceNumber: map['invoice_number'] as String?,
      date: DateTime.parse(map['date'] as String),
      currency: map['currency'] as String,
      notes: map['notes'] as String?,
      totalAmount: map['total_amount'] as double,
      paidAmount: map['paid_amount'] as double,
      additionalCost: map['additional_cost'] != null ? (map['additional_cost'] as num).toDouble() : 0,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
