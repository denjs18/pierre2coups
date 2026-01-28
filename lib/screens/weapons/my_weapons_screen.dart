import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/weapon.dart';
import '../../models/session.dart';
import '../../theme/app_theme.dart';
import 'create_weapon_screen.dart';
import 'dart:io';

class MyWeaponsScreen extends StatefulWidget {
  const MyWeaponsScreen({Key? key}) : super(key: key);

  @override
  State<MyWeaponsScreen> createState() => _MyWeaponsScreenState();
}

class _MyWeaponsScreenState extends State<MyWeaponsScreen> {
  List<Weapon> _weapons = [];
  Map<String, double> _weaponPrecisions = {}; // Nom de l'arme -> Moyenne de précision
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Charger toutes les armes
      final weaponsData = await DatabaseHelper.instance.getAllWeapons();
      final weapons = weaponsData.map((data) => Weapon.fromMap(data)).toList();

      // 2. Charger toutes les sessions pour calculer la précision
      final sessions = await DatabaseHelper.instance.getAllSessions();
      final Map<String, List<double>> precisionByWeapon = {};

      for (var session in sessions) {
        if (session.displayWeaponName != null && session.stdDeviation != null) {
          final name = session.displayWeaponName!;
          if (!precisionByWeapon.containsKey(name)) {
            precisionByWeapon[name] = [];
          }
          precisionByWeapon[name]!.add(session.stdDeviation!);
        }
      }

      final Map<String, double> precisions = {};
      precisionByWeapon.forEach((name, stdDevs) {
        if (stdDevs.isNotEmpty) {
          precisions[name] = stdDevs.reduce((a, b) => a + b) / stdDevs.length;
        }
      });

      setState(() {
        _weapons = weapons;
        _weaponPrecisions = precisions;
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

  Future<void> _addWeapon() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateWeaponScreen()),
    );
    if (result != null) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('MES ARMES'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWeapon,
        backgroundColor: AppTheme.accentPrimary,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentPrimary),
            )
          : _weapons.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _weapons.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildWeaponCard(_weapons[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.gps_fixed,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune arme enregistrée',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addWeapon,
            icon: const Icon(Icons.add),
            label: const Text('AJOUTER UNE ARME'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeaponCard(Weapon weapon) {
    final avgPrecision = _weaponPrecisions[weapon.name];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                ),
                const SizedBox(height: 4),
                Text(
                  weapon.displayDetails,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatBadge(
                      '${weapon.usageCount}',
                      'TIRS',
                      Icons.history,
                    ),
                    if (avgPrecision != null) ...[
                      const SizedBox(width: 12),
                      _buildStatBadge(
                        '${avgPrecision.toStringAsFixed(1)} px',
                        'PRÉCISION',
                        Icons.track_changes,
                        color: AppTheme.accentSecondary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatBadge(String value, String label, IconData icon, {Color? color}) {
    final themeColor = color ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: themeColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: themeColor),
          const SizedBox(width: 4),
           Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: themeColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: themeColor.withOpacity(0.7),
            ),
          ),
        ],
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
