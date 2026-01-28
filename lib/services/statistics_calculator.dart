import 'dart:math';
import '../models/impact.dart';

class Statistics {
  final double centerX;
  final double centerY;
  final double meanRadius;
  final double stdDeviation;
  final double groupDiameter;
  final int shotCount;

  Statistics({
    required this.centerX,
    required this.centerY,
    required this.meanRadius,
    required this.stdDeviation,
    required this.groupDiameter,
    required this.shotCount,
  });
}

class StatisticsCalculator {
  /// Calcule les statistiques d'un groupement d'impacts
  static Statistics calculateStatistics(List<Impact> impacts) {
    if (impacts.isEmpty) {
      return Statistics(
        centerX: 0,
        centerY: 0,
        meanRadius: 0,
        stdDeviation: 0,
        groupDiameter: 0,
        shotCount: 0,
      );
    }

    // Calcul du centre du groupement (barycentre)
    double sumX = 0;
    double sumY = 0;
    for (var impact in impacts) {
      sumX += impact.x;
      sumY += impact.y;
    }
    final centerX = sumX / impacts.length;
    final centerY = sumY / impacts.length;

    // Calcul des distances de chaque impact au centre
    List<double> distances = [];
    for (var impact in impacts) {
      final dx = impact.x - centerX;
      final dy = impact.y - centerY;
      final distance = sqrt(dx * dx + dy * dy);
      distances.add(distance);
    }

    // Rayon moyen
    final meanRadius = distances.reduce((a, b) => a + b) / distances.length;

    // Écart-type
    double sumSquaredDiff = 0;
    for (var distance in distances) {
      final diff = distance - meanRadius;
      sumSquaredDiff += diff * diff;
    }
    final variance = sumSquaredDiff / distances.length;
    final stdDeviation = sqrt(variance);

    // Diamètre du groupement (2 × écart-type)
    final groupDiameter = 2 * stdDeviation;

    return Statistics(
      centerX: centerX,
      centerY: centerY,
      meanRadius: meanRadius,
      stdDeviation: stdDeviation,
      groupDiameter: groupDiameter,
      shotCount: impacts.length,
    );
  }

  /// Convertit des pixels en centimètres
  static double pixelsToCm(double pixels, double pixelsPerCm) {
    return pixels / pixelsPerCm;
  }

  /// Calcule la distance entre deux points
  static double distance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return sqrt(dx * dx + dy * dy);
  }

  /// Calcule la distance d'un impact au centre de la cible
  static double distanceToTargetCenter(
    Impact impact,
    double targetCenterX,
    double targetCenterY,
  ) {
    return distance(impact.x, impact.y, targetCenterX, targetCenterY);
  }

  /// Calcule le pourcentage de précision basé sur l'écart-type
  /// (Plus l'écart-type est faible, meilleure est la précision)
  static double calculatePrecisionScore(
    double stdDeviation,
    double targetRadius,
  ) {
    if (targetRadius == 0) return 0;
    final normalizedStd = stdDeviation / targetRadius;
    final score = max(0.0, 100.0 - (normalizedStd * 100));
    return min(100.0, score).toDouble();
  }
}
