class Unit {
  final int? id;
  final String name;
  final String? symbol;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Unit({
    this.id,
    required this.name,
    this.symbol,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as int?,
      name: map['name'] as String,
      symbol: map['symbol'] as String?,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Unit copyWith({
    int? id,
    String? name,
    String? symbol,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UnitConversion {
  final int? id;
  final int fromUnitId;
  final int toUnitId;
  final double factor;

  UnitConversion({
    this.id,
    required this.fromUnitId,
    required this.toUnitId,
    required this.factor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_unit_id': fromUnitId,
      'to_unit_id': toUnitId,
      'factor': factor,
    };
  }

  factory UnitConversion.fromMap(Map<String, dynamic> map) {
    return UnitConversion(
      id: map['id'] as int?,
      fromUnitId: map['from_unit_id'] as int,
      toUnitId: map['to_unit_id'] as int,
      factor: (map['factor'] as num).toDouble(),
    );
  }
} 