import 'dart:math';
import '../models/impact.dart';
import '../models/c200_scoring.dart';

class C200Calculator {
  // Zones C200 officielles (10 zones circulaires, 40mm de rayon chacune)
  // Zone 10 = centre (0-40mm), Zone 9 (40-80mm), etc.
  static const List<C200Zone> zones = [
    C200Zone(zone: 10, innerRadiusMm: 0, outerRadiusMm: 40, points: 10),
    C200Zone(zone: 9, innerRadiusMm: 40, outerRadiusMm: 80, points: 9),
    C200Zone(zone: 8, innerRadiusMm: 80, outerRadiusMm: 120, points: 8),
    C200Zone(zone: 7, innerRadiusMm: 120, outerRadiusMm: 160, points: 7),
    C200Zone(zone: 6, innerRadiusMm: 160, outerRadiusMm: 200, points: 6),
    C200Zone(zone: 5, innerRadiusMm: 200, outerRadiusMm: 240, points: 5),
    C200Zone(zone: 4, innerRadiusMm: 240, outerRadiusMm: 280, points: 4),
    C200Zone(zone: 3, innerRadiusMm: 280, outerRadiusMm: 320, points: 3),
    C200Zone(zone: 2, innerRadiusMm: 320, outerRadiusMm: 360, points: 2),
    C200Zone(zone: 1, innerRadiusMm: 360, outerRadiusMm: 400, points: 1),
  ];

  /// Calculer le score d'un impact individuel
  static ImpactScore? calculateImpactScore(
    Impact impact,
    C200Calibration calibration,
  ) {
    // Calculer la distance en pixels du centre
    final dx = impact.x - calibration.centerX;
    final dy = impact.y - calibration.centerY;
    final distancePixels = sqrt(dx * dx + dy * dy);

    // Convertir en millimètres
    final distanceMm = pixelsToMm(distancePixels, calibration.scale);

    // Déterminer la zone
    final zone = determineZone(distanceMm);

    if (zone == 0) {
      // Impact hors cible
      return null;
    }

    return ImpactScore(
      impactIndex: impact.id ?? 0,
      zone: zone,
      points: zone, // Dans C200, les points = numéro de zone
      distanceFromCenterMm: distanceMm,
    );
  }

  /// Calculer le score total d'une session
  static C200Score calculateSessionScore(
    List<Impact> impacts,
    C200Calibration calibration,
  ) {
    final List<ImpactScore> impactScores = [];
    int totalScore = 0;
    int perfectShots = 0;

    for (int i = 0; i < impacts.length; i++) {
      final impactScore = calculateImpactScore(impacts[i], calibration);

      if (impactScore != null) {
        impactScores.add(impactScore);
        totalScore += impactScore.points;

        if (impactScore.zone == 10) {
          perfectShots++;
        }
      }
    }

    final averageScore = impactScores.isNotEmpty
        ? totalScore / impactScores.length
        : 0.0;

    return C200Score(
      totalScore: totalScore,
      impactScores: impactScores,
      averageScore: averageScore,
      perfectShots: perfectShots,
      totalShots: impacts.length,
    );
  }

  /// Convertir pixels en millimètres
  static double pixelsToMm(double pixels, double scale) {
    // scale = pixels per mm
    if (scale == 0) return 0;
    return pixels / scale;
  }

  /// Convertir millimètres en pixels
  static double mmToPixels(double mm, double scale) {
    return mm * scale;
  }

  /// Déterminer la zone C200 d'un impact basé sur sa distance du centre
  static int determineZone(double distanceFromCenterMm) {
    for (final zone in zones) {
      if (zone.containsPoint(distanceFromCenterMm)) {
        return zone.zone;
      }
    }
    return 0; // Hors cible
  }

  /// Obtenir la zone C200 par son numéro
  static C200Zone? getZone(int zoneNumber) {
    try {
      return zones.firstWhere((z) => z.zone == zoneNumber);
    } catch (e) {
      return null;
    }
  }

  /// Calculer l'échelle automatique basée sur un rayon de référence
  /// Par exemple, si l'utilisateur dit "ce cercle fait 100mm", on calcule pixels/mm
  static double calculateScale({
    required double radiusPixels,
    required double radiusMm,
  }) {
    if (radiusMm == 0) return 1.0;
    return radiusPixels / radiusMm;
  }

