class Zone {
  final int? id;
  final int warehouseId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Zone({
    this.id,
    required this.warehouseId,
    required this.name,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'warehouse_id': warehouseId,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Zone.fromMap(Map<String, dynamic> map) {
    return Zone(
      id: map['id'] as int?,
      warehouseId: map['warehouse_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Zone copyWith({
    int? id,
    int? warehouseId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Zone(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 