class Product {
  final int? id;
  final String name;
  final String description;
  final int categoryId;
  final int unitId;
  final double minimumStock;
  final double reorderPoint;
  final double maximumStock;
  final bool hasExpiryDate;
  final String? barcode;
  final String? sku;
  final String? brand;
  final Map<String, dynamic>? customFields;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.unitId,
    required this.minimumStock,
    this.reorderPoint = 0,
    this.maximumStock = double.infinity,
    this.hasExpiryDate = false,
    this.barcode,
    this.sku,
    this.brand,
    this.customFields,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

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
      'has_expiry_date': hasExpiryDate ? 1 : 0,
      'barcode': barcode,
      'sku': sku,
      'brand': brand,
      'custom_fields': customFields != null ? customFieldsToString(customFields!) : null,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      categoryId: map['category_id'],
      unitId: map['unit_id'],
      minimumStock: map['minimum_stock'],
      reorderPoint: map['reorder_point'] ?? 0,
      maximumStock: map['maximum_stock'] ?? double.infinity,
      hasExpiryDate: map['has_expiry_date'] == 1,
      barcode: map['barcode'],
      sku: map['sku'],
      brand: map['brand'],
      customFields: map['custom_fields'] != null ? stringToCustomFields(map['custom_fields']) : null,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  static String customFieldsToString(Map<String, dynamic> fields) {
    return fields.toString();
  }

  static Map<String, dynamic> stringToCustomFields(String str) {
    final map = <String, dynamic>{};
    str = str.substring(1, str.length - 1);
    for (var pair in str.split(',')) {
      var parts = pair.split(':');
      if (parts.length == 2) {
        var key = parts[0].trim();
        var value = parts[1].trim();
        map[key] = value;
      }
    }
    return map;
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