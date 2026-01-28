import 'package:flutter/material.dart';
import 'dart:math';
import '../services/c200_calculator.dart';
import '../theme/app_theme.dart';

class C200OverlayWidget extends StatelessWidget {
  final double centerX;
  final double centerY;
  final double scale; // Pixels per mm
  final double opacity;
  final bool showLabels;
  final bool showCenter;

  const C200OverlayWidget({
    Key? key,
    required this.centerX,
    required this.centerY,
    required this.scale,
    this.opacity = 0.5,
    this.showLabels = true,
    this.showCenter = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: C200OverlayPainter(
        centerX: centerX,
        centerY: centerY,
        scale: scale,
        opacity: opacity,
        showLabels: showLabels,
        showCenter: showCenter,
      ),
      child: Container(),
    );
  }
}

class C200OverlayPainter extends CustomPainter {
  final double centerX;
  final double centerY;
  final double scale;
  final double opacity;
  final bool showLabels;
  final bool showCenter;

  C200OverlayPainter({
    required this.centerX,
    required this.centerY,
    required this.scale,
    required this.opacity,
    required this.showLabels,
    required this.showCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner les 10 zones C200 du plus grand au plus petit
    // Pour que les couleurs s'affichent correctement
    for (int i = C200Calculator.zones.length - 1; i >= 0; i--) {
      final zone = C200Calculator.zones[i];
      _drawZone(canvas, zone);
    }

    // Dessiner le centre (croix)
    if (showCenter) {
      _drawCenterCross(canvas);
    }
  }

  void _drawZone(Canvas canvas, dynamic zone) {
    final radiusPixels = C200Calculator.mmToPixels(zone.outerRadiusMm, scale);

    // Couleurs C200 officielles (simplifiées pour visibilité)
    Color zoneColor;
    switch (zone.zone) {
      case 10:
        zoneColor = Colors.white;
        break;
      case 9:
      case 8:
        zoneColor = Colors.black;
        break;
      case 7:
      case 6:
        zoneColor = Colors.blue;
        break;
      case 5:
      case 4:
        zoneColor = Colors.red;
        break;
      case 3:
      case 2:
        zoneColor = Colors.yellow.shade700;
        break;
      case 1:
        zoneColor = Colors.white;
        break;
      default:
        zoneColor = Colors.grey;
    }

    // Remplissage de la zone
    final fillPaint = Paint()
      ..color = zoneColor.withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radiusPixels,
      fillPaint,
    );

    // Bordure de la zone
    final strokePaint = Paint()
      ..color = zoneColor.withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radiusPixels,
      strokePaint,
    );

    // Label du numéro de zone
    if (showLabels && zone.zone <= 10) {
      _drawZoneLabel(canvas, zone.zone, radiusPixels, zoneColor);
    }
  }

  void _drawZoneLabel(Canvas canvas, int zoneNumber, double radiusPixels, Color bgColor) {
    // Positionner le label au-dessus du centre, sur le cercle
    final labelX = centerX;
    final labelY = centerY - radiusPixels + 15;

    // Choisir la couleur du texte basée sur la couleur de fond
    final textColor = _getContrastColor(bgColor);

    final textPainter = TextPainter(
      text: TextSpan(
        text: zoneNumber.toString(),
        style: TextStyle(
          color: textColor.withValues(alpha: opacity),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Fond du label
    final bgPaint = Paint()
      ..color = bgColor.withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.fill;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(labelX, labelY),
        width: textPainter.width + 12,
        height: textPainter.height + 8,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(bgRect, bgPaint);

    // Bordure du label
    final borderPaint = Paint()
      ..color = textColor.withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(bgRect, borderPaint);

    // Texte
    textPainter.paint(
      canvas,
      Offset(
        labelX - textPainter.width / 2,
        labelY - textPainter.height / 2,
      ),
    );
  }

  void _drawCenterCross(Canvas canvas) {
    final crossPaint = Paint()
      ..color = AppTheme.accentPrimary.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const crossSize = 20.0;

    // Ligne horizontale
    canvas.drawLine(
      Offset(centerX - crossSize, centerY),
      Offset(centerX + crossSize, centerY),
      crossPaint,
    );

    // Ligne verticale
    canvas.drawLine(
      Offset(centerX, centerY - crossSize),
      Offset(centerX, centerY + crossSize),
      crossPaint,
    );

    // Cercle au centre
    canvas.drawCircle(
      Offset(centerX, centerY),
      5,
      Paint()
        ..color = AppTheme.accentPrimary.withValues(alpha: opacity)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(centerX, centerY),
      5,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculer la luminance pour choisir noir ou blanc
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  bool shouldRepaint(C200OverlayPainter oldDelegate) {
    return centerX != oldDelegate.centerX ||
        centerY != oldDelegate.centerY ||
        scale != oldDelegate.scale ||
        opacity != oldDelegate.opacity ||
        showLabels != oldDelegate.showLabels ||
        showCenter != oldDelegate.showCenter;
  }
}
