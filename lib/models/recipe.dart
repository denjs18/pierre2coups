import 'dart:convert';
import 'recipe_ingredient.dart';

/// Feuille de rechargement (recette) liée à une arme
class Recipe {
  final int? id;
  final String name;
  final String? weaponId;
  final String? weaponName;
  final String? caliber;
  final String? description;

  // Paramètres de la charge
  final double? powderWeight;     // Poids de poudre par cartouche (g)
  final double? overallLength;    // Longueur totale (mm)
  final double? bulletWeight;     // Poids de l'ogive (grains)

  // Ingrédients (liste des composants nécessaires)
  final List<RecipeIngredient> ingredients;

  // Métadonnées
  final bool isDefault;
  final int usageCount;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Recipe({
    this.id,
    required this.name,
    this.weaponId,
    this.weaponName,
    this.caliber,
    this.description,
    this.powderWeight,
    this.overallLength,
    this.bulletWeight,
    this.ingredients = const [],
    this.isDefault = false,
    this.usageCount = 0,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Nom d'affichage complet
  String get displayName {
    if (caliber != null && caliber!.isNotEmpty) {
      return '$name ($caliber)';
    }
    return name;
  }

  /// Résumé des paramètres de charge
  String get chargeSummary {
    final parts = <String>[];
    if (powderWeight != null) {
      parts.add('${powderWeight!.toStringAsFixed(1)}g poudre');
    }
    if (bulletWeight != null) {
      parts.add('${bulletWeight!.toStringAsFixed(0)}gr ogive');
    }
    if (overallLength != null) {
      parts.add('${overallLength!.toStringAsFixed(2)}mm OAL');
    }
    return parts.join(' • ');
  }

  /// Vérifie si la recette a tous les composants nécessaires définis
  bool get hasAllIngredients {
    bool hasPowder = false;
    bool hasProjectile = false;
    bool hasBrass = false;
    bool hasPrimer = false;

    for (final ingredient in ingredients) {
      switch (ingredient.componentCategory) {
        case 'powder':
          hasPowder = true;
          break;
        case 'projectile':
          hasProjectile = true;
          break;
        case 'brass':
          hasBrass = true;
          break;
        case 'primer':
          hasPrimer = true;
          break;
      }
    }

    return hasPowder && hasProjectile && hasBrass && hasPrimer;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weapon_id': weaponId,
      'weapon_name': weaponName,
      'caliber': caliber,
      'description': description,
      'powder_weight': powderWeight,
      'overall_length': overallLength,
      'bullet_weight': bulletWeight,
      'is_default': isDefault ? 1 : 0,
      'usage_count': usageCount,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map, {List<RecipeIngredient>? ingredients}) {
    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      weaponId: map['weapon_id'] as String?,
      weaponName: map['weapon_name'] as String?,
      caliber: map['caliber'] as String?,
      description: map['description'] as String?,
      powderWeight: map['powder_weight'] != null
          ? (map['powder_weight'] as num).toDouble()
          : null,
      overallLength: map['overall_length'] != null
          ? (map['overall_length'] as num).toDouble()
          : null,
      bulletWeight: map['bullet_weight'] != null
          ? (map['bullet_weight'] as num).toDouble()
          : null,
      ingredients: ingredients ?? [],
      isDefault: (map['is_default'] as int?) == 1,
      usageCount: map['usage_count'] as int? ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Recipe copyWith({
    int? id,
    String? name,
    String? weaponId,
    String? weaponName,
    String? caliber,
    String? description,
    double? powderWeight,
    double? overallLength,
    double? bulletWeight,
    List<RecipeIngredient>? ingredients,
    bool? isDefault,
    int? usageCount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      weaponId: weaponId ?? this.weaponId,
      weaponName: weaponName ?? this.weaponName,
      caliber: caliber ?? this.caliber,
      description: description ?? this.description,
      powderWeight: powderWeight ?? this.powderWeight,
      overallLength: overallLength ?? this.overallLength,
      bulletWeight: bulletWeight ?? this.bulletWeight,
      ingredients: ingredients ?? this.ingredients,
      isDefault: isDefault ?? this.isDefault,
      usageCount: usageCount ?? this.usageCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
