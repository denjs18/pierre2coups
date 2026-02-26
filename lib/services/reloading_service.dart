import '../database/database_helper.dart';
import '../models/component.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../models/batch.dart';
import '../models/stock_transaction.dart';

/// Exception pour les erreurs de stock
class StockException implements Exception {
  final String message;
  final Map<String, dynamic>? details;

  StockException(this.message, {this.details});

  @override
  String toString() => message;
}

/// Résultat de vérification de stock pour une recette
class StockCheckResult {
  final bool hasEnoughStock;
  final int maxQuantity;
  final List<StockShortage> shortages;

  StockCheckResult({
    required this.hasEnoughStock,
    required this.maxQuantity,
    required this.shortages,
  });
}

/// Détail d'un manque de stock
class StockShortage {
  final Component component;
  final double required;
  final double available;
  final double shortage;

  StockShortage({
    required this.component,
    required this.required,
    required this.available,
  }) : shortage = required - available;

  String get message =>
      '${component.displayName}: besoin ${required.toStringAsFixed(1)}, disponible ${available.toStringAsFixed(1)}';
}

/// Service principal pour la gestion du cycle de rechargement
class ReloadingService {
  static final ReloadingService instance = ReloadingService._internal();
  final DatabaseHelper _db = DatabaseHelper.instance;

  ReloadingService._internal();

  // ============================================
  // GESTION DES STOCKS
  // ============================================

  /// Ajoute du stock (achat)
  Future<Component> addStock({
    required int componentId,
    required double quantity,
    String? notes,
  }) async {
    final component = await _db.getComponent(componentId);
    if (component == null) {
      throw StockException('Composant non trouvé');
    }

    final newQuantity = component.quantity + quantity;

    // Mettre à jour le composant
    await _db.updateComponentQuantity(componentId, newQuantity);

    // Enregistrer la transaction
    await _db.insertStockTransaction(StockTransaction(
      componentId: componentId,
      type: TransactionType.purchase,
      quantity: quantity,
      balanceAfter: newQuantity,
      notes: notes,
      createdAt: DateTime.now(),
    ));

    return component.copyWith(quantity: newQuantity);
  }

  /// Consomme du stock (décrémentation manuelle ou perte)
  Future<Component> consumeStock({
    required int componentId,
    required double quantity,
    TransactionType type = TransactionType.waste,
    String? notes,
  }) async {
    final component = await _db.getComponent(componentId);
    if (component == null) {
      throw StockException('Composant non trouvé');
    }

    if (component.quantity < quantity) {
      throw StockException(
        'Stock insuffisant',
        details: {
          'available': component.quantity,
          'required': quantity,
        },
      );
    }

    final newQuantity = component.quantity - quantity;

    await _db.updateComponentQuantity(componentId, newQuantity);

    await _db.insertStockTransaction(StockTransaction(
      componentId: componentId,
      type: type,
      quantity: -quantity,
      balanceAfter: newQuantity,
      notes: notes,
      createdAt: DateTime.now(),
    ));

    return component.copyWith(quantity: newQuantity);
  }

  /// Ajuste le stock manuellement (inventaire)
  Future<Component> adjustStock({
    required int componentId,
    required double newQuantity,
    String? notes,
  }) async {
    final component = await _db.getComponent(componentId);
    if (component == null) {
      throw StockException('Composant non trouvé');
    }

    final difference = newQuantity - component.quantity;

    await _db.updateComponentQuantity(componentId, newQuantity);

    await _db.insertStockTransaction(StockTransaction(
      componentId: componentId,
      type: TransactionType.adjustment,
      quantity: difference,
      balanceAfter: newQuantity,
      notes: notes ?? 'Ajustement d\'inventaire',
      createdAt: DateTime.now(),
    ));

    return component.copyWith(quantity: newQuantity);
  }

  // ============================================
  // VÉRIFICATION DE STOCK POUR RECETTE
  // ============================================

