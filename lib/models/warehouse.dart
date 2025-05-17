class Warehouse {
  final int? id;
  final String name;
  final String address;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Warehouse({
    this.id,
    required this.name,
    required this.address,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
} 