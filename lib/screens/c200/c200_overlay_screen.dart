import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/impact.dart';
import '../../models/c200_scoring.dart';
import '../../services/c200_calculator.dart';
import '../../widgets/c200_overlay_widget.dart';
import '../../theme/app_theme.dart';

class C200OverlayScreen extends StatefulWidget {
  final String imagePath;
  final List<Impact> impacts;
  final Size imageSize;

  const C200OverlayScreen({
    Key? key,
    required this.imagePath,
    required this.impacts,
    required this.imageSize,
  }) : super(key: key);

  @override
  State<C200OverlayScreen> createState() => _C200OverlayScreenState();
}

class _C200OverlayScreenState extends State<C200OverlayScreen> {
  late double _centerX;
  late double _centerY;
  late double _scale;
  double _opacity = 0.5;
  C200Score? _previewScore;

  @override
  void initState() {
    super.initState();
    // Initialiser au centre de l'image avec une échelle par défaut
    _centerX = widget.imageSize.width / 2;
    _centerY = widget.imageSize.height / 2;

    // Échelle par défaut : la cible C200 complète (rayon 400mm) représente ~40% de l'image
    final estimatedRadiusPixels = widget.imageSize.width * 0.4;
    _scale = C200Calculator.calculateScaleFromTargetRadius(estimatedRadiusPixels);

    _updatePreviewScore();
  }

  void _updatePreviewScore() {
    final calibration = C200Calibration(
      centerX: _centerX,
      centerY: _centerY,
      scale: _scale,
      imageSize: widget.imageSize,
    );

    setState(() {
      _previewScore =
          C200Calculator.calculateSessionScore(widget.impacts, calibration);
    });
  }

  void _adjustScale(double delta) {
    setState(() {
      _scale = (_scale + delta).clamp(0.5, 20.0);
      _updatePreviewScore();
    });
  }

  void _validate() {
    if (_previewScore != null) {
      final calibration = C200Calibration(
        centerX: _centerX,
        centerY: _centerY,
        scale: _scale,
        imageSize: widget.imageSize,
      );

      Navigator.pop(context, {
        'calibration': calibration,
        'score': _previewScore,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('POSITIONNEMENT C200'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: 'Aide',
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone d'affichage de l'image avec overlay
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _centerX += details.delta.dx;
                  _centerY += details.delta.dy;
                  _updatePreviewScore();
                });
              },
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image de fond
                    if (kIsWeb)
                      Image.network(widget.imagePath, fit: BoxFit.contain)
                    else
                      Image.file(File(widget.imagePath), fit: BoxFit.contain),

                    // Overlay C200
                    CustomPaint(
                      painter: C200OverlayPainter(
                        centerX: _centerX,
                        centerY: _centerY,
                        scale: _scale,
                        opacity: _opacity,
                        showLabels: true,
                        showCenter: true,
                      ),
                    ),

                    // Impacts
                    CustomPaint(
                      painter: ImpactsPainter(
                        impacts: widget.impacts,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Panneau de contrôle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                top: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Score preview
                  if (_previewScore != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPreviewStat(
                            'Score',
                            '${_previewScore!.totalScore}/${C200Calculator.calculateMaxScore(_previewScore!.totalShots)}',
                            AppTheme.accentPrimary,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: AppTheme.borderColor,
                          ),
                          _buildPreviewStat(
                            'Moyenne',
                            _previewScore!.averageScore.toStringAsFixed(1),
                            AppTheme.accentSecondary,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: AppTheme.borderColor,
                          ),
                          _buildPreviewStat(
                            'Parfaits',
                            '${_previewScore!.perfectShots}',
                            Colors.amber,
                          ),
                        ],
                      ),
                    ),

                  // Contrôles échelle avec slider
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.zoom_out,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Slider(
                              value: _scale,
                              min: 0.5,
                              max: 10.0,
                              divisions: 95,
                              label: _scale.toStringAsFixed(1),
                              activeColor: AppTheme.accentPrimary,
                              inactiveColor: AppTheme.borderColor,
                              onChanged: (value) {
                                setState(() {
                                  _scale = value;
                                  _updatePreviewScore();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.zoom_in,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Ajustement rapide -1.0
                          IconButton(
                            icon: const Icon(Icons.keyboard_double_arrow_left, size: 20),
                            onPressed: () => _adjustScale(-1.0),
                            color: AppTheme.accentSecondary,
                            tooltip: '-1.0',
                          ),
                          // Ajustement fin -0.1
                          IconButton(
                            icon: const Icon(Icons.remove, size: 20),
                            onPressed: () => _adjustScale(-0.1),
                            color: AppTheme.accentSecondary,
                            tooltip: '-0.1',
                          ),
                          // Affichage valeur
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Text(
                              'Échelle: ${_scale.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Ajustement fin +0.1
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: () => _adjustScale(0.1),
                            color: AppTheme.accentPrimary,
                            tooltip: '+0.1',
                          ),
                          // Ajustement rapide +1.0
                          IconButton(
                            icon: const Icon(Icons.keyboard_double_arrow_right, size: 20),
                            onPressed: () => _adjustScale(1.0),
                            color: AppTheme.accentPrimary,
                            tooltip: '+1.0',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contrôle opacité
                  Row(
                    children: [
                      Icon(
                        Icons.opacity,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _opacity,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          label: '${(_opacity * 100).toInt()}%',
                          activeColor: AppTheme.accentPrimary,
                          onChanged: (value) {
                            setState(() {
                              _opacity = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        '${(_opacity * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bouton de validation
                  ElevatedButton.icon(
                    onPressed: _validate,
                    icon: const Icon(Icons.check_circle),
                    label: const Text(
                      'VALIDER LE POSITIONNEMENT',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.labelStyle.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Row(
          children: [
            Icon(Icons.help, color: AppTheme.accentPrimary),
            const SizedBox(width: 12),
            const Text('Comment positionner ?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(Icons.pan_tool, 'Glissez pour déplacer le centre'),
            const SizedBox(height: 12),
            _buildHelpItem(
                Icons.zoom_in, 'Utilisez +/- pour ajuster la taille'),
            const SizedBox(height: 12),
            _buildHelpItem(Icons.opacity, 'Réglez l\'opacité pour mieux voir'),
            const SizedBox(height: 12),
            _buildHelpItem(
                Icons.adjust, 'Alignez le centre avec le centre de votre cible'),
            const SizedBox(height: 12),
            _buildHelpItem(
                Icons.check_circle, 'Validez quand c\'est bien positionné'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.accentPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

// Painter pour afficher les impacts
class ImpactsPainter extends CustomPainter {
  final List<Impact> impacts;

  ImpactsPainter({required this.impacts});

  @override
  void paint(Canvas canvas, Size size) {
    final impactPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final impactFillPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (final impact in impacts) {
      final center = Offset(impact.x, impact.y);
      canvas.drawCircle(center, 10, impactFillPaint);
      canvas.drawCircle(center, 10, impactPaint);
      canvas.drawCircle(center, 2, Paint()..color = Colors.red);
    }
  }

  @override
  bool shouldRepaint(ImpactsPainter oldDelegate) {
    return impacts != oldDelegate.impacts;
  }
}
