// Modèle de données pour les commandes
class OrderItem {
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    required this.name,
    required this.price,
    required this.quantity
  });

  // Calcul du total pour cet item
  double get total => price * quantity;

  // Méthode pour créer une copie avec des modifications
  OrderItem copyWith({
    String? name,
    double? price,
    int? quantity,
  }) {
    return OrderItem(
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  // Conversion en Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  // Factory depuis Map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      price: map['price'] ?? 0.0,
      quantity: map['quantity'] ?? 0,
    );
  }
}

class Order {
  final String id;
  final List<OrderItem> items;
  final double total;
  final DateTime date;
  final String? customerName;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.date,
    this.customerName,
  });

  // Calcul du nombre total d'articles
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  // Méthode pour créer une copie avec des modifications
  Order copyWith({
    String? id,
    List<OrderItem>? items,
    double? total,
    DateTime? date,
    String? customerName,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      total: total ?? this.total,
      date: date ?? this.date,
      customerName: customerName ?? this.customerName,
    );
  }

  // Conversion en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'date': date.toIso8601String(),
      'customerName': customerName,
    };
  }

  // Factory depuis Map
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      total: map['total'] ?? 0.0,
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      customerName: map['customerName'],
    );
  }
}
