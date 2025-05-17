class Bin {
  final int? id;
  final int zoneId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bin({
    this.id,
    required this.zoneId,
    required this.name,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Bin.fromMap(Map<String, dynamic> map) {
    return Bin(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Bin copyWith({
    int? id,
    int? zoneId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bin(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 