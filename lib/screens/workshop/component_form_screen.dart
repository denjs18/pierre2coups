import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/database_helper.dart';
import '../../models/component.dart';
import '../../services/reloading_service.dart';
import '../../theme/app_theme.dart';

/// Écran de création/édition d'un composant
class ComponentFormScreen extends StatefulWidget {
  final Component? component;
  final ComponentCategory? initialCategory;

  const ComponentFormScreen({
    super.key,
    this.component,
    this.initialCategory,
  });

  @override
  State<ComponentFormScreen> createState() => _ComponentFormScreenState();
}

class _ComponentFormScreenState extends State<ComponentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _referenceController;
  late TextEditingController _quantityController;
  late TextEditingController _alertThresholdController;
  late TextEditingController _notesController;

  ComponentCategory _selectedCategory = ComponentCategory.powder;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.component != null;
    _selectedCategory = widget.component?.category ??
        widget.initialCategory ??
        ComponentCategory.powder;

    _nameController = TextEditingController(text: widget.component?.name ?? '');
    _brandController = TextEditingController(text: widget.component?.brand ?? '');
    _referenceController = TextEditingController(text: widget.component?.reference ?? '');
    _quantityController = TextEditingController(
      text: widget.component?.quantity.toString() ?? '',
    );
    _alertThresholdController = TextEditingController(
      text: widget.component?.alertThreshold?.toString() ?? '10',
    );
    _notesController = TextEditingController(text: widget.component?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _referenceController.dispose();
    _quantityController.dispose();
    _alertThresholdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le composant' : 'Nouveau composant'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Supprimer',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Catégorie
            Text(
              'CATÉGORIE',
              style: AppTheme.labelStyle,
            ),
            const SizedBox(height: 8),
            _buildCategorySelector(),
            const SizedBox(height: 24),

            // Nom
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                hintText: 'Ex: Vihtavuori N320',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Marque et Référence
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Marque',
                      hintText: 'Ex: Vihtavuori',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Référence',
                      hintText: 'Ex: N320',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quantité
            Text(
              'QUANTITÉ EN STOCK',
              style: AppTheme.labelStyle,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantité *',
                      suffixText: _selectedCategory.unit,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La quantité est requise';
                      }
                      final quantity = double.tryParse(value);
                      if (quantity == null || quantity < 0) {
                        return 'Quantité invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Seuil d'alerte
            TextFormField(
              controller: _alertThresholdController,
              decoration: const InputDecoration(
                labelText: 'Seuil d\'alerte (%)',
                hintText: 'Alerte si le stock descend sous ce pourcentage',
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Informations supplémentaires...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Actions rapides si édition
            if (_isEditing) ...[
              Text(
                'ACTIONS RAPIDES',
                style: AppTheme.labelStyle,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addStock,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _adjustStock,
                      icon: const Icon(Icons.tune),
                      label: const Text('Ajuster'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // Bouton Enregistrer
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Enregistrer' : 'Créer le composant'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      children: ComponentCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return ChoiceChip(
          label: Text(category.label),
          selected: isSelected,
          onSelected: _isEditing
              ? null
              : (selected) {
                  if (selected) {
                    setState(() => _selectedCategory = category);
                  }
                },
          selectedColor: AppTheme.accentPrimary,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.backgroundPrimary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantity = double.parse(_quantityController.text);
      final alertThreshold = _alertThresholdController.text.isNotEmpty
          ? double.parse(_alertThresholdController.text)
          : null;

      if (_isEditing) {
        final updated = widget.component!.copyWith(
          name: _nameController.text.trim(),
          brand: _brandController.text.trim().isEmpty
              ? null
              : _brandController.text.trim(),
          reference: _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
          quantity: quantity,
          alertThreshold: alertThreshold,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await DatabaseHelper.instance.updateComponent(updated);
      } else {
        final component = Component(
          name: _nameController.text.trim(),
          brand: _brandController.text.trim().isEmpty
              ? null
              : _brandController.text.trim(),
          reference: _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
          category: _selectedCategory,
          quantity: quantity,
          initialQuantity: quantity,
          alertThreshold: alertThreshold,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: DateTime.now(),
        );
        await DatabaseHelper.instance.insertComponent(component);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _addStock() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _QuantityDialog(
        title: 'Ajouter au stock',
        unit: _selectedCategory.unit,
      ),
    );

    if (result != null && result > 0) {
      try {
        await ReloadingService.instance.addStock(
          componentId: widget.component!.id!,
          quantity: result,
          notes: 'Ajout manuel',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('+$result ${_selectedCategory.unit} ajouté')),
          );
          Navigator.pop(context, true);
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

  void _adjustStock() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _QuantityDialog(
        title: 'Ajuster le stock',
        unit: _selectedCategory.unit,
        initialValue: widget.component!.quantity,
        isAdjustment: true,
      ),
    );

    if (result != null) {
      try {
        await ReloadingService.instance.adjustStock(
          componentId: widget.component!.id!,
          newQuantity: result,
          notes: 'Ajustement inventaire',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stock ajusté')),
          );
          Navigator.pop(context, true);
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le composant ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${widget.component!.displayName}" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DatabaseHelper.instance.deleteComponent(widget.component!.id!);
                if (mounted) {
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

/// Dialog pour saisir une quantité
class _QuantityDialog extends StatefulWidget {
  final String title;
  final String unit;
  final double? initialValue;
  final bool isAdjustment;

  const _QuantityDialog({
    required this.title,
    required this.unit,
    this.initialValue,
    this.isAdjustment = false,
  });

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.isAdjustment ? 'Nouvelle quantité' : 'Quantité à ajouter',
          suffixText: widget.unit,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = double.tryParse(_controller.text);
            if (value != null) {
              Navigator.pop(context, value);
            }
          },
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}
