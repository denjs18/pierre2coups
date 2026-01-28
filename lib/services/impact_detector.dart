import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import '../models/impact.dart';
import '../models/target.dart';

class DetectionResult {
  final List<Impact> impacts;
  final TargetCalibration? calibration;
  final String message;

  DetectionResult({
    required this.impacts,
    this.calibration,
    this.message = 'Détection terminée',
  });
}

class ImpactDetector {
  /// Détecte les impacts sur une image de cible
  static Future<DetectionResult> detectImpacts(
    String imagePath, {
    int sessionId = 0,
  }) async {
    try {
      // Charger l'image
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return DetectionResult(
          impacts: [],
          message: 'Erreur: impossible de charger l\'image',
        );
      }

      // Redimensionner si l'image est trop grande (optimisation)
      img.Image processedImage = image;
      double scaleFactor = 1.0;
      if (image.width > 1920 || image.height > 1920) {
        final scale = 1920 / max(image.width, image.height);
        processedImage = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
        );
        scaleFactor = scale;
      }

      // Convertir en niveaux de gris
      final grayscale = img.grayscale(processedImage);

      // Détecter la cible (calibration)
      final calibration = _detectTarget(grayscale, sessionId, scaleFactor);

      // Détecter les impacts (trous sombres et clairs)
      final darkImpacts = _detectDarkHoles(grayscale, sessionId);
      final lightImpacts = _detectLightHoles(grayscale, sessionId);

      // Fusionner les résultats et éliminer les doublons
      final allImpacts = _mergeImpacts(darkImpacts, lightImpacts);

      // Filtrer les impacts hors de la zone de tir si calibration disponible
      final filteredImpacts = calibration != null
          ? _filterImpactsInTarget(allImpacts, calibration)
          : allImpacts;

      // Rescaler les coordonnées si l'image a été redimensionnée
      final rescaledImpacts = scaleFactor != 1.0
          ? _rescaleImpacts(filteredImpacts, 1 / scaleFactor)
          : filteredImpacts;

