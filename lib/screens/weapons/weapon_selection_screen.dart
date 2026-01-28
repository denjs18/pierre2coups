import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/weapon.dart';
import '../../theme/app_theme.dart';
import 'create_weapon_screen.dart';

class WeaponSelectionScreen extends StatefulWidget {
  const WeaponSelectionScreen({Key? key}) : super(key: key);

  @override
  State<WeaponSelectionScreen> createState() => _WeaponSelectionScreenState();
}

class _WeaponSelectionScreenState extends State<WeaponSelectionScreen> {
  final _searchController = TextEditingController();
  List<Weapon> _weapons = [];
  List<Weapon> _filteredWeapons = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWeapons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWeapons() async {
    setState(() => _isLoading = true);

    try {
      final weaponsData = await DatabaseHelper.instance.searchWeaponsLocal('');
      final weapons = weaponsData.map((data) => Weapon.fromMap(data)).toList();

      setState(() {
        _weapons = weapons;
        _filteredWeapons = weapons;
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

  void _filterWeapons(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredWeapons = _weapons;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredWeapons = _weapons.where((weapon) {
          final name = weapon.name.toLowerCase();
          final manufacturer = weapon.manufacturer?.toLowerCase() ?? '';
          final model = weapon.model?.toLowerCase() ?? '';
          final caliber = weapon.caliber?.toLowerCase() ?? '';
          return name.contains(lowerQuery) ||
              manufacturer.contains(lowerQuery) ||
              model.contains(lowerQuery) ||
              caliber.contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> _createNewWeapon() async {
    final weapon = await Navigator.push<Weapon>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWeaponScreen(
          initialSearchQuery: _searchQuery,
        ),
      ),
    );

    if (weapon != null) {
      // Recharger la liste
      await _loadWeapons();
      // Retourner l'arme créée
      if (mounted) {
        Navigator.pop(context, weapon);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('SÉLECTIONNER UNE ARME'),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une arme...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _filterWeapons('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _filterWeapons,
                ),
                const SizedBox(height: 12),
                // Bouton créer nouvelle arme
                OutlinedButton.icon(
                  onPressed: _createNewWeapon,
                  icon: const Icon(Icons.add_circle, size: 20),
                  label: Text(
                    _searchQuery.isEmpty
                        ? 'CRÉER UNE NOUVELLE ARME'
                        : 'CRÉER "${_searchQuery.toUpperCase()}"',
                    style: const TextStyle(
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

          // Liste des armes
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentPrimary,
                    ),
                  )
                : _filteredWeapons.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredWeapons.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final weapon = _filteredWeapons[index];
                          return _buildWeaponCard(weapon);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.gps_fixed : Icons.search_off,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucune arme enregistrée'
                  : 'Aucun résultat pour "$_searchQuery"',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Créez votre première arme pour commencer'
                  : 'Essayez un autre terme ou créez cette arme',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewWeapon,
              icon: const Icon(Icons.add_circle),
              label: const Text(
                'CRÉER UNE ARME',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeaponCard(Weapon weapon) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context, weapon),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône de catégorie
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(weapon.category),
                    color: AppTheme.accentPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Informations de l'arme
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weapon.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weapon.displayDetails,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (weapon.usageCount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 14,
                              color: AppTheme.textSecondary.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${weapon.usageCount} utilisation(s)',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    AppTheme.textSecondary.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Flèche
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.accentPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pistolet':
      case 'Arme de poing':
        return Icons.gps_fixed;
      case 'Revolver':
        return Icons.album;
      case 'Carabine':
      case 'Fusil':
      case 'Arme longue':
        return Icons.architecture;
      default:
        return Icons.category;
    }
  }
}