  /// Vérifie si le stock est suffisant pour fabriquer N cartouches
  Future<StockCheckResult> checkStockForRecipe({
    required int recipeId,
    required int quantity,
  }) async {
    final recipe = await _db.getRecipe(recipeId);
    if (recipe == null) {
      throw StockException('Recette non trouvée');
    }

    final shortages = <StockShortage>[];
    int maxQuantity = 999999;

    for (final ingredient in recipe.ingredients) {
      final component = await _db.getComponent(ingredient.componentId);
      if (component == null) continue;

      final required = ingredient.quantityPerUnit * quantity;
      final available = component.quantity;

      if (available < required) {
        shortages.add(StockShortage(
          component: component,
          required: required,
          available: available,
        ));
      }

      // Calculer le nombre max de cartouches possibles
      if (ingredient.quantityPerUnit > 0) {
        final maxForThisComponent = (available / ingredient.quantityPerUnit).floor();
        if (maxForThisComponent < maxQuantity) {
          maxQuantity = maxForThisComponent;
        }
      }
    }

    return StockCheckResult(
      hasEnoughStock: shortages.isEmpty,
      maxQuantity: maxQuantity,
      shortages: shortages,
    );
  }

  // ============================================
  // FABRICATION DE LOT
  // ============================================

  /// Fabrique un lot de cartouches selon une recette
  /// Décrémente automatiquement les stocks
  Future<Batch> fabricateBatch({
    required int recipeId,
    required int quantity,
    String? notes,
  }) async {
    final recipe = await _db.getRecipe(recipeId);
    if (recipe == null) {
      throw StockException('Recette non trouvée');
    }

    // Vérifier le stock
    final stockCheck = await checkStockForRecipe(
      recipeId: recipeId,
      quantity: quantity,
    );

    if (!stockCheck.hasEnoughStock) {
      final shortageMessages = stockCheck.shortages.map((s) => s.message).join('\n');
      throw StockException(
        'Stock insuffisant pour fabriquer $quantity cartouches:\n$shortageMessages',
        details: {
          'maxQuantity': stockCheck.maxQuantity,
          'shortages': stockCheck.shortages,
        },
      );
    }

    // Générer le numéro de lot
    final lotNumber = await _db.generateNextLotNumber();

    // Créer le lot
    final batch = Batch(
      lotNumber: lotNumber,
      recipeId: recipeId,
      recipeName: recipe.name,
      weaponId: recipe.weaponId,
      weaponName: recipe.weaponName,
      quantityInitial: quantity,
      quantityRemaining: quantity,
      status: BatchStatus.active,
      fabricationDate: DateTime.now(),
      notes: notes,
      createdAt: DateTime.now(),
    );

    final batchId = await _db.insertBatch(batch);

    // Décrémenter les stocks pour chaque ingrédient
    for (final ingredient in recipe.ingredients) {
      final component = await _db.getComponent(ingredient.componentId);
      if (component == null) continue;

      final consumed = ingredient.quantityPerUnit * quantity;
      final newQuantity = component.quantity - consumed;

      await _db.updateComponentQuantity(ingredient.componentId, newQuantity);

      await _db.insertStockTransaction(StockTransaction(
        componentId: ingredient.componentId,
        type: TransactionType.fabrication,
        quantity: -consumed,
        balanceAfter: newQuantity,
        batchId: batchId,
        notes: 'Fabrication Lot #$lotNumber ($quantity cartouches)',
        createdAt: DateTime.now(),
      ));
    }

    // Incrémenter le compteur d'utilisation de la recette
    await _db.incrementRecipeUsage(recipeId);

    return batch.copyWith(id: batchId);
  }

  // ============================================
  // CONSOMMATION DE LOT (TIR)
  // ============================================

  /// Consomme des cartouches d'un lot (enregistrement de session)
  /// Met à jour automatiquement la quantité restante du lot
  Future<Batch> consumeBatch({
    required int batchId,
    required int quantity,
    int? sessionId,
  }) async {
    final batch = await _db.getBatch(batchId);
    if (batch == null) {
      throw StockException('Lot non trouvé');
    }

    if (batch.quantityRemaining < quantity) {
      throw StockException(
        'Quantité insuffisante dans le lot',
        details: {
          'available': batch.quantityRemaining,
          'required': quantity,
        },
      );
    }

    final newRemaining = batch.quantityRemaining - quantity;
    await _db.updateBatchQuantity(batchId, newRemaining);

    return batch.copyWith(
      quantityRemaining: newRemaining,
      status: newRemaining <= 0 ? BatchStatus.empty : BatchStatus.active,
    );
  }

