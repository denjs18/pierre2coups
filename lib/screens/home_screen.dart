import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/session.dart';
import '../theme/app_theme.dart';
import 'capture_screen.dart';
import 'history_screen.dart';
import 'results_screen.dart';
import 'statistics/statistics_screen.dart';
import 'weapons/my_weapons_screen.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Session> _recentSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSessions();
  }

  Future<void> _loadRecentSessions() async {
    setState(() => _isLoading = true);
    final allSessions = await DatabaseHelper.instance.getAllSessions();
    setState(() {
      _recentSessions = allSessions.take(5).toList();
      _isLoading = false;
    });
  }

  void _navigateToCapture() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CaptureScreen()),
    );
    if (result == true) {
      _loadRecentSessions();
    }
  }

  void _navigateToHistory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
    if (result == true) {
      _loadRecentSessions();
    }
  }

  void _navigateToStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatisticsScreen()),
    );
  }

  void _navigateToMyWeapons() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyWeaponsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.accentPrimary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'PIERRE2COUPS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _navigateToStatistics,
            tooltip: 'Statistiques',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToHistory,
            tooltip: 'Historique complet',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecentSessions,
        color: AppTheme.accentPrimary,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentPrimary,
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero section avec le bouton principal
                    _buildHeroSection(),
                    const SizedBox(height: 32),

                    // Stats rapides
                    if (_recentSessions.isNotEmpty) _buildQuickStats(),
                    if (_recentSessions.isNotEmpty) const SizedBox(height: 32),

                    // Sessions récentes
                    _buildRecentSessionsSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentPrimary.withOpacity(0.1),
            AppTheme.backgroundSecondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.gps_fixed,
            size: 64,
            color: AppTheme.accentPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'ANALYSE TACTIQUE',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Détection automatique · Statistiques · Historique',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 0.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCapture,
            icon: const Icon(Icons.add_a_photo, size: 24),
            label: const Text(
              'NOUVELLE SESSION',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _navigateToMyWeapons,
            icon: const Icon(Icons.settings_applications, size: 20),
            label: const Text(
              'MES ARMES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(color: AppTheme.accentPrimary.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalSessions = _recentSessions.length;
    final avgStdDev = _recentSessions
            .where((s) => s.stdDeviation != null)
            .map((s) => s.stdDeviation!)
            .fold(0.0, (a, b) => a + b) /
        _recentSessions.where((s) => s.stdDeviation != null).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              label: 'SESSIONS',
              value: totalSessions.toString(),
              icon: Icons.analytics,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.borderColor,
          ),
          Expanded(
            child: _buildStatItem(
              label: 'PRÉCISION MOY',
              value: avgStdDev.isNaN ? '-' : '${avgStdDev.toStringAsFixed(1)} cm',
              icon: Icons.track_changes,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentPrimary, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.statNumberStyle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.labelStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SESSIONS RÉCENTES',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (_recentSessions.isNotEmpty)
              TextButton.icon(
                onPressed: _navigateToHistory,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('TOUT VOIR'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentPrimary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _recentSessions.isEmpty
            ? _buildEmptyState()
            : Column(
                children: _recentSessions
                    .map((session) => _buildSessionCard(session))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune session',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par créer une nouvelle session',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultsScreen(
                  sessionId: session.id!,
                  isReadOnly: true,
                ),
              ),
            );
            if (result == true) {
              _loadRecentSessions();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image miniature
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: File(session.imagePath).existsSync()
                        ? Image.file(
                            File(session.imagePath),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppTheme.backgroundPrimary,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.weapon ?? 'Arme non spécifiée',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (session.stdDeviation != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: AppTheme.statsBadge(),
                              child: Text(
                                '${session.stdDeviation!.toStringAsFixed(1)} cm',
                                style: const TextStyle(
                                  color: AppTheme.accentPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            session.date,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.gps_fixed,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${session.shotCount} tirs',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (session.distance != null) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.straighten,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${session.distance!.toStringAsFixed(0)}m',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
