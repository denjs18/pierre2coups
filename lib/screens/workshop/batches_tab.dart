import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/database_helper.dart';
import '../../models/batch.dart';
import '../../models/recipe.dart';
import '../../services/reloading_service.dart';
import '../../theme/app_theme.dart';

/// Onglet de gestion des lots fabriqués
class BatchesTab extends StatefulWidget {
  const BatchesTab({super.key});

  @override
  State<BatchesTab> createState() => _BatchesTabState();
}

class _BatchesTabState extends State<BatchesTab> {
  List<Batch> _batches = [];
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  bool _showEmpty = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final batches = await DatabaseHelper.instance.getAllBatches();
      final recipes = await DatabaseHelper.instance.getAllRecipes();
      setState(() {
        _batches = batches;
        _recipes = recipes;
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

  List<Batch> get _filteredBatches {
    if (_showEmpty) {
      return _batches;
    }
    return _batches.where((b) => b.status == BatchStatus.active).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          // Barre de filtre
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_filteredBatches.length} lot(s)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('Lots vides'),
                  selected: _showEmpty,
                  onSelected: (value) => setState(() => _showEmpty = value),
                  selectedColor: AppTheme.accentPrimary.withOpacity(0.2),
                  checkmarkColor: AppTheme.accentPrimary,
                ),
              ],
            ),
          ),

          // Liste des lots
          Expanded(
            child: _filteredBatches.isEmpty
                ? _buildEmptyState()
                : _buildBatchesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _recipes.isEmpty ? null : _showFabricationDialog,
        backgroundColor: _recipes.isEmpty
            ? AppTheme.textSecondary
            : AppTheme.accentSecondary,
        icon: const Icon(Icons.build_outlined, color: Colors.white),
        label: const Text(
          'FABRIQUER',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
            _showEmpty ? 'Aucun lot' : 'Aucun lot actif',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _recipes.isEmpty
                ? 'Créez d\'abord une recette'
                : 'Fabriquez vos premières munitions',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _filteredBatches.length,
        itemBuilder: (context, index) {
          final batch = _filteredBatches[index];
          return _buildBatchCard(batch);
        },
      ),
    );
  }

  Widget _buildBatchCard(Batch batch) {
    final isActive = batch.status == BatchStatus.active;
    final percentage = batch.remainingPercentage;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _showBatchDetails(batch),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.accentPrimary.withOpacity(0.2)
                          : AppTheme.textSecondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${batch.lotNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? AppTheme.accentPrimary
                            : AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      batch.status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? AppTheme.successColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${batch.quantityRemaining}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppTheme.accentPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        'sur ${batch.quantityInitial}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Recette et arme
              if (batch.recipeName != null || batch.weaponName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      if (batch.recipeName != null) ...[
                        const Icon(
                          Icons.science_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          batch.recipeName!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      if (batch.weaponName != null) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.gps_fixed,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            batch.weaponName!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Jauge de consommation
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isActive ? AppTheme.accentPrimary : AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Date de fabrication
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fabriqué le ${_formatDate(batch.fabricationDate)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}% restant',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? AppTheme.textSecondary
                          : AppTheme.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showFabricationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FabricationSheet(
        recipes: _recipes,
        onFabricate: (recipeId, quantity, notes) async {
          Navigator.pop(context);
          await _fabricate(recipeId, quantity, notes);
        },
      ),
    );
  }

  Future<void> _fabricate(int recipeId, int quantity, String? notes) async {
    try {
      final batch = await ReloadingService.instance.fabricateBatch(
        recipeId: recipeId,
        quantity: quantity,
        notes: notes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lot #${batch.lotNumber} créé avec $quantity cartouches'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showBatchDetails(Batch batch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BatchDetailsSheet(
        batch: batch,
        onRecycle: () async {
          Navigator.pop(context);
          await _recycleBrass(batch);
        },
        onRefresh: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  Future<void> _recycleBrass(Batch batch) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _RecycleDialog(
        maxQuantity: batch.quantityUsed,
      ),
    );

    if (result != null && result > 0) {
      try {
        await ReloadingService.instance.recycleBrass(
          quantity: result,
          notes: 'Recyclage du lot #${batch.lotNumber}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$result étuis recyclés'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
}

/// Sheet pour la fabrication d'un nouveau lot
class _FabricationSheet extends StatefulWidget {
  final List<Recipe> recipes;
  final Future<void> Function(int recipeId, int quantity, String? notes) onFabricate;

  const _FabricationSheet({
    required this.recipes,
    required this.onFabricate,
  });

  @override
  State<_FabricationSheet> createState() => _FabricationSheetState();
}

class _FabricationSheetState extends State<_FabricationSheet> {
  int? _selectedRecipeId;
  final _quantityController = TextEditingController(text: '50');
  final _notesController = TextEditingController();
  bool _isChecking = false;
  StockCheckResult? _stockCheck;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkStock() async {
    if (_selectedRecipeId == null) return;

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) return;

    setState(() => _isChecking = true);

    try {
      final result = await ReloadingService.instance.checkStockForRecipe(
        recipeId: _selectedRecipeId!,
        quantity: quantity,
      );
      setState(() {
        _stockCheck = result;
        _isChecking = false;
      });
    } catch (e) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.build_outlined,
                  color: AppTheme.accentSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  'FABRICATION',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sélection recette
            DropdownButtonFormField<int>(
              value: _selectedRecipeId,
              decoration: const InputDecoration(
                labelText: 'Recette *',
              ),
              items: widget.recipes.map((recipe) => DropdownMenuItem(
                value: recipe.id,
                child: Text(recipe.displayName),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRecipeId = value;
                  _stockCheck = null;
                });
                _checkStock();
              },
            ),
            const SizedBox(height: 16),

            // Quantité
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantité *',
                      suffixText: 'cartouches',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) {
                      _stockCheck = null;
                      _checkStock();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _checkStock,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'Vérifier le stock',
                ),
              ],
            ),

            // Résultat vérification stock
            if (_stockCheck != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _stockCheck!.hasEnoughStock
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _stockCheck!.hasEnoughStock
                        ? AppTheme.successColor.withOpacity(0.3)
                        : AppTheme.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _stockCheck!.hasEnoughStock
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          color: _stockCheck!.hasEnoughStock
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _stockCheck!.hasEnoughStock
                              ? 'Stock suffisant'
                              : 'Stock insuffisant',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _stockCheck!.hasEnoughStock
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                    if (!_stockCheck!.hasEnoughStock) ...[
                      const SizedBox(height: 8),
                      ..._stockCheck!.shortages.map((shortage) => Padding(
                        padding: const EdgeInsets.only(left: 28, bottom: 4),
                        child: Text(
                          shortage.message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )),
                      Padding(
                        padding: const EdgeInsets.only(left: 28, top: 4),
                        child: Text(
                          'Maximum fabricable: ${_stockCheck!.maxQuantity} cartouches',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optionnel...',
              ),
            ),
            const SizedBox(height: 24),

            // Bouton fabriquer
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _canFabricate ? _doFabricate : null,
                icon: const Icon(Icons.build_outlined),
                label: const Text('FABRIQUER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool get _canFabricate {
    return _selectedRecipeId != null &&
        (_stockCheck?.hasEnoughStock ?? false) &&
        (int.tryParse(_quantityController.text) ?? 0) > 0;
  }

  void _doFabricate() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    widget.onFabricate(_selectedRecipeId!, quantity, notes);
  }
}

/// Sheet pour les détails d'un lot
class _BatchDetailsSheet extends StatelessWidget {
  final Batch batch;
  final VoidCallback onRecycle;
  final VoidCallback onRefresh;

  const _BatchDetailsSheet({
    required this.batch,
    required this.onRecycle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LOT #${batch.lotNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: batch.status == BatchStatus.active
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  batch.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: batch.status == BatchStatus.active
                        ? AppTheme.successColor
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Statistiques
          Row(
            children: [
              _StatItem(
                label: 'FABRIQUÉES',
                value: batch.quantityInitial.toString(),
              ),
              const SizedBox(width: 24),
              _StatItem(
                label: 'TIRÉES',
                value: batch.quantityUsed.toString(),
              ),
              const SizedBox(width: 24),
              _StatItem(
                label: 'RESTANTES',
                value: batch.quantityRemaining.toString(),
                highlight: batch.status == BatchStatus.active,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Infos
          if (batch.recipeName != null)
            _InfoRow(
              icon: Icons.science_outlined,
              label: 'Recette',
              value: batch.recipeName!,
            ),
          if (batch.weaponName != null)
            _InfoRow(
              icon: Icons.gps_fixed,
              label: 'Arme',
              value: batch.weaponName!,
            ),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Fabriqué le',
            value: '${batch.fabricationDate.day}/${batch.fabricationDate.month}/${batch.fabricationDate.year}',
          ),
          if (batch.notes != null && batch.notes!.isNotEmpty)
            _InfoRow(
              icon: Icons.notes_outlined,
              label: 'Notes',
              value: batch.notes!,
            ),

          const SizedBox(height: 24),

          // Actions
          if (batch.quantityUsed > 0)
            OutlinedButton.icon(
              onPressed: onRecycle,
              icon: const Icon(Icons.recycling_outlined),
              label: Text('Recycler les ${batch.quantityUsed} étuis tirés'),
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: highlight ? AppTheme.accentPrimary : AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog pour le recyclage des étuis
class _RecycleDialog extends StatefulWidget {
  final int maxQuantity;

  const _RecycleDialog({required this.maxQuantity});

  @override
  State<_RecycleDialog> createState() => _RecycleDialogState();
}

class _RecycleDialogState extends State<_RecycleDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.maxQuantity.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recycler les étuis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Combien d\'étuis souhaitez-vous recycler ?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Quantité',
              suffixText: 'étuis',
              helperText: 'Maximum: ${widget.maxQuantity}',
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            final value = int.tryParse(_controller.text) ?? 0;
            if (value > 0 && value <= widget.maxQuantity) {
              Navigator.pop(context, value);
            }
          },
          icon: const Icon(Icons.recycling_outlined),
          label: const Text('Recycler'),
        ),
      ],
    );
  }
}
