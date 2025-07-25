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
  final double? userEnteredTotal;
  final bool isPreSale;

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
    this.userEnteredTotal,
    this.isPreSale = false,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);

  double get calculatedTotal => subtotal;

  double get total => userEnteredTotal ?? calculatedTotal;

  double get balance => total - (paidAmount ?? 0.0);

  bool get isPaid => status == InvoiceStatus.paid;

  bool get isOverdue =>
      status != InvoiceStatus.paid &&
      status != InvoiceStatus.cancelled &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  bool get hasManualAdjustment => userEnteredTotal != null;

  double? get adjustmentAmount =>
      userEnteredTotal != null ? userEnteredTotal! - calculatedTotal : null;

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
      'user_entered_total': userEnteredTotal,
      'is_pre_sale': isPreSale,
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
      userEnteredTotal: map['user_entered_total'] as double?,
      isPreSale: map['is_pre_sale'] as bool? ?? false,
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
    double? userEnteredTotal,
    bool? isPreSale,
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
      userEnteredTotal: userEnteredTotal ?? this.userEnteredTotal,
      isPreSale: isPreSale ?? this.isPreSale,
    );
  }
}

class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int productId;
  final double quantity;
  final double unitPrice;
  final int? unitId;
  final String? description;
  final int? warehouseId;

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.unitId,
    this.description,
    this.warehouseId,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'unit_id': unitId,
      'description': description,
      'warehouse_id': warehouseId,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as double,
      unitPrice: map['unit_price'] as double,
      unitId: map['unit_id'] as int?,
      description: map['description'] as String?,
      warehouseId: map['warehouse_id'] as int?,
    );
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    double? quantity,
    double? unitPrice,
    int? unitId,
    String? description,
    int? warehouseId,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unitId: unitId ?? this.unitId,
      description: description ?? this.description,
      warehouseId: warehouseId ?? this.warehouseId,
    );
  }
}
