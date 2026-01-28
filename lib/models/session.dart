class Session {
  final int? id;
  final String date;
  final String? weapon; // Deprecated: use weaponName instead
  final double? distance;
  final int shotCount;
  final String imagePath;
  final double? stdDeviation;
  final double? meanRadius;
  final double? groupCenterX;
  final double? groupCenterY;
  final String? notes;
  final String createdAt;

  // Nouveaux champs Firebase
  final String? firestoreId;
  final String? userId;
  final String? weaponId;
  final String? weaponName;
  final String? clubId;
  final String? imageUrl;
  final double? c200Score;
  final Map<String, dynamic>? c200Details;
  final DateTime? updatedAt;
  final String syncStatus;
  final bool isMigrated;

  Session({
    this.id,
    required this.date,
    this.weapon,
    this.distance,
    required this.shotCount,
    required this.imagePath,
    this.stdDeviation,
    this.meanRadius,
    this.groupCenterX,
    this.groupCenterY,
    this.notes,
    required this.createdAt,
    this.firestoreId,
    this.userId,
    this.weaponId,
    this.weaponName,
    this.clubId,
    this.imageUrl,
    this.c200Score,
    this.c200Details,
    this.updatedAt,
    this.syncStatus = 'pending',
    this.isMigrated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'weapon': weapon,
      'distance': distance,
      'shot_count': shotCount,
      'image_path': imagePath,
      'std_deviation': stdDeviation,
      'mean_radius': meanRadius,
      'group_center_x': groupCenterX,
      'group_center_y': groupCenterY,
      'notes': notes,
      'created_at': createdAt,
      'firestore_id': firestoreId,
      'user_id': userId,
      'weapon_id': weaponId,
      'weapon_name': weaponName,
      'club_id': clubId,
      'image_url': imageUrl,
      'c200_score': c200Score,
      'c200_details': c200Details != null ? c200Details.toString() : null,
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'is_migrated': isMigrated ? 1 : 0,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as int?,
      date: map['date'] as String,
      weapon: map['weapon'] as String?,
      distance: map['distance'] as double?,
      shotCount: map['shot_count'] as int,
      imagePath: map['image_path'] as String,
      stdDeviation: map['std_deviation'] as double?,
      meanRadius: map['mean_radius'] as double?,
      groupCenterX: map['group_center_x'] as double?,
      groupCenterY: map['group_center_y'] as double?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      firestoreId: map['firestore_id'] as String?,
      userId: map['user_id'] as String?,
      weaponId: map['weapon_id'] as String?,
      weaponName: map['weapon_name'] as String?,
      clubId: map['club_id'] as String?,
      imageUrl: map['image_url'] as String?,
      c200Score: map['c200_score'] as double?,
      c200Details: map['c200_details'] != null ? {} : null, // TODO: parse JSON
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      syncStatus: map['sync_status'] as String? ?? 'pending',
      isMigrated: (map['is_migrated'] as int?) == 1,
    );
  }

  Session copyWith({
    int? id,
    String? date,
    String? weapon,
    double? distance,
    int? shotCount,
    String? imagePath,
    double? stdDeviation,
    double? meanRadius,
    double? groupCenterX,
    double? groupCenterY,
    String? notes,
    String? createdAt,
    String? firestoreId,
    String? userId,
    String? weaponId,
    String? weaponName,
    String? clubId,
    String? imageUrl,
    double? c200Score,
    Map<String, dynamic>? c200Details,
    DateTime? updatedAt,
    String? syncStatus,
    bool? isMigrated,
  }) {
    return Session(
      id: id ?? this.id,
      date: date ?? this.date,
      weapon: weapon ?? this.weapon,
      distance: distance ?? this.distance,
      shotCount: shotCount ?? this.shotCount,
      imagePath: imagePath ?? this.imagePath,
      stdDeviation: stdDeviation ?? this.stdDeviation,
      meanRadius: meanRadius ?? this.meanRadius,
      groupCenterX: groupCenterX ?? this.groupCenterX,
      groupCenterY: groupCenterY ?? this.groupCenterY,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      firestoreId: firestoreId ?? this.firestoreId,
      userId: userId ?? this.userId,
      weaponId: weaponId ?? this.weaponId,
      weaponName: weaponName ?? this.weaponName,
      clubId: clubId ?? this.clubId,
      imageUrl: imageUrl ?? this.imageUrl,
      c200Score: c200Score ?? this.c200Score,
      c200Details: c200Details ?? this.c200Details,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isMigrated: isMigrated ?? this.isMigrated,
    );
  }

  // Méthode pour obtenir le nom de l'arme à afficher
  String? get displayWeaponName => weaponName ?? weapon;
}
