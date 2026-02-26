/// Ingrédient d'une recette (liaison recette-composant)
class RecipeIngredient {
  final int? id;
  final int recipeId;
  final int componentId;
  final double quantityPerUnit; // Quantité par cartouche fabriquée
  final String? componentCategory; // Cache pour éviter une jointure
  final String? componentName;     // Cache pour l'affichage

  RecipeIngredient({
    this.id,
    required this.recipeId,
    required this.componentId,
    required this.quantityPerUnit,
    this.componentCategory,
    this.componentName,
  });

  /// Affichage formaté de la quantité par unité
  String get formattedQuantity {
    if (componentCategory == 'powder') {
      return '${quantityPerUnit.toStringAsFixed(2)}g/u';
    }
    return '${quantityPerUnit.toInt()}/u';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'component_id': componentId,
      'quantity_per_unit': quantityPerUnit,
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      id: map['id'] as int?,
      recipeId: map['recipe_id'] as int,
      componentId: map['component_id'] as int,
      quantityPerUnit: (map['quantity_per_unit'] as num).toDouble(),
      componentCategory: map['component_category'] as String?,
      componentName: map['component_name'] as String?,
    );
  }

  RecipeIngredient copyWith({
    int? id,
    int? recipeId,
    int? componentId,
    double? quantityPerUnit,
    String? componentCategory,
    String? componentName,
  }) {
    return RecipeIngredient(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      componentId: componentId ?? this.componentId,
      quantityPerUnit: quantityPerUnit ?? this.quantityPerUnit,
      componentCategory: componentCategory ?? this.componentCategory,
      componentName: componentName ?? this.componentName,
    );
  }
}