      return DetectionResult(
        impacts: rescaledImpacts,
        calibration: calibration,
        message: '${rescaledImpacts.length} impact(s) détecté(s)',
      );
    } catch (e) {
      return DetectionResult(
        impacts: [],
        message: 'Erreur lors de la détection: $e',
      );
    }
  }

  /// Détecte la cible (cercles concentriques) pour la calibration
  static TargetCalibration? _detectTarget(
    img.Image image,
    int sessionId,
    double scaleFactor,
  ) {
    // Pour l'instant, on retourne une calibration par défaut au centre de l'image
    // Dans une version plus avancée, on pourrait implémenter une vraie détection de cercles
    final centerX = image.width / 2;
    final centerY = image.height / 2;
    final radius = min(image.width, image.height) * 0.4;

    return TargetCalibration(
      sessionId: sessionId,
      centerX: centerX / scaleFactor,
      centerY: centerY / scaleFactor,
      radius: radius / scaleFactor,
      pixelsPerCm: 10.0, // Valeur par défaut, à ajuster
    );
  }

  /// Détecte les trous sombres (sur fond blanc)
  static List<Impact> _detectDarkHoles(img.Image image, int sessionId) {
    final impacts = <Impact>[];

    // Seuillage pour isoler les zones sombres
    // Réduit pour être plus strict (ne détecter que les zones vraiment noires)
    final threshold = 60;
    final visited = List.generate(
      image.height,
      (_) => List.filled(image.width, false),
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (visited[y][x]) continue;

        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel);

        if (luminance < threshold) {
          // Début d'une zone sombre, faire un flood fill
          final blob = _floodFill(image, x, y, threshold, true, visited);

          // Vérifier si c'est un impact potentiel (taille et circularité)
          if (_isValidImpact(blob)) {
            final center = _calculateBlobCenter(blob);
            impacts.add(Impact(
              sessionId: sessionId,
              x: center['x']!,
              y: center['y']!,
              isManual: false,
            ));
          }
        }
      }
    }

    return impacts;
  }

  /// Détecte les trous clairs (sur fond noir)
  static List<Impact> _detectLightHoles(img.Image image, int sessionId) {
    final impacts = <Impact>[];

    // Seuillage pour isoler les zones claires
    // Augmenté pour être plus strict (ne détecter que les zones vraiment blanches)
    final threshold = 195;
    final visited = List.generate(
      image.height,
      (_) => List.filled(image.width, false),
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (visited[y][x]) continue;

        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel);

        if (luminance > threshold) {
          // Début d'une zone claire, faire un flood fill
          final blob = _floodFill(image, x, y, threshold, false, visited);

          // Vérifier si c'est un impact potentiel
          if (_isValidImpact(blob)) {
            final center = _calculateBlobCenter(blob);
            impacts.add(Impact(
              sessionId: sessionId,
              x: center['x']!,
              y: center['y']!,
              isManual: false,
            ));
          }
        }
      }
    }

    return impacts;
  }

  /// Flood fill pour trouver une zone connexe
  static List<Map<String, int>> _floodFill(
    img.Image image,
    int startX,
    int startY,
    int threshold,
    bool isDark,
    List<List<bool>> visited,
  ) {
    final blob = <Map<String, int>>[];
    final stack = <Map<String, int>>[
      {'x': startX, 'y': startY}
    ];

    while (stack.isNotEmpty) {
      final point = stack.removeLast();
      final x = point['x']!;
      final y = point['y']!;

      if (x < 0 || x >= image.width || y < 0 || y >= image.height) continue;
      if (visited[y][x]) continue;

      final pixel = image.getPixel(x, y);
      final luminance = img.getLuminance(pixel);

      final matches = isDark ? luminance < threshold : luminance > threshold;
      if (!matches) continue;

      visited[y][x] = true;
      blob.add({'x': x, 'y': y});

      // Limiter la taille du blob pour éviter les boucles infinies
      if (blob.length > 10000) break;

      // Ajouter les voisins
      stack.add({'x': x + 1, 'y': y});
      stack.add({'x': x - 1, 'y': y});
      stack.add({'x': x, 'y': y + 1});
      stack.add({'x': x, 'y': y - 1});
    }

    return blob;
  }

  /// Vérifie si un blob est un impact valide
  static bool _isValidImpact(List<Map<String, int>> blob) {
    if (blob.isEmpty) return false;

    // Taille minimale et maximale (en pixels)
    // Augmenté pour éviter de détecter les artefacts et les lignes de la cible
    const minSize = 30;  // Impact minimum ~6x6 pixels
    const maxSize = 800; // Impact maximum ~28x28 pixels (un gros trou)

    if (blob.length < minSize || blob.length > maxSize) return false;

    // Vérifier la circularité (rapport entre l'aire et le périmètre)
    final center = _calculateBlobCenter(blob);
    final avgRadius = _calculateAverageRadius(blob, center);

    // Éviter les blobs avec rayon trop petit ou trop grand
    if (avgRadius < 3 || avgRadius > 20) return false;

    // Un cercle parfait a une circularité proche de 1
    // Augmenté pour être plus strict (rejeter les lignes et formes irrégulières)
    final circularityThreshold = 0.55;
    double sumDeviation = 0;
    for (var point in blob) {
      final dx = point['x']! - center['x']!;
      final dy = point['y']! - center['y']!;
      final distance = sqrt(dx * dx + dy * dy);
      sumDeviation += (distance - avgRadius).abs();
    }
    final avgDeviation = sumDeviation / blob.length;
    final circularity = 1 - (avgDeviation / avgRadius);

    // Vérifier aussi le ratio largeur/hauteur pour rejeter les lignes
    final bounds = _getBlobBounds(blob);
    final width = bounds['maxX']! - bounds['minX']! + 1;
    final height = bounds['maxY']! - bounds['minY']! + 1;
    final aspectRatio = width > height ? width / height : height / width;

    // Rejeter si trop allongé (ligne)
    if (aspectRatio > 2.5) return false;

    return circularity > circularityThreshold;
  }

  /// Calcule les limites d'un blob
  static Map<String, int> _getBlobBounds(List<Map<String, int>> blob) {
    int minX = blob[0]['x']!;
    int maxX = blob[0]['x']!;
    int minY = blob[0]['y']!;
    int maxY = blob[0]['y']!;

    for (var point in blob) {
      if (point['x']! < minX) minX = point['x']!;
      if (point['x']! > maxX) maxX = point['x']!;
      if (point['y']! < minY) minY = point['y']!;
      if (point['y']! > maxY) maxY = point['y']!;
    }

    return {
      'minX': minX,
      'maxX': maxX,
      'minY': minY,
      'maxY': maxY,
    };
  }

  /// Calcule le centre d'un blob
  static Map<String, double> _calculateBlobCenter(
    List<Map<String, int>> blob,
  ) {
    double sumX = 0;
    double sumY = 0;
    for (var point in blob) {
      sumX += point['x']!;
      sumY += point['y']!;
    }
    return {
      'x': sumX / blob.length,
      'y': sumY / blob.length,
    };
  }

  /// Calcule le rayon moyen d'un blob
  static double _calculateAverageRadius(
    List<Map<String, int>> blob,
    Map<String, double> center,
  ) {
    double sumRadius = 0;
    for (var point in blob) {
      final dx = point['x']! - center['x']!;
      final dy = point['y']! - center['y']!;
      sumRadius += sqrt(dx * dx + dy * dy);
    }
    return sumRadius / blob.length;
  }

  /// Fusionne les impacts et élimine les doublons
  static List<Impact> _mergeImpacts(
    List<Impact> impacts1,
    List<Impact> impacts2,
  ) {
    final merged = <Impact>[...impacts1];
    const duplicateThreshold = 15.0; // pixels

    for (var impact2 in impacts2) {
      bool isDuplicate = false;
      for (var impact1 in impacts1) {
        final dx = impact2.x - impact1.x;
        final dy = impact2.y - impact1.y;
        final distance = sqrt(dx * dx + dy * dy);
        if (distance < duplicateThreshold) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate) {
        merged.add(impact2);
      }
    }

    return merged;
  }

  /// Filtre les impacts qui sont hors de la zone de tir
  static List<Impact> _filterImpactsInTarget(
    List<Impact> impacts,
    TargetCalibration calibration,
  ) {
    return impacts.where((impact) {
      final dx = impact.x - calibration.centerX;
      final dy = impact.y - calibration.centerY;
      final distance = sqrt(dx * dx + dy * dy);
      // Garder les impacts dans un rayon de 1.2× le rayon de la cible
      return distance <= calibration.radius * 1.2;
    }).toList();
  }

  /// Rescale les coordonnées des impacts
  static List<Impact> _rescaleImpacts(List<Impact> impacts, double scale) {
    return impacts.map((impact) {
      return Impact(
        id: impact.id,
        sessionId: impact.sessionId,
        x: impact.x * scale,
        y: impact.y * scale,
        isManual: impact.isManual,
      );
    }).toList();
  }
}
