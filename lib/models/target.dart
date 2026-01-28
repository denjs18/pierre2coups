class TargetCalibration {
  final int? id;
  final int sessionId;
  final double centerX;
  final double centerY;
  final double radius;
  final double? pixelsPerCm;

  // Nouveaux champs C200
  final double? c200CenterX;
  final double? c200CenterY;
  final double? c200Scale;

  TargetCalibration({
    this.id,
    required this.sessionId,
    required this.centerX,
    required this.centerY,
    required this.radius,
    this.pixelsPerCm,
    this.c200CenterX,
    this.c200CenterY,
    this.c200Scale,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'center_x': centerX,
      'center_y': centerY,
      'radius': radius,
      'pixels_per_cm': pixelsPerCm,
      'c200_center_x': c200CenterX,
      'c200_center_y': c200CenterY,
      'c200_scale': c200Scale,
    };
  }

  factory TargetCalibration.fromMap(Map<String, dynamic> map) {
    return TargetCalibration(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      centerX: map['center_x'] as double,
      centerY: map['center_y'] as double,
      radius: map['radius'] as double,
      pixelsPerCm: map['pixels_per_cm'] as double?,
      c200CenterX: map['c200_center_x'] as double?,
      c200CenterY: map['c200_center_y'] as double?,
      c200Scale: map['c200_scale'] as double?,
    );
  }

  TargetCalibration copyWith({
    int? id,
    int? sessionId,
    double? centerX,
    double? centerY,
    double? radius,
    double? pixelsPerCm,
    double? c200CenterX,
    double? c200CenterY,
    double? c200Scale,
  }) {
    return TargetCalibration(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      radius: radius ?? this.radius,
      pixelsPerCm: pixelsPerCm ?? this.pixelsPerCm,
      c200CenterX: c200CenterX ?? this.c200CenterX,
      c200CenterY: c200CenterY ?? this.c200CenterY,
      c200Scale: c200Scale ?? this.c200Scale,
    );
  }
}
