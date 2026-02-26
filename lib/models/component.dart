/// Catégories de composants pour le rechargement
enum ComponentCategory {
  powder,     // Poudre (en grammes)
  projectile, // Ogives (en unités)
  brass,      // Étuis/Douilles (en unités, avec compteur de rechargements)
  primer,     // Amorces (en unités)
}

/// Extension pour les labels et unités des catégories
extension ComponentCategoryExtension on ComponentCategory {
  String get label {
    switch (this) {
      case ComponentCategory.powder:
        return 'Poudre';
      case ComponentCategory.projectile:
        return 'Ogive';
      case ComponentCategory.brass:
        return 'Étui';
      case ComponentCategory.primer:
        return 'Amorce';
    }
  }

  String get pluralLabel {
    switch (this) {
      case ComponentCategory.powder:
        return 'Poudres';
      case ComponentCategory.projectile:
        return 'Ogives';
      case ComponentCategory.brass:
        return 'Étuis';
      case ComponentCategory.primer:
        return 'Amorces';
    }
  }

  String get unit {
    switch (this) {
      case ComponentCategory.powder:
        return 'g';
      case ComponentCategory.projectile:
      case ComponentCategory.brass:
      case ComponentCategory.primer:
        return 'u';
    }
  }

  String get icon {
    switch (this) {
      case ComponentCategory.powder:
        return '🧪';
      case ComponentCategory.projectile:
        return '🔘';
      case ComponentCategory.brass:
        return '🔩';
      case ComponentCategory.primer:
        return '💥';
    }
  }

  static ComponentCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'powder':
        return ComponentCategory.powder;
      case 'projectile':
        return ComponentCategory.projectile;
      case 'brass':
        return ComponentCategory.brass;
      case 'primer':
        return ComponentCategory.primer;
      default:
        throw ArgumentError('Unknown component category: $value');
    }
  }
}

/// Composant de rechargement (stock central)
class Component {
  final int? id;
  final String name;
  final String? brand;
  final String? reference;
  final ComponentCategory category;
  final double quantity;
  final double? initialQuantity;
  final int reloadCount; // Nombre de rechargements (pour les étuis)
  final double? alertThreshold; // Seuil d'alerte (ex: < 10%)
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Component({
    this.id,
    required this.name,
    this.brand,
    this.reference,
    required this.category,
    required this.quantity,
    this.initialQuantity,
    this.reloadCount = 0,
    this.alertThreshold,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Vérifie si le stock est en alerte (sous le seuil)
  bool get isLowStock {
    if (alertThreshold == null || initialQuantity == null || initialQuantity == 0) {
      return false;
    }
    final percentage = (quantity / initialQuantity!) * 100;
    return percentage <= alertThreshold!;
  }

  /// Pourcentage restant du stock
  double get remainingPercentage {
    if (initialQuantity == null || initialQuantity == 0) return 100;
    return (quantity / initialQuantity!) * 100;
  }

  /// Affichage formaté de la quantité
  String get formattedQuantity {
    if (category == ComponentCategory.powder) {
      return '${quantity.toStringAsFixed(1)} ${category.unit}';
    }
    return '${quantity.toInt()} ${category.unit}';
  }

  /// Nom d'affichage complet
  String get displayName {
    if (brand != null && brand!.isNotEmpty) {
      return '$brand $name';
    }
    return name;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'reference': reference,
      'category': category.name,
      'quantity': quantity,
      'initial_quantity': initialQuantity,
      'reload_count': reloadCount,
      'alert_threshold': alertThreshold,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Component.fromMap(Map<String, dynamic> map) {
    return Component(
      id: map['id'] as int?,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      reference: map['reference'] as String?,
      category: ComponentCategoryExtension.fromString(map['category'] as String),
      quantity: (map['quantity'] as num).toDouble(),
      initialQuantity: map['initial_quantity'] != null
          ? (map['initial_quantity'] as num).toDouble()
          : null,
      reloadCount: map['reload_count'] as int? ?? 0,
      alertThreshold: map['alert_threshold'] != null
          ? (map['alert_threshold'] as num).toDouble()
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Component copyWith({
    int? id,
    String? name,
    String? brand,
    String? reference,
    ComponentCategory? category,
    double? quantity,
    double? initialQuantity,
    int? reloadCount,
    double? alertThreshold,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Component(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      reference: reference ?? this.reference,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      reloadCount: reloadCount ?? this.reloadCount,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
