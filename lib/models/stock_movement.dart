enum MovementType {
  stockIn,
  stockOut,
  transfer,
  adjustment
}

class StockMovement {
  final int? id;
  final int productId;
  final int? sourceBinId;  // null for stock in
  final int? destinationBinId;  // null for stock out
  final double quantity;
  final MovementType type;
  final String? reference;  // Reference number or document
  final String? notes;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  StockMovement({
    this.id,
    required this.productId,
    this.sourceBinId,
    this.destinationBinId,
    required this.quantity,
    required this.type,
    this.reference,
    this.notes,
    this.expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'source_bin_id': sourceBinId,
      'destination_bin_id': destinationBinId,
      'quantity': quantity,
      'type': type.toString().split('.').last,
      'reference': reference,
      'notes': notes,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'],
      productId: map['product_id'],
      sourceBinId: map['source_bin_id'],
      destinationBinId: map['destination_bin_id'],
      quantity: map['quantity'],
      type: MovementType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      reference: map['reference'],
      notes: map['notes'],
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
} 