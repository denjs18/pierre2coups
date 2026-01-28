class Club {
  final String id;
  final String name;
  final String city;
  final String department;
  final int memberCount;
  final DateTime createdAt;
  final String? createdBy;

  Club({
    required this.id,
    required this.name,
    required this.city,
    required this.department,
    this.memberCount = 0,
    required this.createdAt,
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'department': department,
      'member_count': memberCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['id'] as String,
      name: map['name'] as String,
      city: map['city'] as String,
      department: map['department'] as String,
      memberCount: map['member_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'city': city,
      'department': department,
      'memberCount': memberCount,
      'createdAt': createdAt,
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  factory Club.fromFirestore(Map<String, dynamic> data, String id) {
    return Club(
      id: id,
      name: data['name'] as String,
      city: data['city'] as String,
      department: data['department'] as String,
      memberCount: data['memberCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      createdBy: data['createdBy'] as String?,
    );
  }

  Club copyWith({
    String? id,
    String? name,
    String? city,
    String? department,
    int? memberCount,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      department: department ?? this.department,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  String get displayName => '$name - $city';
}
