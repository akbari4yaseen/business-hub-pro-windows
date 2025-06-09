class PurchaseItem {
  final int id;
  final int purchaseId;
  final int productId;
  final String productName;
  final double quantity;
  final int unitId;
  final String unitName;
  final double unitPrice;
  final double price;
  final DateTime? expiryDate;
  final int warehouseId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitId,
    required this.unitName,
    required this.unitPrice,
    required this.price,
    this.expiryDate,
    required this.warehouseId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_id': unitId,
      'unit_name': unitName,
      'unit_price': unitPrice,
      'price': price,
      'expiry_date': expiryDate?.toIso8601String(),
      'warehouse_id': warehouseId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] as int,
      purchaseId: map['purchase_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      quantity: map['quantity'] as double,
      unitId: map['unit_id'] as int,
      unitName: map['unit_name'] as String,
      unitPrice: map['unit_price'] as double,
      price: map['price'] as double,
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date'] as String) : null,
      warehouseId: map['warehouse_id'] as int,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
} 