  /// Calculer l'échelle automatique pour la cible C200 complète
  /// La zone 1 (extérieure) a un rayon de 400mm
  static double calculateScaleFromTargetRadius(double targetRadiusPixels) {
    const double c200OuterRadiusMm = 400.0;
    return calculateScale(
      radiusPixels: targetRadiusPixels,
      radiusMm: c200OuterRadiusMm,
    );
  }

  /// Calculer l'échelle basée sur la zone 10 (centre, rayon 40mm)
  static double calculateScaleFromZone10(double zone10RadiusPixels) {
    const double zone10RadiusMm = 40.0;
    return calculateScale(
      radiusPixels: zone10RadiusPixels,
      radiusMm: zone10RadiusMm,
    );
  }

  /// Vérifier si un point est dans la cible C200 (zone 1 ou mieux)
  static bool isInTarget(double distanceFromCenterMm) {
    return distanceFromCenterMm <= 400.0;
  }

  /// Obtenir la couleur associée à une zone (pour l'affichage)
  static String getZoneColor(int zone) {
    switch (zone) {
      case 10:
        return '#FFFFFF'; // Blanc (centre)
      case 9:
      case 8:
        return '#000000'; // Noir
      case 7:
      case 6:
        return '#0000FF'; // Bleu
      case 5:
      case 4:
        return '#FF0000'; // Rouge
      case 3:
      case 2:
        return '#FFFF00'; // Jaune
      case 1:
        return '#FFFFFF'; // Blanc
      default:
        return '#CCCCCC'; // Gris (hors cible)
    }
  }

  /// Calculer le score maximum possible pour un nombre de tirs
  static int calculateMaxScore(int numberOfShots) {
    return numberOfShots * 10;
  }

  /// Calculer le pourcentage de précision basé sur le score
  static double calculateAccuracyPercentage(int score, int numberOfShots) {
    if (numberOfShots == 0) return 0.0;
    final maxScore = calculateMaxScore(numberOfShots);
    return (score / maxScore) * 100;
  }

  /// Créer un rapport textuel du score
  static String generateScoreReport(C200Score score) {
    final buffer = StringBuffer();
    buffer.writeln('=== RAPPORT C200 ===');
    buffer.writeln('Score total: ${score.totalScore}/${calculateMaxScore(score.totalShots)}');
    buffer.writeln('Moyenne par tir: ${score.averageScore.toStringAsFixed(2)}');
    buffer.writeln('Tirs parfaits (10): ${score.perfectShots}');
    buffer.writeln('Précision: ${calculateAccuracyPercentage(score.totalScore, score.totalShots).toStringAsFixed(1)}%');
    buffer.writeln('\nDétail par impact:');

    for (int i = 0; i < score.impactScores.length; i++) {
      final impact = score.impactScores[i];
      buffer.writeln(
        'Impact ${i + 1}: Zone ${impact.zone} (${impact.points} pts) - ${impact.distanceFromCenterMm.toStringAsFixed(1)}mm du centre',
      );
    }

    return buffer.toString();
  }

  /// Calculer des statistiques avancées
  static Map<String, dynamic> calculateAdvancedStats(C200Score score) {
    if (score.impactScores.isEmpty) {
      return {
        'meanDistance': 0.0,
        'medianDistance': 0.0,
        'stdDeviation': 0.0,
        'consistency': 0.0,
      };
    }

    // Distances triées
    final distances = score.impactScores
        .map((s) => s.distanceFromCenterMm)
        .toList()
      ..sort();

    // Distance moyenne
    final meanDistance = distances.reduce((a, b) => a + b) / distances.length;

    // Distance médiane
    final medianDistance = distances.length.isOdd
        ? distances[distances.length ~/ 2]
        : (distances[distances.length ~/ 2 - 1] +
                distances[distances.length ~/ 2]) /
            2;

    // Écart-type des distances
    final variance = distances
            .map((d) => pow(d - meanDistance, 2))
            .reduce((a, b) => a + b) /
        distances.length;
    final stdDeviation = sqrt(variance);

    // Indice de consistance (0-100, plus élevé = plus consistant)
    final consistency = max(0.0, 100 - (stdDeviation / 4));

    return {
      'meanDistance': meanDistance,
      'medianDistance': medianDistance,
      'stdDeviation': stdDeviation,
      'consistency': consistency,
    };
  }
}
