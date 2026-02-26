import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/session.dart';
import '../models/impact.dart';
import '../models/target.dart';
import '../models/c200_scoring.dart';
import '../services/statistics_calculator.dart';
import '../services/c200_calculator.dart';
import '../widgets/impact_overlay.dart';
import '../widgets/stats_card.dart';
import '../widgets/c200_score_card.dart';
import 'c200/c200_overlay_screen.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends StatefulWidget {
  final String? imagePath;
  final List<Impact>? impacts;
  final TargetCalibration? calibration;
  final String? weaponId;
  final String? weaponName;
  final String? weapon; // Deprecated - pour compatibilité
  final double? distance;
  final String? notes;
  final int? sessionId;
  final bool isReadOnly;
  final C200Score? c200Score;

  const ResultsScreen({
    Key? key,
    this.imagePath,
    this.impacts,
    this.calibration,
    this.weaponId,
    this.weaponName,
    this.weapon, // Deprecated
    this.distance,
    this.notes,
    this.sessionId,
    this.isReadOnly = false,
    this.c200Score,
  }) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Session? _session;
  List<Impact> _impacts = [];
  TargetCalibration? _calibration;
  Statistics? _statistics;
  C200Score? _c200Score;
  bool _isLoading = false;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _c200Score = widget.c200Score;
    if (widget.isReadOnly && widget.sessionId != null) {
      _loadSession();
    } else {
      _calculateStatistics();
      _loadImageSize();
    }
  }

  Future<void> _loadImageSize() async {
    if (widget.imagePath == null) return;

    final ImageProvider provider = kIsWeb
        ? (NetworkImage(widget.imagePath!) as ImageProvider)
        : FileImage(File(widget.imagePath!));
    final completer = provider.resolve(const ImageConfiguration());
    completer.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      }
    }));
  }

  Future<void> _loadSession() async {
    setState(() => _isLoading = true);

    final session = await DatabaseHelper.instance.getSession(widget.sessionId!);
    final impacts = await DatabaseHelper.instance.getImpactsForSession(widget.sessionId!);
    final calibration = await DatabaseHelper.instance.getCalibrationForSession(widget.sessionId!);

    if (session != null) {
      final stats = StatisticsCalculator.calculateStatistics(impacts);

      setState(() {
        _session = session;
        _impacts = impacts;
        _calibration = calibration;
        _statistics = stats;
        _isLoading = false;
      });
    }
  }

  void _calculateStatistics() {
    if (widget.impacts != null) {
      final stats = StatisticsCalculator.calculateStatistics(widget.impacts!);

      setState(() {
        _impacts = widget.impacts!;
        _calibration = widget.calibration;
        _statistics = stats;
      });
    }
  }

  Future<void> _addC200Score() async {
    if (_imageSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chargement de l\'image en cours...'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final imagePath = widget.isReadOnly ? _session?.imagePath : widget.imagePath;
    if (imagePath == null) return;

    // Ouvrir l'écran C200 pour positionner l'overlay
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => C200OverlayScreen(
          imagePath: imagePath,
          impacts: _impacts,
          imageSize: _imageSize!,
        ),
      ),
    );

    if (result != null && mounted) {
      final C200Calibration c200Calibration = result['calibration'];
      final C200Score c200Score = result['score'];

      // Mettre à jour la calibration existante avec les données C200
      TargetCalibration? updatedCalibration = _calibration;
      if (updatedCalibration != null) {
        updatedCalibration = TargetCalibration(
          sessionId: updatedCalibration.sessionId,
          centerX: updatedCalibration.centerX,
          centerY: updatedCalibration.centerY,
          radius: updatedCalibration.radius,
          pixelsPerCm: updatedCalibration.pixelsPerCm,
          c200CenterX: c200Calibration.centerX,
          c200CenterY: c200Calibration.centerY,
          c200Scale: c200Calibration.scale,
        );
      } else {
        // Créer une nouvelle calibration avec uniquement les données C200
        updatedCalibration = TargetCalibration(
          sessionId: 0,
          centerX: 0,
          centerY: 0,
          radius: 0,
          pixelsPerCm: 1.0,
          c200CenterX: c200Calibration.centerX,
          c200CenterY: c200Calibration.centerY,
          c200Scale: c200Calibration.scale,
        );
      }

      // Mettre à jour les impacts avec les données C200
      final List<Impact> updatedImpacts = [];
      for (int i = 0; i < _impacts.length; i++) {
        final impact = _impacts[i];
        final impactScore = c200Score.impactScores.firstWhere(
          (score) => score.impactIndex == i,
          orElse: () => c200Score.impactScores[i],
        );

        updatedImpacts.add(Impact(
          id: impact.id,
          sessionId: impact.sessionId,
          x: impact.x,
          y: impact.y,
          isManual: impact.isManual,
          c200Zone: impactScore.zone,
          c200Points: impactScore.points.toDouble(),
          distanceFromCenter: impactScore.distanceFromCenterMm,
        ));
      }

      setState(() {
        _c200Score = c200Score;
        _calibration = updatedCalibration;
        _impacts = updatedImpacts;
      });

      // Si c'est en mode lecture seule (session existante), mettre à jour la base de données
      if (widget.isReadOnly && widget.sessionId != null) {
        await _updateSessionWithC200(c200Score);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Score C200 ajouté avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _updateSessionWithC200(C200Score c200Score) async {
    if (_session == null) return;

    // Créer les détails C200
    final c200Details = {
      'totalScore': c200Score.totalScore,
      'averageScore': c200Score.averageScore,
      'perfectShots': c200Score.perfectShots,
      'totalShots': c200Score.totalShots,
    };

    // Mettre à jour la session
    final updatedSession = Session(
      id: _session!.id,
      date: _session!.date,
      weapon: _session!.weapon,
      distance: _session!.distance,
      shotCount: _session!.shotCount,
      imagePath: _session!.imagePath,
      stdDeviation: _session!.stdDeviation,
      meanRadius: _session!.meanRadius,
      groupCenterX: _session!.groupCenterX,
      groupCenterY: _session!.groupCenterY,
      notes: _session!.notes,
      createdAt: _session!.createdAt,
      c200Score: c200Score.totalScore.toDouble(),
      c200Details: c200Details,
    );

    await DatabaseHelper.instance.updateSession(updatedSession);

    // Mettre à jour les impacts
    for (var impact in _impacts) {
      if (impact.id != null) {
        await DatabaseHelper.instance.updateImpact(impact);
      }
    }

    // Mettre à jour la calibration
    if (_calibration != null) {
      await DatabaseHelper.instance.updateCalibration(_calibration!);
    }
  }

  Future<void> _saveSession() async {
    if (_statistics == null || widget.imagePath == null) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy').format(now);
      final createdAtStr = now.toIso8601String();

      // Créer les détails C200 si disponibles
      Map<String, dynamic>? c200Details;
      if (_c200Score != null) {
        c200Details = {
          'totalScore': _c200Score!.totalScore,
          'averageScore': _c200Score!.averageScore,
          'perfectShots': _c200Score!.perfectShots,
          'totalShots': _c200Score!.totalShots,
        };
      }

      // Créer la session
      final session = Session(
        date: dateStr,
        weaponId: widget.weaponId,
        weaponName: widget.weaponName ?? widget.weapon, // Fallback pour compatibilité
        weapon: widget.weapon, // Deprecated
        distance: widget.distance,
        shotCount: _statistics!.shotCount,
        imagePath: widget.imagePath!,
        stdDeviation: _statistics!.stdDeviation,
        meanRadius: _statistics!.meanRadius,
        groupCenterX: _statistics!.centerX,
        groupCenterY: _statistics!.centerY,
        notes: widget.notes,
        createdAt: createdAtStr,
        c200Score: _c200Score?.totalScore.toDouble(),
        c200Details: c200Details,
      );

      final sessionId = await DatabaseHelper.instance.insertSession(session);

      // Sauvegarder les impacts
      for (var impact in _impacts) {
        final impactWithSession = Impact(
          sessionId: sessionId,
          x: impact.x,
          y: impact.y,
          isManual: impact.isManual,
        );
        await DatabaseHelper.instance.insertImpact(impactWithSession);
      }

      // Sauvegarder la calibration
      if (_calibration != null) {
        final calibrationWithSession = TargetCalibration(
          sessionId: sessionId,
          centerX: _calibration!.centerX,
          centerY: _calibration!.centerY,
          radius: _calibration!.radius,
          pixelsPerCm: _calibration!.pixelsPerCm,
        );
        await DatabaseHelper.instance.insertCalibration(calibrationWithSession);
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session sauvegardée avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Retourner à l'écran d'accueil
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette session ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.sessionId != null) {
      await DatabaseHelper.instance.deleteSession(widget.sessionId!);

      // Supprimer l'image (pas applicable sur web)
      if (!kIsWeb && _session?.imagePath != null) {
        try {
          final file = File(_session!.imagePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Ignorer les erreurs de suppression de fichier
        }
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Résultats'),
          backgroundColor: Colors.orange[800],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final imagePath = widget.isReadOnly ? _session?.imagePath : widget.imagePath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        actions: [
          if (widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Supprimer',
              onPressed: _deleteSession,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image avec impacts
            if (imagePath != null)
              SizedBox(
                height: 300,
                child: ImpactOverlay(
                  imagePath: imagePath,
                  impacts: _impacts,
                  calibration: _calibration,
                  showGroupCenter: true,
                  readOnly: true,
                ),
              ),

            // Score C200 si disponible
            if (_c200Score != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: C200ScoreCard(
                  score: _c200Score!,
                  isCompact: true,
                ),
              ),

            // Bouton pour ajouter C200 si pas encore calculé
            if (_c200Score == null && !widget.isReadOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentPrimary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.stars,
                            color: AppTheme.accentPrimary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Score C200',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Calculez votre score officiel C200',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _addC200Score,
                        icon: const Icon(Icons.add_circle, size: 20),
                        label: const Text(
                          'CALCULER SCORE C200',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bouton pour ajouter/voir C200 en mode lecture seule
            if (widget.isReadOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: OutlinedButton.icon(
                  onPressed: _addC200Score,
                  icon: Icon(
                    _c200Score == null ? Icons.add_circle : Icons.visibility,
                    size: 20,
                  ),
                  label: Text(
                    _c200Score == null ? 'AJOUTER SCORE C200' : 'RECALCULER C200',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ),

            // Statistiques
            if (_statistics != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Statistiques du groupement',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            title: 'Nombre de tirs',
                            value: _statistics!.shotCount.toString(),
                            icon: Icons.circle_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatsCard(
                            title: 'Rayon moyen',
                            value: '${_statistics!.meanRadius.toStringAsFixed(1)} px',
                            icon: Icons.radar,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            title: 'Écart-type',
                            value: '${_statistics!.stdDeviation.toStringAsFixed(1)} px',
                            icon: Icons.show_chart,
                            highlight: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatsCard(
                            title: 'Diamètre',
                            value: '${_statistics!.groupDiameter.toStringAsFixed(1)} px',
                            icon: Icons.straighten,
                          ),
                        ),
                      ],
                    ),

                    // Informations de la session
                    if (widget.weaponName != null || widget.weapon != null || _session?.displayWeaponName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.weaponName != null || widget.weapon != null || _session?.displayWeaponName != null)
                                      _buildInfoRow(
                                        Icons.gps_fixed,
                                        'Arme',
                                        widget.weaponName ?? widget.weapon ?? _session!.displayWeaponName!,
                                      ),
                                    if (widget.distance != null || _session?.distance != null)
                                      _buildInfoRow(
                                        Icons.straighten,
                                        'Distance',
                                        '${widget.distance ?? _session!.distance!} m',
                                      ),
                                    if (_session?.date != null)
                                      _buildInfoRow(
                                        Icons.calendar_today,
                                        'Date',
                                        _session!.date,
                                      ),
                                    if (widget.notes != null || _session?.notes != null)
                                      _buildInfoRow(
                                        Icons.note,
                                        'Notes',
                                        widget.notes ?? _session!.notes!,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: !widget.isReadOnly
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _saveSession,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Enregistrer la session',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
