enum MovementType { stockIn, stockOut, transfer, adjustment }

class StockMovement {
  final int? id;
  final int productId;
  final int? sourceWarehouseId; // null for stock in
  final int? destinationWarehouseId; // null for stock out
  final double quantity;
  final MovementType type;
  final String? reference; // Reference number or document
  final String? notes;
  final DateTime? expiryDate;
  final DateTime? date;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Additional fields from joins
  final String? productName;
  final String? unitName;
  final String? sourceWarehouseName;
  final String? destinationWarehouseName;

  StockMovement({
    this.id,
    required this.productId,
    this.sourceWarehouseId,
    this.destinationWarehouseId,
    required this.quantity,
    required this.type,
    this.reference,
    this.notes,
    this.date,
    this.expiryDate,
    DateTime? createdAt,
    this.updatedAt,
    this.productName,
    this.unitName,
    this.sourceWarehouseName,
    this.destinationWarehouseName,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      sourceWarehouseId: map['source_warehouse_id'] as int?,
      destinationWarehouseId: map['destination_warehouse_id'] as int?,
      quantity: (map['quantity'] as num).toDouble(),
      type: MovementType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MovementType.stockIn,
      ),
      reference: map['reference'] as String?,
      notes: map['notes'] as String?,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      productName: map['product_name'] as String?,
      unitName: map['unit_name'] as String?,
      sourceWarehouseName: map['source_warehouse_name'] as String?,
      destinationWarehouseName: map['destination_warehouse_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'source_warehouse_id': sourceWarehouseId,
      'destination_warehouse_id': destinationWarehouseId,
      'quantity': quantity,
      'type': type.toString().split('.').last,
      'reference': reference,
      'notes': notes,
      'expiry_date': expiryDate?.toIso8601String(),
      'date': date?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
