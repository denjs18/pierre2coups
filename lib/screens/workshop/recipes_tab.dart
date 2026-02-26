import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/recipe.dart';
import '../../theme/app_theme.dart';
import 'recipe_form_screen.dart';

/// Onglet de gestion des recettes de rechargement
class RecipesTab extends StatefulWidget {
  final VoidCallback? onNavigateToBatches;

  const RecipesTab({
    super.key,
    this.onNavigateToBatches,
  });

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> {
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final recipes = await DatabaseHelper.instance.getAllRecipes();
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _recipes.isEmpty ? _buildEmptyState() : _buildRecipesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createRecipe,
        backgroundColor: AppTheme.accentPrimary,
        child: const Icon(Icons.add, color: AppTheme.backgroundPrimary),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune recette',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez vos feuilles de rechargement',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createRecipe,
            icon: const Icon(Icons.add),
            label: const Text('Créer une recette'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesList() {
    // Grouper par arme
    final byWeapon = <String?, List<Recipe>>{};
    for (final recipe in _recipes) {
      final key = recipe.weaponName ?? 'Sans arme';
      byWeapon.putIfAbsent(key, () => []).add(recipe);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: byWeapon.length,
        itemBuilder: (context, index) {
          final weaponName = byWeapon.keys.elementAt(index);
          final recipes = byWeapon[weaponName]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  weaponName?.toUpperCase() ?? 'SANS ARME',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
              ),
              ...recipes.map((recipe) => _buildRecipeCard(recipe)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _editRecipe(recipe),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (recipe.isDefault)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentPrimary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PAR DÉFAUT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accentPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                recipe.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (recipe.caliber != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              recipe.caliber!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${recipe.usageCount}x',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                      const Text(
                        'utilisé',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Paramètres de charge
              if (recipe.chargeSummary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    recipe.chargeSummary,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],

              // Ingrédients résumé
              if (recipe.ingredients.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: recipe.ingredients.map((ingredient) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.borderColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ingredient.componentName ?? 'Composant ${ingredient.componentId}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Bouton fabrication
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _fabricateBatch(recipe),
                    icon: const Icon(Icons.build_outlined, size: 18),
                    label: const Text('Fabriquer'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accentSecondary,
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

  void _createRecipe() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const RecipeFormScreen(),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _editRecipe(Recipe recipe) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeFormScreen(recipe: recipe),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _fabricateBatch(Recipe recipe) async {
    // Naviguer vers l'écran de fabrication avec la recette présélectionnée
    widget.onNavigateToBatches?.call();
    // TODO: Implémenter la navigation vers l'écran de fabrication
  }
}
