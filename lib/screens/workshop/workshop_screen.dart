import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'stock_tab.dart';
import 'recipes_tab.dart';
import 'batches_tab.dart';

/// Écran principal de l'Atelier (Workshop)
/// Contient les onglets Stock, Recettes et Lots
class WorkshopScreen extends StatefulWidget {
  const WorkshopScreen({super.key});

  @override
  State<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends State<WorkshopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ATELIER'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique des transactions',
            onPressed: () {
              // TODO: Afficher l'historique des transactions
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentPrimary,
          indicatorWeight: 3,
          labelColor: AppTheme.accentPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.inventory_2_outlined),
              text: 'STOCK',
            ),
            Tab(
              icon: Icon(Icons.science_outlined),
              text: 'RECETTES',
            ),
            Tab(
              icon: Icon(Icons.layers_outlined),
              text: 'LOTS',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StockTab(
            onNavigateToRecipes: () => _tabController.animateTo(1),
          ),
          RecipesTab(
            onNavigateToBatches: () => _tabController.animateTo(2),
          ),
          const BatchesTab(),
        ],
      ),
    );
  }
}
