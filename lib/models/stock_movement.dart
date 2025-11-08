enum MovementType { stockIn, stockOut, transfer }

class StockMovement {
  final int id;
  final int productId;
  final int? sourceWarehouseId;
  final int? destinationWarehouseId;
  final double quantity;
  final MovementType type;
  final String? reference;
  final String? notes;
  final DateTime? expiryDate;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from joins
  final String? productName;
  final String? unitName;
  final String? sourceWarehouseName;
  final String? destinationWarehouseName;

  StockMovement({
    required this.id,
    required this.productId,
    this.sourceWarehouseId,
    this.destinationWarehouseId,
    required this.quantity,
    required this.type,
    this.reference,
    this.notes,
    this.expiryDate,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.productName,
    this.unitName,
    this.sourceWarehouseName,
    this.destinationWarehouseName,
  });

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
      'expiry_date': expiryDate?.millisecondsSinceEpoch,
      'date': date.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;

      // int (timestamp)
      if (value is int) {
        if (value.toString().length == 10) {
          // secondsSinceEpoch
          return DateTime.fromMillisecondsSinceEpoch(value * 1000);
        }
        return DateTime.fromMillisecondsSinceEpoch(value);
      }

      // string (ISO or int as string)
      if (value is String) {
        final intVal = int.tryParse(value);
        if (intVal != null) {
          if (value.length == 10) {
            return DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
          }
          return DateTime.fromMillisecondsSinceEpoch(intVal);
        }
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }

      return null;
    }

    return StockMovement(
      id: map['id'] as int,
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
      expiryDate: parseDate(map['expiry_date']),
      date: parseDate(map['date']) ?? DateTime.now(),
      createdAt: parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: parseDate(map['updated_at']) ?? DateTime.now(),
      productName: map['product_name'] as String?,
      unitName: map['unit_name'] as String?,
      sourceWarehouseName: map['source_warehouse_name'] as String?,
      destinationWarehouseName: map['destination_warehouse_name'] as String?,
    );
  }
}
