import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/database_helper.dart';
import '../../models/recipe.dart';
import '../../models/recipe_ingredient.dart';
import '../../models/component.dart';
import '../../models/weapon.dart';
import '../../theme/app_theme.dart';

/// Écran de création/édition d'une recette
class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;

  const RecipeFormScreen({
    super.key,
    this.recipe,
  });

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _caliberController;
  late TextEditingController _descriptionController;
  late TextEditingController _powderWeightController;
  late TextEditingController _overallLengthController;
  late TextEditingController _bulletWeightController;
  late TextEditingController _notesController;

  String? _selectedWeaponId;
  String? _selectedWeaponName;
  bool _isDefault = false;
  bool _isLoading = false;
  bool _isEditing = false;

  List<Map<String, dynamic>> _weapons = [];
  List<Component> _components = [];
  List<_IngredientEntry> _ingredientEntries = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.recipe != null;

    _nameController = TextEditingController(text: widget.recipe?.name ?? '');
    _caliberController = TextEditingController(text: widget.recipe?.caliber ?? '');
    _descriptionController = TextEditingController(text: widget.recipe?.description ?? '');
    _powderWeightController = TextEditingController(
      text: widget.recipe?.powderWeight?.toString() ?? '',
    );
    _overallLengthController = TextEditingController(
      text: widget.recipe?.overallLength?.toString() ?? '',
    );
    _bulletWeightController = TextEditingController(
      text: widget.recipe?.bulletWeight?.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.recipe?.notes ?? '');

    _selectedWeaponId = widget.recipe?.weaponId;
    _selectedWeaponName = widget.recipe?.weaponName;
    _isDefault = widget.recipe?.isDefault ?? false;

    _loadData();
  }

  Future<void> _loadData() async {
    final weapons = await DatabaseHelper.instance.getAllWeapons();
    final components = await DatabaseHelper.instance.getAllComponents();

    setState(() {
      _weapons = weapons;
      _components = components;
    });

    // Charger les ingrédients existants
    if (_isEditing && widget.recipe!.ingredients.isNotEmpty) {
      setState(() {
        _ingredientEntries = widget.recipe!.ingredients.map((ingredient) {
          return _IngredientEntry(
            componentId: ingredient.componentId,
            quantityController: TextEditingController(
              text: ingredient.quantityPerUnit.toString(),
            ),
          );
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caliberController.dispose();
    _descriptionController.dispose();
    _powderWeightController.dispose();
    _overallLengthController.dispose();
    _bulletWeightController.dispose();
    _notesController.dispose();
    for (final entry in _ingredientEntries) {
      entry.quantityController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la recette' : 'Nouvelle recette'),
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
            // Informations de base
            Text(
              'INFORMATIONS',
              style: AppTheme.labelStyle,
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la recette *',
                hintText: 'Ex: Charge standard .308',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Sélection arme
            DropdownButtonFormField<String>(
              value: _selectedWeaponId,
              decoration: const InputDecoration(
                labelText: 'Arme associée',
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Aucune arme'),
                ),
                ..._weapons.map((weapon) => DropdownMenuItem(
                  value: weapon['id'] as String,
                  child: Text(
                    '${weapon['manufacturer']} ${weapon['model']} (${weapon['caliber']})',
                  ),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedWeaponId = value;
                  if (value != null) {
                    final weapon = _weapons.firstWhere((w) => w['id'] == value);
                    _selectedWeaponName = '${weapon['manufacturer']} ${weapon['model']}';
                    if (_caliberController.text.isEmpty) {
                      _caliberController.text = weapon['caliber'] as String;
                    }
                  } else {
                    _selectedWeaponName = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _caliberController,
              decoration: const InputDecoration(
                labelText: 'Calibre',
                hintText: 'Ex: .308 Winchester',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description de la charge...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Paramètres de charge
            Text(
              'PARAMÈTRES DE CHARGE',
              style: AppTheme.labelStyle,
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _powderWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Poids poudre',
                      suffixText: 'g',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _bulletWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Poids ogive',
                      suffixText: 'gr',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _overallLengthController,
              decoration: const InputDecoration(
                labelText: 'Longueur totale (OAL)',
                suffixText: 'mm',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
            const SizedBox(height: 24),

            // Ingrédients
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INGRÉDIENTS',
                  style: AppTheme.labelStyle,
                ),
                TextButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_ingredientEntries.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.borderColor,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Text(
                  'Ajoutez les composants nécessaires à cette recette',
                  style: TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._ingredientEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                return _buildIngredientRow(index, ingredient);
              }),

            const SizedBox(height: 24),

            // Options
            SwitchListTile(
              title: const Text('Recette par défaut'),
              subtitle: const Text('Utilisée automatiquement pour cette arme'),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
              activeColor: AppTheme.accentPrimary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Informations supplémentaires...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

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
                    : Text(_isEditing ? 'Enregistrer' : 'Créer la recette'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientRow(int index, _IngredientEntry entry) {
    final component = _components.where((c) => c.id == entry.componentId).firstOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                value: entry.componentId,
                decoration: const InputDecoration(
                  labelText: 'Composant',
                  isDense: true,
                ),
                items: _components.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(
                    '${c.category.icon} ${c.displayName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    entry.componentId = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: entry.quantityController,
                decoration: InputDecoration(
                  labelText: 'Qté/u',
                  isDense: true,
                  suffixText: component?.category.unit ?? '',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: AppTheme.errorColor,
              onPressed: () => _removeIngredient(index),
            ),
          ],
        ),
      ),
    );
  }

  void _addIngredient() {
    setState(() {
      _ingredientEntries.add(_IngredientEntry(
        quantityController: TextEditingController(text: '1'),
      ));
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientEntries[index].quantityController.dispose();
      _ingredientEntries.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final powderWeight = _powderWeightController.text.isNotEmpty
          ? double.parse(_powderWeightController.text)
          : null;
      final overallLength = _overallLengthController.text.isNotEmpty
          ? double.parse(_overallLengthController.text)
          : null;
      final bulletWeight = _bulletWeightController.text.isNotEmpty
          ? double.parse(_bulletWeightController.text)
          : null;

      final db = DatabaseHelper.instance;

      if (_isEditing) {
        final updated = widget.recipe!.copyWith(
          name: _nameController.text.trim(),
          weaponId: _selectedWeaponId,
          weaponName: _selectedWeaponName,
          caliber: _caliberController.text.trim().isEmpty
              ? null
              : _caliberController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          powderWeight: powderWeight,
          overallLength: overallLength,
          bulletWeight: bulletWeight,
          isDefault: _isDefault,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await db.updateRecipe(updated);

        // Mettre à jour les ingrédients
        final ingredients = _ingredientEntries
            .where((e) => e.componentId != null)
            .map((e) => RecipeIngredient(
                  recipeId: widget.recipe!.id!,
                  componentId: e.componentId!,
                  quantityPerUnit: double.tryParse(e.quantityController.text) ?? 1,
                ))
            .toList();
        await db.replaceRecipeIngredients(widget.recipe!.id!, ingredients);
      } else {
        final recipe = Recipe(
          name: _nameController.text.trim(),
          weaponId: _selectedWeaponId,
          weaponName: _selectedWeaponName,
          caliber: _caliberController.text.trim().isEmpty
              ? null
              : _caliberController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          powderWeight: powderWeight,
          overallLength: overallLength,
          bulletWeight: bulletWeight,
          isDefault: _isDefault,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: DateTime.now(),
        );
        final recipeId = await db.insertRecipe(recipe);

        // Ajouter les ingrédients
        for (final entry in _ingredientEntries) {
          if (entry.componentId != null) {
            await db.insertRecipeIngredient(RecipeIngredient(
              recipeId: recipeId,
              componentId: entry.componentId!,
              quantityPerUnit: double.tryParse(entry.quantityController.text) ?? 1,
            ));
          }
        }
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la recette ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${widget.recipe!.name}" ?\n\n'
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
                await DatabaseHelper.instance.deleteRecipe(widget.recipe!.id!);
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

/// Entrée d'ingrédient dans le formulaire
class _IngredientEntry {
  int? componentId;
  final TextEditingController quantityController;

  _IngredientEntry({
    this.componentId,
    required this.quantityController,
  });
}
