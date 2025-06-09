class ProductUnit {
  final int id;
  final int productId;
  final int unitId;
  final bool isBaseUnit;
  final double conversionRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductUnit({
    required this.id,
    required this.productId,
    required this.unitId,
    required this.isBaseUnit,
    required this.conversionRate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'unit_id': unitId,
      'is_base_unit': isBaseUnit ? 1 : 0,
      'conversion_rate': conversionRate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProductUnit.fromMap(Map<String, dynamic> map) {
    return ProductUnit(
      id: map['id'] as int,
      productId: map['product_id'] as int,
      unitId: map['unit_id'] as int,
      isBaseUnit: map['is_base_unit'] == 1,
      conversionRate: map['conversion_rate'] as double,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
} 