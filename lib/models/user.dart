class AppUser {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? clubId;
  final String? clubName;
  final String department;
  final DateTime createdAt;
  final DateTime? lastSync;

  AppUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.clubId,
    this.clubName,
    required this.department,
    required this.createdAt,
    this.lastSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'club_id': clubId,
      'club_name': clubName,
      'department': department,
      'created_at': createdAt.toIso8601String(),
      'last_sync': lastSync?.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      clubId: map['club_id'] as String?,
      clubName: map['club_name'] as String?,
      department: map['department'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastSync: map['last_sync'] != null
          ? DateTime.parse(map['last_sync'] as String)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'club': clubId,
      'department': department,
      'createdAt': createdAt,
      'lastSync': lastSync,
    };
  }

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] as String,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      clubId: data['club'] as String?,
      clubName: null, // À remplir séparément si nécessaire
      department: data['department'] as String,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      lastSync: data['lastSync'] != null
          ? (data['lastSync'] as dynamic).toDate()
          : null,
    );
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? clubId,
    String? clubName,
    String? department,
    DateTime? createdAt,
    DateTime? lastSync,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return email.split('@').first;
  }
}
