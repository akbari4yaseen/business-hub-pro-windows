class Product {
  final int id;
  final String name;
  final String? description;
  final int categoryId;
  final int unitId;
  final double minimumStock;
  final double? reorderPoint;
  final double? maximumStock;
  final int? baseUnitId;
  final bool hasExpiryDate;
  final String? barcode;
  final String? sku;
  final String? brand;
  final Map<String, dynamic>? customFields;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    required this.unitId,
    required this.minimumStock,
    this.reorderPoint,
    this.maximumStock,
    this.baseUnitId,
    required this.hasExpiryDate,
    this.barcode,
    this.sku,
    this.brand,
    this.customFields,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'unit_id': unitId,
      'minimum_stock': minimumStock,
      'reorder_point': reorderPoint,
      'maximum_stock': maximumStock,
      'base_unit_id': baseUnitId,
      'has_expiry_date': hasExpiryDate ? 1 : 0,
      'barcode': barcode,
      'sku': sku,
      'brand': brand,
      'custom_fields': customFields != null ? customFields.toString() : null,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      categoryId: map['category_id'] as int,
      unitId: map['unit_id'] as int,
      minimumStock: map['minimum_stock'] as double,
      reorderPoint: map['reorder_point'] as double?,
      maximumStock: map['maximum_stock'] as double?,
      baseUnitId: map['base_unit_id'] as int?,
      hasExpiryDate: map['has_expiry_date'] == 1,
      barcode: map['barcode'] as String?,
      sku: map['sku'] as String?,
      brand: map['brand'] as String?,
      customFields: map['custom_fields'] != null 
          ? Map<String, dynamic>.from(map['custom_fields'] as Map)
          : null,
      isActive: map['is_active'] == 1,
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
    double? reorderPoint,
    double? maximumStock,
    int? baseUnitId,
    bool? hasExpiryDate,
    String? barcode,
    String? sku,
    String? brand,
    Map<String, dynamic>? customFields,
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
      reorderPoint: reorderPoint ?? this.reorderPoint,
      maximumStock: maximumStock ?? this.maximumStock,
      baseUnitId: baseUnitId ?? this.baseUnitId,
      hasExpiryDate: hasExpiryDate ?? this.hasExpiryDate,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      brand: brand ?? this.brand,
      customFields: customFields ?? this.customFields,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 