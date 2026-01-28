import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/session.dart';
import '../widgets/session_list_item.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Session> _allSessions = [];
  List<Session> _filteredSessions = [];
  bool _isLoading = true;

  // Filtres
  String? _selectedWeapon;
  String? _selectedDistance;
  bool _onlyC200 = false;
  String _sortBy = 'date'; // date, score, c200

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final sessions = await DatabaseHelper.instance.getAllSessions();
    setState(() {
      _allSessions = sessions;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    var filtered = List<Session>.from(_allSessions);

    // Filtre par arme
    if (_selectedWeapon != null) {
      filtered = filtered
          .where((s) => s.displayWeaponName == _selectedWeapon)
          .toList();
    }

    // Filtre par distance
    if (_selectedDistance != null) {
      final distance = double.parse(_selectedDistance!.replaceAll('m', ''));
      filtered = filtered.where((s) => s.distance == distance).toList();
    }

    // Filtre C200 uniquement
    if (_onlyC200) {
      filtered = filtered.where((s) => s.c200Score != null).toList();
    }

    // Tri
    switch (_sortBy) {
      case 'date':
        // Déjà trié par date (plus récent en premier)
        break;
      case 'score':
        filtered.sort((a, b) {
          final aScore = a.stdDeviation ?? double.maxFinite;
          final bScore = b.stdDeviation ?? double.maxFinite;
          return aScore.compareTo(bScore); // Meilleur score = plus petit écart-type
        });
        break;
      case 'c200':
        filtered = filtered.where((s) => s.c200Score != null).toList();
        filtered.sort((a, b) => b.c200Score!.compareTo(a.c200Score!));
        break;
    }

    setState(() {
      _filteredSessions = filtered;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedWeapon = null;
      _selectedDistance = null;
      _onlyC200 = false;
      _sortBy = 'date';
      _applyFilters();
    });
  }

  void _navigateToSession(Session session) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          sessionId: session.id!,
          isReadOnly: true,
        ),
      ),
    );
    _loadSessions();
  }

  List<String> get _availableWeapons {
    final weapons = _allSessions
        .map((s) => s.displayWeaponName)
        .where((w) => w != null)
        .toSet()
        .toList();
    weapons.sort();
    return weapons.cast<String>();
  }

  List<String> get _availableDistances {
    final distances = _allSessions
        .where((s) => s.distance != null)
        .map((s) => '${s.distance!.toInt()}m')
        .toSet()
        .toList();
    distances.sort((a, b) {
      final aNum = int.parse(a.replaceAll('m', ''));
      final bNum = int.parse(b.replaceAll('m', ''));
      return aNum.compareTo(bNum);
    });
    return distances;
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _selectedWeapon != null ||
        _selectedDistance != null ||
        _onlyC200 ||
        _sortBy != 'date';

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('HISTORIQUE'),
        actions: [
          if (hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _resetFilters,
              tooltip: 'Réinitialiser les filtres',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Trier par',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: _sortBy == 'date'
                          ? AppTheme.accentPrimary
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text('Date (plus récent)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'score',
                child: Row(
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 18,
                      color: _sortBy == 'score'
                          ? AppTheme.accentPrimary
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text('Meilleur groupement'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'c200',
                child: Row(
                  children: [
                    Icon(
                      Icons.stars,
                      size: 18,
                      color: _sortBy == 'c200'
                          ? AppTheme.accentPrimary
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text('Meilleur score C200'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentPrimary,
              ),
            )
          : Column(
              children: [
                // Barre de filtres
                _buildFilterBar(),

                // Liste des sessions
                Expanded(
                  child: _filteredSessions.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadSessions,
                          color: AppTheme.accentPrimary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredSessions.length,
                            itemBuilder: (context, index) {
                              final session = _filteredSessions[index];
                              return SessionListItem(
                                session: session,
                                onTap: () => _navigateToSession(session),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    if (_allSessions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne 1: Arme et Distance
          Row(
            children: [
              // Filtre par arme
              if (_availableWeapons.isNotEmpty)
                Expanded(
                  child: _buildFilterChip(
                    label: _selectedWeapon ?? 'Toutes les armes',
                    icon: Icons.gps_fixed,
                    isActive: _selectedWeapon != null,
                    onTap: () => _showWeaponFilter(),
                  ),
                ),
              const SizedBox(width: 8),

              // Filtre par distance
              if (_availableDistances.isNotEmpty)
                Expanded(
                  child: _buildFilterChip(
                    label: _selectedDistance ?? 'Toutes distances',
                    icon: Icons.straighten,
                    isActive: _selectedDistance != null,
                    onTap: () => _showDistanceFilter(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Ligne 2: C200 uniquement
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _onlyC200 = !_onlyC200;
                      _applyFilters();
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _onlyC200
                          ? AppTheme.accentPrimary.withOpacity(0.15)
                          : AppTheme.backgroundSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _onlyC200
                            ? AppTheme.accentPrimary
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _onlyC200 ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 18,
                          color: _onlyC200
                              ? AppTheme.accentPrimary
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sessions C200 uniquement',
                          style: TextStyle(
                            fontSize: 13,
                            color: _onlyC200
                                ? AppTheme.accentPrimary
                                : AppTheme.textSecondary,
                            fontWeight:
                                _onlyC200 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Compteur
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_filteredSessions.length} session(s)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accentPrimary.withOpacity(0.15)
              : AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppTheme.accentPrimary : AppTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.accentPrimary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isActive ? AppTheme.accentPrimary : AppTheme.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.close,
                size: 14,
                color: AppTheme.accentPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showWeaponFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Filtrer par arme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedWeapon != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedWeapon = null;
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Effacer'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...List.generate(
                _availableWeapons.length,
                (index) {
                  final weapon = _availableWeapons[index];
                  final isSelected = weapon == _selectedWeapon;
                  return ListTile(
                    leading: Icon(
                      Icons.gps_fixed,
                      color: isSelected
                          ? AppTheme.accentPrimary
                          : AppTheme.textSecondary,
                    ),
                    title: Text(
                      weapon,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.accentPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppTheme.accentPrimary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedWeapon = weapon;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showDistanceFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Filtrer par distance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedDistance != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDistance = null;
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Effacer'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...List.generate(
                _availableDistances.length,
                (index) {
                  final distance = _availableDistances[index];
                  final isSelected = distance == _selectedDistance;
                  return ListTile(
                    leading: Icon(
                      Icons.straighten,
                      color: isSelected
                          ? AppTheme.accentPrimary
                          : AppTheme.textSecondary,
                    ),
                    title: Text(
                      distance,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.accentPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppTheme.accentPrimary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedDistance = distance;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _selectedWeapon != null ||
        _selectedDistance != null ||
        _onlyC200;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.filter_list_off : Icons.history,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'Aucune session trouvée'
                  : 'Aucune session enregistrée',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Essayez de modifier les filtres'
                  : 'Créez votre première session pour commencer',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('RÉINITIALISER LES FILTRES'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
