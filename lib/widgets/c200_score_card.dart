import 'package:flutter/material.dart';
import '../models/c200_scoring.dart';
import '../services/c200_calculator.dart';
import '../theme/app_theme.dart';

class C200ScoreCard extends StatelessWidget {
  final C200Score score;
  final bool isCompact;

  const C200ScoreCard({
    Key? key,
    required this.score,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactView(context);
    }
    return _buildFullView(context);
  }

  Widget _buildCompactView(BuildContext context) {
    final accuracy =
        C200Calculator.calculateAccuracyPercentage(score.totalScore, score.totalShots);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Score total
          Expanded(
            child: Column(
              children: [
                Text(
                  '${score.totalScore}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '/${C200Calculator.calculateMaxScore(score.totalShots)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SCORE C200',
                  style: AppTheme.labelStyle,
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 60,
            color: AppTheme.borderColor,
          ),

          // Précision
          Expanded(
            child: Column(
              children: [
                Text(
                  '${accuracy.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PRÉCISION',
                  style: AppTheme.labelStyle,
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 60,
            color: AppTheme.borderColor,
          ),

          // Tirs parfaits
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.stars,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${score.perfectShots}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'PARFAITS',
                  style: AppTheme.labelStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView(BuildContext context) {
    final accuracy =
        C200Calculator.calculateAccuracyPercentage(score.totalScore, score.totalShots);
    final advancedStats = C200Calculator.calculateAdvancedStats(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            children: [
              Icon(
                Icons.stars,
                color: AppTheme.accentPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'SCORE C200',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scores principaux
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  label: 'SCORE TOTAL',
                  value: '${score.totalScore}',
                  subtitle: '/${C200Calculator.calculateMaxScore(score.totalShots)}',
                  color: AppTheme.accentPrimary,
                  icon: Icons.emoji_events,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  label: 'MOYENNE',
                  value: score.averageScore.toStringAsFixed(2),
                  subtitle: 'points/tir',
                  color: AppTheme.accentSecondary,
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  label: 'PRÉCISION',
                  value: '${accuracy.toStringAsFixed(1)}%',
                  subtitle: 'du max',
                  color: Colors.blue,
                  icon: Icons.adjust,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  label: 'PARFAITS (10)',
                  value: '${score.perfectShots}',
                  subtitle: '/${score.totalShots} tirs',
                  color: Colors.amber,
                  icon: Icons.star,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: AppTheme.borderColor),
          const SizedBox(height: 20),

          // Statistiques avancées
          Text(
            'STATISTIQUES AVANCÉES',
            style: AppTheme.labelStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 12),

          _buildAdvancedStatRow(
            'Distance moyenne du centre',
            '${advancedStats['meanDistance'].toStringAsFixed(1)} mm',
            Icons.center_focus_weak,
          ),
          const SizedBox(height: 8),
          _buildAdvancedStatRow(
            'Distance médiane',
            '${advancedStats['medianDistance'].toStringAsFixed(1)} mm',
            Icons.more_horiz,
          ),
          const SizedBox(height: 8),
          _buildAdvancedStatRow(
            'Écart-type',
            '${advancedStats['stdDeviation'].toStringAsFixed(1)} mm',
            Icons.show_chart,
          ),
          const SizedBox(height: 8),
          _buildAdvancedStatRow(
            'Indice de consistance',
            '${advancedStats['consistency'].toStringAsFixed(0)}/100',
            Icons.psychology,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.labelStyle.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
