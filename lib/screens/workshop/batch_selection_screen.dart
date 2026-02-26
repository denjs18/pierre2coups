import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/batch.dart';
import '../../theme/app_theme.dart';

/// Écran de sélection d'un lot pour une session de tir
class BatchSelectionScreen extends StatefulWidget {
  final String? weaponId;

  const BatchSelectionScreen({
    super.key,
    this.weaponId,
  });

  @override
  State<BatchSelectionScreen> createState() => _BatchSelectionScreenState();
}

class _BatchSelectionScreenState extends State<BatchSelectionScreen> {
  List<Batch> _batches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => _isLoading = true);
    try {
      List<Batch> batches;
      if (widget.weaponId != null) {
        batches = await DatabaseHelper.instance.getBatchesForWeapon(widget.weaponId!);
      } else {
        batches = await DatabaseHelper.instance.getActiveBatches();
      }
      setState(() {
        _batches = batches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner un lot'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _batches.isEmpty
              ? _buildEmptyState()
              : _buildBatchesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.layers_outlined,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun lot actif',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.weaponId != null
                ? 'Aucun lot disponible pour cette arme'
                : 'Fabriquez des munitions dans l\'Atelier',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer sans lot'),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesList() {
    return Column(
      children: [
        // Option sans lot
        ListTile(
          leading: const Icon(Icons.block_outlined, color: AppTheme.textSecondary),
          title: const Text('Sans lot associé'),
          subtitle: const Text('Munitions du commerce ou non tracées'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pop(context, null),
        ),
        const Divider(),

        // Liste des lots
        Expanded(
          child: ListView.builder(
            itemCount: _batches.length,
            itemBuilder: (context, index) {
              final batch = _batches[index];
              return _buildBatchTile(batch);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBatchTile(Batch batch) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.accentPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '#${batch.lotNumber}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.accentPrimary,
            ),
          ),
        ),
      ),
      title: Text(batch.recipeName ?? 'Lot #${batch.lotNumber}'),
      subtitle: Row(
        children: [
          Text('${batch.quantityRemaining}/${batch.quantityInitial} restantes'),
          const SizedBox(width: 8),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: batch.remainingPercentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pop(context, batch),
    );
  }
}
