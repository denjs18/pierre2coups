class Department {
  final String code;
  final String name;
  final String region;

  const Department({
    required this.code,
    required this.name,
    required this.region,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'region': region,
    };
  }

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      code: map['code'] as String,
      name: map['name'] as String,
      region: map['region'] as String,
    );
  }

  String get displayName => '$code - $name';
  String get fullDisplayName => '$code - $name ($region)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Department &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
