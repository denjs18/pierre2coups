import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/component.dart';
import '../../theme/app_theme.dart';
import '../../services/reloading_service.dart';
import 'component_form_screen.dart';

/// Onglet de gestion des stocks
class StockTab extends StatefulWidget {
  final VoidCallback? onNavigateToRecipes;

  const StockTab({
    super.key,
    this.onNavigateToRecipes,
  });

  @override
  State<StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<StockTab> {
  List<Component> _components = [];
  List<Component> _lowStockAlerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final components = await DatabaseHelper.instance.getAllComponents();
      final alerts = await ReloadingService.instance.getLowStockAlerts();
      setState(() {
        _components = components;
        _lowStockAlerts = alerts;
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

  Map<ComponentCategory, List<Component>> _groupByCategory() {
    final grouped = <ComponentCategory, List<Component>>{};
    for (final category in ComponentCategory.values) {
      grouped[category] = _components
          .where((c) => c.category == category)
          .toList();
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_components.isEmpty) {
      return _buildEmptyState();
    }

    final groupedComponents = _groupByCategory();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Alertes de stock bas
          if (_lowStockAlerts.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildAlertsSection(),
            ),

          // Stock par catégorie
          ...ComponentCategory.values.map((category) {
            final components = groupedComponents[category] ?? [];
            if (components.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
            return SliverToBoxAdapter(
              child: _buildCategorySection(category, components),
            );
          }),

          // Espace pour le FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun composant en stock',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos composants de rechargement',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addComponent,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un composant'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warningColor,
              ),
              const SizedBox(width: 8),
              Text(
                'ALERTES STOCK BAS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warningColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._lowStockAlerts.map((component) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    component.displayName,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
                Text(
                  component.formattedQuantity,
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${component.remainingPercentage.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCategorySection(ComponentCategory category, List<Component> components) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                category.pluralLabel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addComponent(category: category),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentPrimary,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        ...components.map((component) => _buildComponentCard(component)),
      ],
    );
  }

  Widget _buildComponentCard(Component component) {
    final isLowStock = component.isLowStock;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _editComponent(component),
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
                        Text(
                          component.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (component.reference != null)
                          Text(
                            component.reference!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        component.formattedQuantity,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isLowStock
                              ? AppTheme.warningColor
                              : AppTheme.accentPrimary,
                        ),
                      ),
                      if (component.category == ComponentCategory.brass &&
                          component.reloadCount > 0)
                        Text(
                          '${component.reloadCount}x rechargé',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (component.initialQuantity != null &&
                  component.initialQuantity! > 0) ...[
                const SizedBox(height: 12),
                _buildStockGauge(component),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockGauge(Component component) {
    final percentage = component.remainingPercentage / 100;
    final isLowStock = component.isLowStock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stock initial: ${component.category == ComponentCategory.powder ? component.initialQuantity!.toStringAsFixed(0) : component.initialQuantity!.toInt()} ${component.category.unit}',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${component.remainingPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isLowStock ? AppTheme.warningColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppTheme.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              isLowStock ? AppTheme.warningColor : AppTheme.accentPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _addComponent({ComponentCategory? category}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentFormScreen(
          initialCategory: category,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _editComponent(Component component) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentFormScreen(
          component: component,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }
}
