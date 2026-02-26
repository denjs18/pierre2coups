/// Type de transaction de stock
enum TransactionType {
  purchase,     // Achat / Entrée en stock
  fabrication,  // Consommation lors de la fabrication
  recycling,    // Recyclage des étuis
  adjustment,   // Ajustement manuel
  waste,        // Perte / Déchet
}

extension TransactionTypeExtension on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.purchase:
        return 'Achat';
      case TransactionType.fabrication:
        return 'Fabrication';
      case TransactionType.recycling:
        return 'Recyclage';
      case TransactionType.adjustment:
        return 'Ajustement';
      case TransactionType.waste:
        return 'Perte';
    }
  }

  String get icon {
    switch (this) {
      case TransactionType.purchase:
        return '📥';
      case TransactionType.fabrication:
        return '🔨';
      case TransactionType.recycling:
        return '♻️';
      case TransactionType.adjustment:
        return '✏️';
      case TransactionType.waste:
        return '🗑️';
    }
  }

  /// true si la transaction ajoute du stock, false si elle en retire
  bool get isAddition {
    switch (this) {
      case TransactionType.purchase:
      case TransactionType.recycling:
        return true;
      case TransactionType.fabrication:
      case TransactionType.waste:
        return false;
      case TransactionType.adjustment:
        return true; // Dépend de la quantité (peut être + ou -)
    }
  }

  static TransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'purchase':
        return TransactionType.purchase;
      case 'fabrication':
        return TransactionType.fabrication;
      case 'recycling':
        return TransactionType.recycling;
      case 'adjustment':
        return TransactionType.adjustment;
      case 'waste':
        return TransactionType.waste;
      default:
        return TransactionType.adjustment;
    }
  }
}

/// Transaction de stock (historique des mouvements)
class StockTransaction {
  final int? id;
  final int componentId;
  final String? componentName;     // Cache pour l'affichage
  final TransactionType type;
  final double quantity;           // Quantité (positive ou négative)
  final double balanceAfter;       // Solde après transaction
  final int? batchId;              // Référence au lot si fabrication
  final int? sessionId;            // Référence à la session si recyclage
  final String? notes;
  final DateTime createdAt;

  StockTransaction({
    this.id,
    required this.componentId,
    this.componentName,
    required this.type,
    required this.quantity,
    required this.balanceAfter,
    this.batchId,
    this.sessionId,
    this.notes,
    required this.createdAt,
  });

  /// Affichage formaté de la quantité avec signe
  String get formattedQuantity {
    final sign = quantity >= 0 ? '+' : '';
    return '$sign${quantity.toStringAsFixed(quantity == quantity.roundToDouble() ? 0 : 1)}';
  }

  /// Affichage de la transaction
  String get displaySummary {
    return '${type.icon} ${type.label}: $formattedQuantity';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'component_id': componentId,
      'type': type.name,
      'quantity': quantity,
      'balance_after': balanceAfter,
      'batch_id': batchId,
      'session_id': sessionId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockTransaction.fromMap(Map<String, dynamic> map) {
    return StockTransaction(
      id: map['id'] as int?,
      componentId: map['component_id'] as int,
      componentName: map['component_name'] as String?,
      type: TransactionTypeExtension.fromString(map['type'] as String),
      quantity: (map['quantity'] as num).toDouble(),
      balanceAfter: (map['balance_after'] as num).toDouble(),
      batchId: map['batch_id'] as int?,
      sessionId: map['session_id'] as int?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  StockTransaction copyWith({
    int? id,
    int? componentId,
    String? componentName,
    TransactionType? type,
    double? quantity,
    double? balanceAfter,
    int? batchId,
    int? sessionId,
    String? notes,
    DateTime? createdAt,
  }) {
    return StockTransaction(
      id: id ?? this.id,
      componentId: componentId ?? this.componentId,
      componentName: componentName ?? this.componentName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      batchId: batchId ?? this.batchId,
      sessionId: sessionId ?? this.sessionId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
