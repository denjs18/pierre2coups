import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Stack(
        children: [
          // Fond camouflage
          Positioned.fill(
            child: CustomPaint(
              painter: _CamoPainter(),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // Header - logo + titre
                  _buildHeader(context),

                  const SizedBox(height: 40),

                  // Capacités opérationnelles
                  _buildCapabilities(context),

                  const Spacer(flex: 3),

                  // Boutons d'action
                  _buildActionButtons(context),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Icône viseur avec cercles
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentPrimary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentPrimary.withOpacity(0.6),
                    width: 1,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentPrimary,
                    width: 2,
                  ),
                  color: AppTheme.accentPrimary.withOpacity(0.1),
                ),
              ),
              const Icon(
                Icons.gps_fixed,
                size: 24,
                color: AppTheme.accentPrimary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Titre avec style militaire
        const Text(
          'OPÉRATION',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'PIERRE2COUPS',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Badge "SYSTÈME ACTIF"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.accentPrimary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppTheme.accentPrimary.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: const Text(
            '◉ SYSTÈME ACTIF',
            style: TextStyle(
              color: AppTheme.accentPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapabilities(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CAPACITÉS OPÉRATIONNELLES',
            style: TextStyle(
              color: AppTheme.accentPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _buildCapabilityItem(
            Icons.cloud_sync_outlined,
            'SYNC CLOUD',
            'Sauvegarde sécurisée de toutes vos opérations',
          ),
          const SizedBox(height: 12),
          _buildCapabilityItem(
            Icons.analytics_outlined,
            'ANALYSE TACTIQUE',
            'Détection auto • Statistiques • Rapport C200',
          ),
          const SizedBox(height: 12),
          _buildCapabilityItem(
            Icons.military_tech_outlined,
            'ARSENAL',
            'Gérez vos armes et suivez leurs performances',
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentPrimary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppTheme.accentPrimary.withOpacity(0.3),
            ),
          ),
          child: Icon(icon, color: AppTheme.accentPrimary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bouton principal - Initier compte
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignupScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentPrimary,
            foregroundColor: AppTheme.backgroundPrimary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            elevation: 0,
          ),
          child: const Text(
            '⊕ INITIER COMPTE',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Bouton secondaire - Se connecter
        OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textPrimary,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: AppTheme.borderColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            '≡ SE CONNECTER',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Mode invité
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
          ),
          child: const Text(
            'MODE INVITÉ — SANS COMPTE',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter pour fond camouflage militaire
class _CamoPainter extends CustomPainter {
  final Random _rng = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFF1F2416),
      const Color(0xFF2A3020),
      const Color(0xFF222818),
      const Color(0xFF1C201A),
    ];

    for (int i = 0; i < 40; i++) {
      final color = colors[i % colors.length];
      final paint = Paint()..color = color;

      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      final w = 40.0 + _rng.nextDouble() * 120;
      final h = 20.0 + _rng.nextDouble() * 60;

      final path = Path();
      path.moveTo(x, y);
      path.cubicTo(
        x + w * 0.3, y - h * 0.5,
        x + w * 0.7, y - h * 0.3,
        x + w, y,
      );
      path.cubicTo(
        x + w * 0.8, y + h * 0.6,
        x + w * 0.2, y + h * 0.8,
        x, y,
      );
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
