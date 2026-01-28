import 'dart:ui';

class C200Zone {
  final int zone;
  final double innerRadiusMm;
  final double outerRadiusMm;
  final int points;

  const C200Zone({
    required this.zone,
    required this.innerRadiusMm,
    required this.outerRadiusMm,
    required this.points,
  });

  bool containsPoint(double distanceMm) {
    return distanceMm >= innerRadiusMm && distanceMm < outerRadiusMm;
  }
}

class C200Score {
  final int totalScore;
  final List<ImpactScore> impactScores;
  final double averageScore;
  final int perfectShots;
  final int totalShots;

  C200Score({
    required this.totalScore,
    required this.impactScores,
    required this.averageScore,
    required this.perfectShots,
    required this.totalShots,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalScore': totalScore,
      'impactScores': impactScores.map((s) => s.toMap()).toList(),
      'averageScore': averageScore,
      'perfectShots': perfectShots,
      'totalShots': totalShots,
    };
  }

  factory C200Score.fromMap(Map<String, dynamic> map) {
    return C200Score(
      totalScore: map['totalScore'] as int,
      impactScores: (map['impactScores'] as List)
          .map((item) => ImpactScore.fromMap(item as Map<String, dynamic>))
          .toList(),
      averageScore: map['averageScore'] as double,
      perfectShots: map['perfectShots'] as int,
      totalShots: map['totalShots'] as int,
    );
  }
}

class ImpactScore {
  final int impactIndex;
  final int zone;
  final int points;
  final double distanceFromCenterMm;

  ImpactScore({
    required this.impactIndex,
    required this.zone,
    required this.points,
    required this.distanceFromCenterMm,
  });

  Map<String, dynamic> toMap() {
    return {
      'impactIndex': impactIndex,
      'zone': zone,
      'points': points,
      'distanceFromCenterMm': distanceFromCenterMm,
    };
  }

  factory ImpactScore.fromMap(Map<String, dynamic> map) {
    return ImpactScore(
      impactIndex: map['impactIndex'] as int,
      zone: map['zone'] as int,
      points: map['points'] as int,
      distanceFromCenterMm: map['distanceFromCenterMm'] as double,
    );
  }
}

class C200Calibration {
  final double centerX;
  final double centerY;
  final double scale; // Pixels per mm
  final Size imageSize;
  final double rotation; // Rotation en radians

  C200Calibration({
    required this.centerX,
    required this.centerY,
    required this.scale,
    required this.imageSize,
    this.rotation = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'centerX': centerX,
      'centerY': centerY,
      'scale': scale,
      'imageWidth': imageSize.width,
      'imageHeight': imageSize.height,
      'rotation': rotation,
    };
  }

  factory C200Calibration.fromMap(Map<String, dynamic> map) {
    return C200Calibration(
      centerX: map['centerX'] as double,
      centerY: map['centerY'] as double,
      scale: map['scale'] as double,
      imageSize: Size(
        map['imageWidth'] as double,
        map['imageHeight'] as double,
      ),
      rotation: map['rotation'] as double? ?? 0.0,
    );
  }

  C200Calibration copyWith({
    double? centerX,
    double? centerY,
    double? scale,
    Size? imageSize,
    double? rotation,
  }) {
    return C200Calibration(
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      scale: scale ?? this.scale,
      imageSize: imageSize ?? this.imageSize,
      rotation: rotation ?? this.rotation,
    );
  }
}
