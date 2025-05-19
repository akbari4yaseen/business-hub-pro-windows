enum InvoiceStatus { draft, finalized, partiallyPaid, paid, cancelled }

class Invoice {
  final int? id;
  final int accountId;
  final String invoiceNumber;
  final DateTime date;
  final String currency;
  final String? notes;
  final InvoiceStatus status;
  final List<InvoiceItem> items;
  final double? paidAmount;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Invoice({
    this.id,
    required this.accountId,
    required this.invoiceNumber,
    required this.date,
    required this.currency,
    this.notes,
    this.status = InvoiceStatus.draft,
    required this.items,
    this.paidAmount = 0.0,
    this.dueDate,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double get total =>
      subtotal; // Can be extended to include tax, discounts etc.

  double get balance => total - (paidAmount ?? 0.0);

  bool get isPaid => status == InvoiceStatus.paid;

  bool get isOverdue =>
      status != InvoiceStatus.paid &&
      status != InvoiceStatus.cancelled &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'invoice_number': invoiceNumber,
      'date': date.toIso8601String(),
      'currency': currency,
      'notes': notes,
      'status': status.toString().split('.').last,
      'paid_amount': paidAmount,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      invoiceNumber: map['invoice_number'] as String,
      date: DateTime.parse(map['date'] as String),
      currency: map['currency'] as String,
      notes: map['notes'] as String?,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      items: [], // Items need to be loaded separately
      paidAmount: map['paid_amount'] as double?,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Invoice copyWith({
    int? id,
    int? accountId,
    String? invoiceNumber,
    DateTime? date,
    String? currency,
    String? notes,
    InvoiceStatus? status,
    List<InvoiceItem>? items,
    double? paidAmount,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      items: items ?? this.items,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int productId;
  final double quantity;
  final double unitPrice;
  final String? description;

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.description,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'description': description,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as double,
      unitPrice: map['unit_price'] as double,
      description: map['description'] as String?,
    );
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    double? quantity,
    double? unitPrice,
    String? description,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      description: description ?? this.description,
    );
  }
}
