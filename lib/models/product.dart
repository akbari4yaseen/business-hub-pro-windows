class Product {
  final int? id;
  final String name;
  final String? description;
  final int? categoryId;
  final int? unitId;
  final double minimumStock;
  final double? maximumStock;
  final double? reorderPoint;
  final bool hasExpiryDate;
  final String? barcode;
  final String? sku;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    this.description,
    this.categoryId,
    this.unitId,
    this.minimumStock = 0,
    this.maximumStock,
    this.reorderPoint,
    this.hasExpiryDate = false,
    this.barcode,
    this.sku,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'description': description,
      'category_id': categoryId,
      'unit_id': unitId,
      'minimum_stock': minimumStock,
      'maximum_stock': maximumStock,
      'reorder_point': reorderPoint,
      'has_expiry_date': hasExpiryDate ? 1 : 0,
      'barcode': barcode,
      'sku': sku,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    // Only include id if it's not null
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      categoryId: map['category_id'] as int?,
      unitId: map['unit_id'] as int?,
      minimumStock: (map['minimum_stock'] as num?)?.toDouble() ?? 0,
      maximumStock: (map['maximum_stock'] as num?)?.toDouble(),
      reorderPoint: (map['reorder_point'] as num?)?.toDouble(),
      hasExpiryDate: (map['has_expiry_date'] as int?) == 1,
      barcode: map['barcode'] as String?,
      sku: map['sku'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    int? categoryId,
    int? unitId,
    double? minimumStock,
    double? maximumStock,
    double? reorderPoint,
    bool? hasExpiryDate,
    String? barcode,
    String? sku,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      unitId: unitId ?? this.unitId,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      hasExpiryDate: hasExpiryDate ?? this.hasExpiryDate,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
