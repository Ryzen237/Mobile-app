// Modèle de données pour les devis
class Quote {
  final String clientName;
  final String product;
  final int quantity;
  final String description;
  final double unitPrice;
  final double total;

  Quote({
    required this.clientName,
    required this.product,
    required this.quantity,
    required this.description,
    required this.unitPrice,
  }) : total = quantity * unitPrice;

  // Méthode pour créer une copie avec des modifications
  Quote copyWith({
    String? clientName,
    String? product,
    int? quantity,
    String? description,
    double? unitPrice,
  }) {
    return Quote(
      clientName: clientName ?? this.clientName,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  // Méthode pour convertir en Map (utile pour la persistance)
  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'product': product,
      'quantity': quantity,
      'description': description,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  // Factory pour créer depuis un Map
  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      clientName: map['clientName'] ?? '',
      product: map['product'] ?? '',
      quantity: map['quantity'] ?? 0,
      description: map['description'] ?? '',
      unitPrice: map['unitPrice'] ?? 0.0,
    );
  }
}
