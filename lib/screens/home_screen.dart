import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/session.dart';
import '../services/firebase_auth_service.dart';
import '../theme/app_theme.dart';
import 'auth/welcome_screen.dart';
import 'capture_screen.dart';
import 'history_screen.dart';
import 'results_screen.dart';
import 'statistics/statistics_screen.dart';
import 'weapons/my_weapons_screen.dart';
import 'workshop/workshop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Session> _recentSessions = [];
  List<Session> _allSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final allSessions = await DatabaseHelper.instance.getAllSessions();
    setState(() {
      _allSessions = allSessions;
      _recentSessions = allSessions.take(5).toList();
      _isLoading = false;
    });
  }

  void _navigateToCapture() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CaptureScreen()),
    );
    if (result == true) _loadSessions();
  }

  void _navigateToHistory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
    if (result == true) _loadSessions();
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

  void _navigateToWorkshop() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkshopScreen()),
    );
    _loadSessions();
  }

  Future<void> _handleLogout() async {
    final authService = Provider.of<FirebaseAuthService>(context, listen: false);
    try {
      await authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur déconnexion: $e')),
      );
    }
  }

  // Statistiques calculées
  int get _totalSessions => _allSessions.length;

  double? get _avgPrecision {
    final withDev = _allSessions.where((s) => s.stdDeviation != null).toList();
    if (withDev.isEmpty) return null;
    return withDev.map((s) => s.stdDeviation!).reduce((a, b) => a + b) /
        withDev.length;
  }

  double? get _bestSession {
    final withDev = _allSessions.where((s) => s.stdDeviation != null).toList();
    if (withDev.isEmpty) return null;
    return withDev.map((s) => s.stdDeviation!).reduce((a, b) => a < b ? a : b);
  }

  int get _activeWeapons {
    return _allSessions
        .map((s) => s.displayWeaponName ?? '')
        .where((w) => w.isNotEmpty)
        .toSet()
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<FirebaseAuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final isGuest = currentUser == null;
    final agentLabel = isGuest
        ? 'INVITÉ'
        : (currentUser.firstName?.isNotEmpty == true
            ? currentUser.firstName!.toUpperCase()
            : currentUser.email.split('@').first.toUpperCase());

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPrimary,
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
            const SizedBox(width: 10),
            const Text(
              'PIERRE2COUPS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Icône stats
          IconButton(
            icon: const Icon(Icons.bar_chart, color: AppTheme.textSecondary),
            onPressed: _navigateToStatistics,
            tooltip: 'Statistiques',
          ),
          // Avatar/déconnexion
          if (!isGuest)
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline,
                        color: AppTheme.accentPrimary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      agentLabel,
                      style: const TextStyle(
                        color: AppTheme.accentPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              color: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: AppTheme.accentDanger, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'DÉCONNEXION',
                        style: TextStyle(
                          color: AppTheme.accentDanger,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'logout') _handleLogout();
              },
            )
          else
            // Bouton pour quitter le mode invité
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WelcomeScreen()),
                );
              },
              child: const Text(
                'CONNEXION',
                style: TextStyle(
                  color: AppTheme.accentPrimary,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSessions,
        color: AppTheme.accentPrimary,
        backgroundColor: AppTheme.surfaceColor,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accentPrimary),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Briefing Mission
                    _buildBriefingSection(agentLabel),
                    const SizedBox(height: 20),

                    // 4 tuiles stats
                    _buildStatsGrid(),
                    const SizedBox(height: 20),

                    // Dernières opérations
                    _buildRecentOperations(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBriefingSection(String agentLabel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentPrimary.withOpacity(0.08),
            AppTheme.backgroundSecondary,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentPrimary.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête briefing
          Row(
            children: [
              const Icon(Icons.gps_fixed, color: AppTheme.accentPrimary, size: 16),
              const SizedBox(width: 8),
              const Text(
                'BRIEFING MISSION',
                style: TextStyle(
                  color: AppTheme.accentPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: AppTheme.missionBadge(AppTheme.accentPrimary),
                child: const Text(
                  '◉ PRÊT POUR MISSION',
                  style: TextStyle(
                    color: AppTheme.accentPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ligne de statut agent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                _buildStatusChip('AGENT', agentLabel),
                _buildStatusDivider(),
                _buildStatusChip('SESSIONS', '$_totalSessions'),
                _buildStatusDivider(),
                _buildStatusChip(
                  'PRÉCISION',
                  _avgPrecision != null
                      ? '${_avgPrecision!.toStringAsFixed(1)} cm'
                      : 'N/A',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bouton Nouvelle Mission
          ElevatedButton.icon(
            onPressed: _navigateToCapture,
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text(
              '⊕ NOUVELLE MISSION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: AppTheme.backgroundPrimary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 10),

          // Boutons Arsenal + Atelier côte à côte
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigateToMyWeapons,
                  icon: const Icon(Icons.settings_applications_outlined, size: 16),
                  label: const Text(
                    '◈ ARSENAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentPrimary,
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: AppTheme.accentPrimary, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigateToWorkshop,
                  icon: const Icon(Icons.construction_outlined, size: 16),
                  label: const Text(
                    '⚙ ATELIER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentSecondary,
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: AppTheme.accentSecondary, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppTheme.borderColor,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildStatTile(
          label: 'SESSIONS TOTALES',
          value: '$_totalSessions',
          icon: Icons.analytics_outlined,
          color: AppTheme.accentPrimary,
        ),
        _buildStatTile(
          label: 'PRÉCISION MOY',
          value: _avgPrecision != null
              ? '${_avgPrecision!.toStringAsFixed(1)} cm'
              : '—',
          icon: Icons.track_changes_outlined,
          color: AppTheme.accentSecondary,
        ),
        _buildStatTile(
          label: 'MEILLEURE SESSION',
          value: _bestSession != null
              ? '${_bestSession!.toStringAsFixed(1)} cm'
              : '—',
          icon: Icons.military_tech_outlined,
          color: AppTheme.accentPrimary,
        ),
        _buildStatTile(
          label: 'ARMES ACTIVES',
          value: '$_activeWeapons',
          icon: Icons.settings_applications_outlined,
          color: AppTheme.accentSecondary,
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOperations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DERNIÈRES OPÉRATIONS',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            if (_recentSessions.isNotEmpty)
              TextButton(
                onPressed: _navigateToHistory,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentPrimary,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'TOUT VOIR ›',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Container(height: 1, color: AppTheme.borderColor),
        const SizedBox(height: 12),

        _recentSessions.isEmpty
            ? _buildEmptyState()
            : Column(
                children: _recentSessions
                    .map((session) => _buildOperationCard(session))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 48,
            color: AppTheme.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'AUCUNE OPÉRATION',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Commencez par créer une nouvelle mission',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOperationCard(Session session) {
    // Indicateur de précision selon stdDeviation
    Color precisionColor;
    String precisionLabel;
    if (session.stdDeviation == null) {
      precisionColor = AppTheme.textSecondary;
      precisionLabel = 'N/A';
    } else if (session.stdDeviation! <= 5) {
      precisionColor = AppTheme.accentPrimary;
      precisionLabel = 'EXCELLENT';
    } else if (session.stdDeviation! <= 10) {
      precisionColor = AppTheme.accentSecondary;
      precisionLabel = 'BON';
    } else {
      precisionColor = AppTheme.accentDanger;
      precisionLabel = 'À AMÉLIORER';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
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
            if (result == true) _loadSessions();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Miniature
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: _buildSessionThumbnail(session.imagePath),
                  ),
                ),
                const SizedBox(width: 14),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arme + badge précision
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.displayWeaponName ?? 'Arme non spécifiée',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: AppTheme.missionBadge(precisionColor),
                            child: Text(
                              precisionLabel,
                              style: TextStyle(
                                color: precisionColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Rapport militaire: date / distance / tirs / score
                      _buildReportLine(session, precisionColor),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.borderColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportLine(Session session, Color precisionColor) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _buildReportChip(Icons.calendar_today_outlined, session.date, AppTheme.textSecondary),
        _buildReportChip(Icons.gps_fixed, '${session.shotCount} tirs', AppTheme.textSecondary),
        if (session.distance != null)
          _buildReportChip(Icons.straighten_outlined,
              '${session.distance!.toStringAsFixed(0)}m', AppTheme.textSecondary),
        if (session.stdDeviation != null)
          _buildReportChip(Icons.track_changes_outlined,
              '${session.stdDeviation!.toStringAsFixed(1)} cm', precisionColor),
      ],
    );
  }

  Widget _buildReportChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionThumbnail(String imagePath) {
    if (kIsWeb) {
      return Container(
        color: AppTheme.backgroundPrimary,
        child: const Icon(Icons.image_outlined, color: AppTheme.textSecondary, size: 20),
      );
    }
    final file = File(imagePath);
    return file.existsSync()
        ? Image.file(file, fit: BoxFit.cover)
        : Container(
            color: AppTheme.backgroundPrimary,
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          );
  }
}