  // ============================================
  // RECYCLAGE DES ÉTUIS
  // ============================================

  /// Recycle des étuis après un tir
  /// Incrémente le stock d'étuis avec reload_count augmenté
  Future<Component?> recycleBrass({
    required int quantity,
    int? sessionId,
    String? notes,
  }) async {
    // Trouver le composant étui principal (ou créer une logique de sélection)
    final brassComponents = await _db.getComponentsByCategory(ComponentCategory.brass);
    if (brassComponents.isEmpty) {
      return null; // Pas de composant étui dans le stock
    }

    // Utiliser le premier étui trouvé (on pourrait améliorer cette logique)
    final brass = brassComponents.first;
    final newQuantity = brass.quantity + quantity;
    final newReloadCount = brass.reloadCount + 1;

    await _db.updateComponent(brass.copyWith(
      quantity: newQuantity,
      reloadCount: newReloadCount,
    ));

    await _db.insertStockTransaction(StockTransaction(
      componentId: brass.id!,
      type: TransactionType.recycling,
      quantity: quantity.toDouble(),
      balanceAfter: newQuantity,
      sessionId: sessionId,
      notes: notes ?? 'Recyclage de $quantity étuis',
      createdAt: DateTime.now(),
    ));

    return brass.copyWith(
      quantity: newQuantity,
      reloadCount: newReloadCount,
    );
  }

  /// Recycle des étuis d'un composant spécifique
  Future<Component> recycleBrassForComponent({
    required int componentId,
    required int quantity,
    int? sessionId,
    String? notes,
  }) async {
    final component = await _db.getComponent(componentId);
    if (component == null) {
      throw StockException('Composant non trouvé');
    }

    if (component.category != ComponentCategory.brass) {
      throw StockException('Ce composant n\'est pas un étui');
    }

    final newQuantity = component.quantity + quantity;

    await _db.updateComponent(component.copyWith(
      quantity: newQuantity,
      reloadCount: component.reloadCount + 1,
    ));

    await _db.insertStockTransaction(StockTransaction(
      componentId: componentId,
      type: TransactionType.recycling,
      quantity: quantity.toDouble(),
      balanceAfter: newQuantity,
      sessionId: sessionId,
      notes: notes ?? 'Recyclage de $quantity étuis',
      createdAt: DateTime.now(),
    ));

    return component.copyWith(
      quantity: newQuantity,
      reloadCount: component.reloadCount + 1,
    );
  }

  // ============================================
  // STATISTIQUES ET RAPPORTS
  // ============================================

  /// Obtient un résumé du stock par catégorie
  Future<Map<ComponentCategory, double>> getStockSummary() async {
    final components = await _db.getAllComponents();
    final summary = <ComponentCategory, double>{};

    for (final category in ComponentCategory.values) {
      summary[category] = 0;
    }

    for (final component in components) {
      summary[component.category] = (summary[component.category] ?? 0) + component.quantity;
    }

    return summary;
  }

  /// Obtient les composants en alerte (stock bas)
  Future<List<Component>> getLowStockAlerts() async {
    return await _db.getLowStockComponents();
  }

  /// Obtient les statistiques d'utilisation d'un lot
  Future<Map<String, dynamic>> getBatchStatistics(int batchId) async {
    final batch = await _db.getBatch(batchId);
    if (batch == null) {
      throw StockException('Lot non trouvé');
    }

    final sessionCount = await _db.getSessionCountForBatch(batchId);
    final totalShots = await _db.getTotalShotsForBatch(batchId);
    final transactions = await _db.getTransactionsForBatch(batchId);

    return {
      'batch': batch,
      'sessionCount': sessionCount,
      'totalShots': totalShots,
      'usedQuantity': batch.quantityUsed,
      'remainingQuantity': batch.quantityRemaining,
      'consumedPercentage': batch.consumedPercentage,
      'transactions': transactions,
    };
  }
}
