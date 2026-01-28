import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/session.dart';
import '../../theme/app_theme.dart';
import '../results_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Session> _allSessions = [];
  bool _isLoading = false;

  // Statistiques calculées
  Map<String, dynamic> _overallStats = {};
  Map<String, List<Session>> _sessionsByWeapon = {};
  Map<String, List<Session>> _sessionsByDistance = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final sessions = await DatabaseHelper.instance.getAllSessions();

      // Grouper par arme
      final Map<String, List<Session>> byWeapon = {};
      for (var session in sessions) {
        final weaponName = session.displayWeaponName ?? 'Sans arme';
        byWeapon[weaponName] = [...(byWeapon[weaponName] ?? []), session];
      }

      // Grouper par distance
      final Map<String, List<Session>> byDistance = {};
      for (var session in sessions) {
        if (session.distance != null) {
          final distanceKey = '${session.distance!.toInt()}m';
          byDistance[distanceKey] = [
            ...(byDistance[distanceKey] ?? []),
            session
          ];
        }
      }

      // Calculer stats globales
      final stats = _calculateOverallStats(sessions);

      setState(() {
        _allSessions = sessions;
        _sessionsByWeapon = byWeapon;
        _sessionsByDistance = byDistance;
        _overallStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _calculateOverallStats(List<Session> sessions) {
    if (sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'totalShots': 0,
        'averageStdDev': 0.0,
        'bestStdDev': 0.0,
        'bestSession': null,
        'totalC200Sessions': 0,
        'averageC200Score': 0.0,
        'bestC200Score': 0,
        'bestC200Session': null,
      };
    }

    // Stats groupement standard
    final totalShots = sessions.fold<int>(0, (sum, s) => sum + s.shotCount);
    final validStdDevs =
        sessions.where((s) => s.stdDeviation != null).toList();
    final averageStdDev = validStdDevs.isEmpty
        ? 0.0
        : validStdDevs.fold<double>(0, (sum, s) => sum + s.stdDeviation!) /
            validStdDevs.length;
    final bestStdDevSession =
        validStdDevs.isEmpty ? null : (validStdDevs..sort((a, b) => a.stdDeviation!.compareTo(b.stdDeviation!))).first;

    // Stats C200
    final c200Sessions = sessions.where((s) => s.c200Score != null).toList();
    final totalC200Sessions = c200Sessions.length;
    final averageC200Score = c200Sessions.isEmpty
        ? 0.0
        : c200Sessions.fold<double>(0, (sum, s) => sum + s.c200Score!) /
            c200Sessions.length;
    final bestC200Session = c200Sessions.isEmpty
        ? null
        : (c200Sessions..sort((a, b) => b.c200Score!.compareTo(a.c200Score!))).first;

    return {
      'totalSessions': sessions.length,
      'totalShots': totalShots,
      'averageStdDev': averageStdDev,
      'bestStdDev': bestStdDevSession?.stdDeviation ?? 0.0,
      'bestSession': bestStdDevSession,
      'totalC200Sessions': totalC200Sessions,
      'averageC200Score': averageC200Score,
      'bestC200Score': bestC200Session?.c200Score?.toInt() ?? 0,
      'bestC200Session': bestC200Session,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('STATISTIQUES'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentPrimary,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'VUE D\'ENSEMBLE'),
            Tab(text: 'PAR ARME'),
            Tab(text: 'PAR DISTANCE'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentPrimary,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildWeaponTab(),
                _buildDistanceTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_allSessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bar_chart,
        title: 'Aucune session enregistrée',
        subtitle: 'Commencez à analyser vos tirs pour voir vos statistiques',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card sessions totales
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentPrimary,
                AppTheme.accentPrimary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBigStat(
                    '${_overallStats['totalSessions']}',
                    'SESSIONS',
                    Icons.folder,
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildBigStat(
                    '${_overallStats['totalShots']}',
                    'TIRS',
                    Icons.circle_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats groupement
        const Text(
          'GROUPEMENT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Écart-type moyen',
                '${_overallStats['averageStdDev'].toStringAsFixed(1)} px',
                Icons.show_chart,
                AppTheme.accentSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Meilleur groupement',
                '${_overallStats['bestStdDev'].toStringAsFixed(1)} px',
                Icons.emoji_events,
                Colors.amber,
              ),
            ),
          ],
        ),

        // Stats C200 si disponibles
        if (_overallStats['totalC200Sessions'] > 0) ...[
          const SizedBox(height: 24),
          const Text(
            'SCORE C200',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Sessions C200',
                  '${_overallStats['totalC200Sessions']}',
                  Icons.stars,
                  AppTheme.accentPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Score moyen',
                  _overallStats['averageC200Score'].toStringAsFixed(1),
                  Icons.trending_up,
                  AppTheme.accentSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Meilleur score C200',
            '${_overallStats['bestC200Score']} points',
            Icons.emoji_events,
            Colors.amber,
            fullWidth: true,
          ),
        ],

        // Meilleure session
        if (_overallStats['bestSession'] != null) ...[
          const SizedBox(height: 24),
          const Text(
            'MEILLEURE SESSION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildSessionCard(_overallStats['bestSession']),
        ],

        // Meilleure session C200
        if (_overallStats['bestC200Session'] != null &&
            _overallStats['bestC200Session'] != _overallStats['bestSession']) ...[
          const SizedBox(height: 16),
          _buildSessionCard(_overallStats['bestC200Session']),
        ],
      ],
    );
  }

  Widget _buildWeaponTab() {
    if (_sessionsByWeapon.isEmpty) {
      return _buildEmptyState(
        icon: Icons.gps_fixed,
        title: 'Aucune arme enregistrée',
        subtitle: 'Enregistrez vos sessions avec une arme pour voir les stats',
      );
    }

    final sortedWeapons = _sessionsByWeapon.keys.toList()
      ..sort((a, b) => _sessionsByWeapon[b]!.length.compareTo(_sessionsByWeapon[a]!.length));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedWeapons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final weaponName = sortedWeapons[index];
        final sessions = _sessionsByWeapon[weaponName]!;
        return _buildWeaponStatCard(weaponName, sessions);
      },
    );
  }

  Widget _buildDistanceTab() {
    if (_sessionsByDistance.isEmpty) {
      return _buildEmptyState(
        icon: Icons.straighten,
        title: 'Aucune distance enregistrée',
        subtitle: 'Renseignez la distance dans vos sessions pour voir les stats',
      );
    }

    final sortedDistances = _sessionsByDistance.keys.toList()
      ..sort((a, b) {
        final aNum = int.parse(a.replaceAll('m', ''));
        final bNum = int.parse(b.replaceAll('m', ''));
        return aNum.compareTo(bNum);
      });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDistances.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final distance = sortedDistances[index];
        final sessions = _sessionsByDistance[distance]!;
        return _buildDistanceStatCard(distance, sessions);
      },
    );
  }

  Widget _buildBigStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentPrimary.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultsScreen(
                  sessionId: session.id,
                  isReadOnly: true,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session.displayWeaponName ?? 'Session',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.accentPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (session.c200Score != null)
                      Expanded(
                        child: _buildSessionStat(
                          'Score C200',
                          '${session.c200Score!.toInt()}',
                        ),
                      ),
                    if (session.stdDeviation != null)
                      Expanded(
                        child: _buildSessionStat(
                          'Écart-type',
                          '${session.stdDeviation!.toStringAsFixed(1)} px',
                        ),
                      ),
                    Expanded(
                      child: _buildSessionStat(
                        'Tirs',
                        '${session.shotCount}',
                      ),
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

  Widget _buildSessionStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.accentPrimary,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWeaponStatCard(String weaponName, List<Session> sessions) {
    final avgStdDev = sessions
            .where((s) => s.stdDeviation != null)
            .fold<double>(0, (sum, s) => sum + s.stdDeviation!) /
        sessions.where((s) => s.stdDeviation != null).length;

    final c200Sessions = sessions.where((s) => s.c200Score != null).toList();
    final avgC200 = c200Sessions.isEmpty
        ? null
        : c200Sessions.fold<double>(0, (sum, s) => sum + s.c200Score!) /
            c200Sessions.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.gps_fixed,
                  color: AppTheme.accentPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  weaponName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sessions.length} sessions',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Écart-type moyen',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${avgStdDev.toStringAsFixed(1)} px',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              if (avgC200 != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score C200 moyen',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        avgC200.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceStatCard(String distance, List<Session> sessions) {
    final avgStdDev = sessions
            .where((s) => s.stdDeviation != null)
            .fold<double>(0, (sum, s) => sum + s.stdDeviation!) /
        sessions.where((s) => s.stdDeviation != null).length;

    final c200Sessions = sessions.where((s) => s.c200Score != null).toList();
    final avgC200 = c200Sessions.isEmpty
        ? null
        : c200Sessions.fold<double>(0, (sum, s) => sum + s.c200Score!) /
            c200Sessions.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentSecondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.straighten,
                  color: AppTheme.accentSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  distance,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sessions.length} sessions',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Écart-type moyen',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${avgStdDev.toStringAsFixed(1)} px',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              if (avgC200 != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score C200 moyen',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        avgC200.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
