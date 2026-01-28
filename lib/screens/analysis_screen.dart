import 'dart:io';
import 'package:flutter/material.dart';
import '../models/impact.dart';
import '../models/target.dart';
import '../models/c200_scoring.dart';
import '../models/weapon.dart';
import '../services/impact_detector.dart';
import '../widgets/impact_overlay.dart';
import '../widgets/weapon_selector.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';
import 'c200/c200_overlay_screen.dart';
import 'weapons/weapon_selection_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final String imagePath;

  const AnalysisScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  List<Impact> _impacts = [];
  TargetCalibration? _calibration;
  bool _isDetecting = false;
  bool _modeSelected = false; // Pour savoir si l'utilisateur a choisi un mode
  String _selectedMode = ''; // 'auto' ou 'manual'
  String _statusMessage = '';
  Size? _imageSize;

  Weapon? _selectedWeapon;
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadImageSize();
    // Ne PAS lancer la détection automatiquement
    // L'utilisateur choisira le mode
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectWeapon() async {
    final weapon = await Navigator.push<Weapon>(
      context,
      MaterialPageRoute(
        builder: (context) => const WeaponSelectionScreen(),
      ),
    );

    if (weapon != null) {
      setState(() => _selectedWeapon = weapon);
    }
  }

  Future<void> _loadImageSize() async {
    final image = Image.file(File(widget.imagePath));
    final completer = image.image.resolve(const ImageConfiguration());
    completer.addListener(ImageStreamListener((info, _) {
      setState(() {
        _imageSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
      });
    }));
  }

  void _selectAutoMode() async {
    setState(() {
      _selectedMode = 'auto';
      _modeSelected = true;
      _isDetecting = true;
      _statusMessage = 'Détection automatique en cours...';
    });

    try {
      final result = await ImpactDetector.detectImpacts(widget.imagePath);

      setState(() {
        _impacts = result.impacts;
        _calibration = result.calibration;
        _statusMessage = result.message;
        _isDetecting = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur: $e';
        _isDetecting = false;
      });
    }
  }

  void _selectManualMode() {
    setState(() {
      _selectedMode = 'manual';
      _modeSelected = true;
      _impacts = [];
      _statusMessage = 'Mode manuel : tapez sur l\'image pour ajouter des impacts';
    });
  }

  void _addImpact(Offset position) {
    setState(() {
      _impacts.add(Impact(
        sessionId: 0,
        x: position.dx,
        y: position.dy,
        isManual: true,
      ));
    });
  }

  void _removeImpact(int index) {
    setState(() {
      _impacts.removeAt(index);
    });
  }

  void _resetDetection() {
    setState(() {
      _modeSelected = false;
      _selectedMode = '';
      _impacts = [];
      _calibration = null;
      _statusMessage = '';
      _isDetecting = false;
    });
  }

  void _validateAndContinue() {
    if (_impacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un impact'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          imagePath: widget.imagePath,
          impacts: _impacts,
          calibration: _calibration,
          weaponId: _selectedWeapon?.id,
          weaponName: _selectedWeapon?.displayName,
          distance: _distanceController.text.isEmpty
              ? null
              : double.tryParse(_distanceController.text),
          notes: _notesController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _calculateWithC200() async {
    if (_impacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un impact'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    if (_imageSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chargement de l\'image en cours...'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // Ouvrir l'écran C200 pour positionner l'overlay
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => C200OverlayScreen(
          imagePath: widget.imagePath,
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
          sessionId: impact.sessionId,
          x: impact.x,
          y: impact.y,
          isManual: impact.isManual,
          c200Zone: impactScore.zone,
          c200Points: impactScore.points.toDouble(),
          distanceFromCenter: impactScore.distanceFromCenterMm,
        ));
      }

      // Naviguer vers ResultsScreen avec les données C200
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            imagePath: widget.imagePath,
            impacts: updatedImpacts,
            calibration: updatedCalibration,
            weaponId: _selectedWeapon?.id,
            weaponName: _selectedWeapon?.displayName,
            distance: _distanceController.text.isEmpty
                ? null
                : double.tryParse(_distanceController.text),
            notes: _notesController.text.trim(),
            c200Score: c200Score,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Analyse des impacts'),
        actions: [
          if (_modeSelected)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetDetection,
              tooltip: 'Recommencer',
            ),
        ],
      ),
      body: !_modeSelected ? _buildModeSelection() : _buildAnalysisView(),
    );
  }

  Widget _buildModeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview de l'image
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Titre
          Text(
            'CHOISISSEZ VOTRE MODE',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Comment souhaitez-vous détecter les impacts ?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Bouton Détection Automatique
          _buildModeCard(
            icon: Icons.auto_awesome,
            title: 'DÉTECTION AUTOMATIQUE',
            description:
                'L\'algorithme détecte automatiquement les impacts sur votre cible',
            color: AppTheme.accentPrimary,
            onTap: _selectAutoMode,
            recommended: true,
          ),
          const SizedBox(height: 16),

          // Bouton Mode Manuel
          _buildModeCard(
            icon: Icons.touch_app,
            title: 'AJOUT MANUEL',
            description:
                'Placez vous-même chaque impact en tapant sur l\'image',
            color: AppTheme.accentSecondary,
            onTap: _selectManualMode,
            recommended: false,
          ),

          const SizedBox(height: 24),

          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.accentPrimary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.accentPrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dans les 2 modes, vous pourrez ajouter ou supprimer des impacts',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required bool recommended,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recommended ? color : AppTheme.borderColor,
          width: recommended ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ),
                              if (recommended)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'RECOMMANDÉ',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: color,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisView() {
    return Column(
      children: [
        // Status bar
        if (_statusMessage.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isDetecting
                ? AppTheme.accentPrimary.withOpacity(0.1)
                : AppTheme.surfaceColor,
            child: Row(
              children: [
                if (_isDetecting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                if (_isDetecting) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                  ),
                ),
                // Compteur d'impacts
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_impacts.length} impact(s)',
                    style: const TextStyle(
                      color: AppTheme.accentPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Image avec overlay
        Expanded(
          child: _isDetecting
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.accentPrimary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Analyse en cours...',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : ImpactOverlay(
                  imagePath: widget.imagePath,
                  impacts: _impacts,
                  onTap: _addImpact,
                  onImpactTap: _removeImpact,
                ),
        ),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.backgroundSecondary,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInstructionChip(
                    icon: Icons.add_circle_outline,
                    text: 'Tap sur l\'image = Ajouter',
                    color: AppTheme.accentPrimary,
                  ),
                  _buildInstructionChip(
                    icon: Icons.remove_circle_outline,
                    text: 'Tap sur un point = Supprimer',
                    color: AppTheme.accentSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Formulaire
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
              children: [
                Text(
                  'INFORMATIONS DE LA SESSION',
                  style: AppTheme.labelStyle.copyWith(
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                // Sélecteur d'arme
                Text(
                  'ARME',
                  style: AppTheme.labelStyle.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 8),
                WeaponSelector(
                  selectedWeapon: _selectedWeapon,
                  onTap: _selectWeapon,
                ),
                const SizedBox(height: 16),
                // Distance
                Text(
                  'DISTANCE (OPTIONNEL)',
                  style: AppTheme.labelStyle.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _distanceController,
                  decoration: const InputDecoration(
                    hintText: 'Distance en mètres',
                    prefixIcon: Icon(Icons.straighten, size: 20),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Bouton C200 (recommandé)
                ElevatedButton.icon(
                  onPressed: _impacts.isEmpty ? null : _calculateWithC200,
                  icon: const Icon(Icons.stars),
                  label: const Text(
                    'CALCULER AVEC SCORE C200',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 8),
                // Bouton standard
                OutlinedButton.icon(
                  onPressed: _impacts.isEmpty ? null : _validateAndContinue,
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text(
                    'Continuer sans C200',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}
