/// Statut d'un lot de cartouches
enum BatchStatus {
  active,   // Lot en cours d'utilisation
  empty,    // Lot épuisé
  archived, // Lot archivé manuellement
}

extension BatchStatusExtension on BatchStatus {
  String get label {
    switch (this) {
      case BatchStatus.active:
        return 'Actif';
      case BatchStatus.empty:
        return 'Épuisé';
      case BatchStatus.archived:
        return 'Archivé';
    }
  }

  String get icon {
    switch (this) {
      case BatchStatus.active:
        return '✓';
      case BatchStatus.empty:
        return '○';
      case BatchStatus.archived:
        return '📦';
    }
  }

  static BatchStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return BatchStatus.active;
      case 'empty':
        return BatchStatus.empty;
      case 'archived':
        return BatchStatus.archived;
      default:
        return BatchStatus.active;
    }
  }
}

/// Lot de cartouches fabriquées
class Batch {
  final int? id;
  final String lotNumber;         // Numéro de lot (ex: "1001")
  final int recipeId;
  final String? recipeName;       // Cache pour l'affichage
  final String? weaponId;
  final String? weaponName;       // Cache pour l'affichage
  final int quantityInitial;      // Nombre de cartouches fabriquées
  final int quantityRemaining;    // Nombre de cartouches restantes
  final BatchStatus status;
  final DateTime fabricationDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Batch({
    this.id,
    required this.lotNumber,
    required this.recipeId,
    this.recipeName,
    this.weaponId,
    this.weaponName,
    required this.quantityInitial,
    required this.quantityRemaining,
    this.status = BatchStatus.active,
    required this.fabricationDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Pourcentage de cartouches consommées
  double get consumedPercentage {
    if (quantityInitial == 0) return 0;
    return ((quantityInitial - quantityRemaining) / quantityInitial) * 100;
  }

  /// Pourcentage de cartouches restantes
  double get remainingPercentage {
    if (quantityInitial == 0) return 0;
    return (quantityRemaining / quantityInitial) * 100;
  }

  /// Nombre de cartouches tirées
  int get quantityUsed => quantityInitial - quantityRemaining;

  /// Vérifie si le lot est vide
  bool get isEmpty => quantityRemaining <= 0;

  /// Affichage du lot
  String get displayName => 'Lot #$lotNumber';

  /// Résumé du lot
  String get summary {
    return '$quantityRemaining/$quantityInitial restantes';
  }

  /// Affichage complet
  String get fullDisplayName {
    final parts = [displayName];
    if (recipeName != null) parts.add(recipeName!);
    if (weaponName != null) parts.add(weaponName!);
    return parts.join(' - ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lot_number': lotNumber,
      'recipe_id': recipeId,
      'recipe_name': recipeName,
      'weapon_id': weaponId,
      'weapon_name': weaponName,
      'quantity_initial': quantityInitial,
      'quantity_remaining': quantityRemaining,
      'status': status.name,
      'fabrication_date': fabricationDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'] as int?,
      lotNumber: map['lot_number'] as String,
      recipeId: map['recipe_id'] as int,
      recipeName: map['recipe_name'] as String?,
      weaponId: map['weapon_id'] as String?,
      weaponName: map['weapon_name'] as String?,
      quantityInitial: map['quantity_initial'] as int,
      quantityRemaining: map['quantity_remaining'] as int,
      status: BatchStatusExtension.fromString(map['status'] as String? ?? 'active'),
      fabricationDate: DateTime.parse(map['fabrication_date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Batch copyWith({
    int? id,
    String? lotNumber,
    int? recipeId,
    String? recipeName,
    String? weaponId,
    String? weaponName,
    int? quantityInitial,
    int? quantityRemaining,
    BatchStatus? status,
    DateTime? fabricationDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Batch(
      id: id ?? this.id,
      lotNumber: lotNumber ?? this.lotNumber,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      weaponId: weaponId ?? this.weaponId,
      weaponName: weaponName ?? this.weaponName,
      quantityInitial: quantityInitial ?? this.quantityInitial,
      quantityRemaining: quantityRemaining ?? this.quantityRemaining,
      status: status ?? this.status,
      fabricationDate: fabricationDate ?? this.fabricationDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
