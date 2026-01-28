class Weapon {
  final String id;
  final String name;
  final String manufacturer;
  final String model;
  final String caliber;
  final String category;
  final int usageCount;
  final DateTime createdAt;
  final String? createdBy;

  Weapon({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.model,
    required this.caliber,
    required this.category,
    this.usageCount = 0,
    required this.createdAt,
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'manufacturer': manufacturer,
      'model': model,
      'caliber': caliber,
      'category': category,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Weapon.fromMap(Map<String, dynamic> map) {
    return Weapon(
      id: map['id'] as String,
      name: map['name'] as String,
      manufacturer: map['manufacturer'] as String,
      model: map['model'] as String,
      caliber: map['caliber'] as String,
      category: map['category'] as String,
      usageCount: map['usage_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'manufacturer': manufacturer,
      'model': model,
      'caliber': caliber,
      'category': category,
      'usageCount': usageCount,
      'createdAt': createdAt,
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  factory Weapon.fromFirestore(Map<String, dynamic> data, String id) {
    return Weapon(
      id: id,
      name: data['name'] as String,
      manufacturer: data['manufacturer'] as String,
      model: data['model'] as String,
      caliber: data['caliber'] as String,
      category: data['category'] as String,
      usageCount: data['usageCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      createdBy: data['createdBy'] as String?,
    );
  }

  Weapon copyWith({
    String? id,
    String? name,
    String? manufacturer,
    String? model,
    String? caliber,
    String? category,
    int? usageCount,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Weapon(
      id: id ?? this.id,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      caliber: caliber ?? this.caliber,
      category: category ?? this.category,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  String get displayName => '$manufacturer $model ($caliber)';
  String get fullDisplayName => '$name - $manufacturer $model - $caliber';
  String get displayDetails => '$manufacturer • $model • $caliber';
}
