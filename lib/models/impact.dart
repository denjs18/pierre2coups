class Impact {
  final int? id;
  final int sessionId;
  final double x;
  final double y;
  final bool isManual;

  // Nouveaux champs C200 et Firebase
  final String? firestoreId;
  final int? c200Zone;
  final double? c200Points;
  final double? distanceFromCenter;

  Impact({
    this.id,
    required this.sessionId,
    required this.x,
    required this.y,
    this.isManual = false,
    this.firestoreId,
    this.c200Zone,
    this.c200Points,
    this.distanceFromCenter,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'x': x,
      'y': y,
      'is_manual': isManual ? 1 : 0,
      'firestore_id': firestoreId,
      'c200_zone': c200Zone,
      'c200_points': c200Points,
      'distance_from_center': distanceFromCenter,
    };
  }

  factory Impact.fromMap(Map<String, dynamic> map) {
    return Impact(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      x: map['x'] as double,
      y: map['y'] as double,
      isManual: (map['is_manual'] as int) == 1,
      firestoreId: map['firestore_id'] as String?,
      c200Zone: map['c200_zone'] as int?,
      c200Points: map['c200_points'] as double?,
      distanceFromCenter: map['distance_from_center'] as double?,
    );
  }

  Impact copyWith({
    int? id,
    int? sessionId,
    double? x,
    double? y,
    bool? isManual,
    String? firestoreId,
    int? c200Zone,
    double? c200Points,
    double? distanceFromCenter,
  }) {
    return Impact(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      x: x ?? this.x,
      y: y ?? this.y,
      isManual: isManual ?? this.isManual,
      firestoreId: firestoreId ?? this.firestoreId,
      c200Zone: c200Zone ?? this.c200Zone,
      c200Points: c200Points ?? this.c200Points,
      distanceFromCenter: distanceFromCenter ?? this.distanceFromCenter,
    );
  }
}
