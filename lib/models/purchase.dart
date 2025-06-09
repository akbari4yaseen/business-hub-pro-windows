class Purchase {
  final int id;
  final int supplierId;
  final String? invoiceNumber;
  final String referenceNumber;
  final String supplierName;
  final DateTime date;
  final String currency;
  final String? notes;
  final double totalAmount;
  final double total;
  final double paidAmount;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Purchase({
    required this.id,
    required this.supplierId,
    this.invoiceNumber,
    required this.referenceNumber,
    required this.supplierName,
    required this.date,
    required this.currency,
    this.notes,
    this.totalAmount = 0,
    this.total = 0,
    this.paidAmount = 0,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'invoice_number': invoiceNumber,
      'reference_number': referenceNumber,
      'supplier_name': supplierName,
      'date': date.toIso8601String(),
      'currency': currency,
      'notes': notes,
      'total_amount': totalAmount,
      'total': total,
      'paid_amount': paidAmount,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as int,
      supplierId: map['supplier_id'] as int,
      invoiceNumber: map['invoice_number'] as String?,
      referenceNumber: map['reference_number'] as String,
      supplierName: map['supplier_name'] as String,
      date: DateTime.parse(map['date'] as String),
      currency: map['currency'] as String,
      notes: map['notes'] as String?,
      totalAmount: map['total_amount'] as double,
      total: map['total'] as double,
      paidAmount: map['paid_amount'] as double,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
} 