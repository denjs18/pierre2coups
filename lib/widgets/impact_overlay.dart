import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/impact.dart';
import '../models/target.dart';
import '../services/statistics_calculator.dart';

class ImpactOverlay extends StatelessWidget {
  final String imagePath;
  final List<Impact> impacts;
  final TargetCalibration? calibration;
  final Function(Offset)? onTap;
  final Function(int)? onImpactTap;
  final bool showGroupCenter;
  final bool readOnly;

  const ImpactOverlay({
    Key? key,
    required this.imagePath,
    required this.impacts,
    this.calibration,
    this.onTap,
    this.onImpactTap,
    this.showGroupCenter = false,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: GestureDetector(
        onTapDown: readOnly
            ? null
            : (details) {
                if (onTap != null) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(details.globalPosition);
                  onTap!(localPosition);
                }
              },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image de fond
            if (kIsWeb)
              Image.network(imagePath, fit: BoxFit.contain)
            else
              Image.file(File(imagePath), fit: BoxFit.contain),

            // Overlay des impacts et du centre
            CustomPaint(
              painter: ImpactPainter(
                impacts: impacts,
                calibration: calibration,
                onImpactTap: readOnly ? null : onImpactTap,
                showGroupCenter: showGroupCenter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImpactPainter extends CustomPainter {
  final List<Impact> impacts;
  final TargetCalibration? calibration;
  final Function(int)? onImpactTap;
  final bool showGroupCenter;

  ImpactPainter({
    required this.impacts,
    this.calibration,
    this.onImpactTap,
    this.showGroupCenter = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculer le ratio entre la taille de l'image et la taille du widget
    // Pour l'instant, on suppose que l'image remplit le widget
    final imageWidth = size.width;
    final imageHeight = size.height;

    // Dessiner la calibration de la cible (optionnel)
    if (calibration != null) {
      final calibPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        Offset(calibration!.centerX, calibration!.centerY),
        calibration!.radius,
        calibPaint,
      );

      // Dessiner le centre de la cible
      canvas.drawCircle(
        Offset(calibration!.centerX, calibration!.centerY),
        5,
        Paint()..color = Colors.blue,
      );
    }

    // Dessiner les impacts
    final impactPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final impactFillPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < impacts.length; i++) {
      final impact = impacts[i];
      final center = Offset(impact.x, impact.y);

      // Cercle de l'impact
      canvas.drawCircle(center, 15, impactFillPaint);
      canvas.drawCircle(center, 15, impactPaint);

      // Point central
      canvas.drawCircle(center, 3, Paint()..color = Colors.red);

      // Numéro de l'impact
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          impact.x - textPainter.width / 2,
          impact.y - textPainter.height / 2,
        ),
      );
    }

    // Dessiner le centre du groupement
    if (showGroupCenter && impacts.isNotEmpty) {
      final stats = StatisticsCalculator.calculateStatistics(impacts);
      final groupCenter = Offset(stats.centerX, stats.centerY);

      // Croix verte pour le centre du groupement
      final centerPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      const crossSize = 20.0;
      canvas.drawLine(
        Offset(groupCenter.dx - crossSize, groupCenter.dy),
        Offset(groupCenter.dx + crossSize, groupCenter.dy),
        centerPaint,
      );
      canvas.drawLine(
        Offset(groupCenter.dx, groupCenter.dy - crossSize),
        Offset(groupCenter.dx, groupCenter.dy + crossSize),
        centerPaint,
      );

      // Cercle autour du centre
      canvas.drawCircle(
        groupCenter,
        10,
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(ImpactPainter oldDelegate) {
    return impacts != oldDelegate.impacts ||
        calibration != oldDelegate.calibration ||
        showGroupCenter != oldDelegate.showGroupCenter;
  }
}
