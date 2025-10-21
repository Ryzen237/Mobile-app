import '../models/order.dart';

class OrderService {
  // Singleton pattern
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  // Catalogue de produits disponibles
  final List<Map<String, dynamic>> _availableProducts = [
    {'name': 'Produit A', 'price': 25.0, 'category': 'Électronique'},
    {'name': 'Produit B', 'price': 40.0, 'category': 'Électronique'},
    {'name': 'Service C', 'price': 60.0, 'category': 'Services'},
    {'name': 'Produit D', 'price': 15.0, 'category': 'Accessoires'},
  ];

  // Getter pour les produits disponibles
  List<Map<String, dynamic>> get availableProducts => _availableProducts;

  // Méthode pour ajouter un produit au panier
  List<OrderItem> addToCart(List<OrderItem> currentCart, String productName, double price) {
    final updatedCart = List<OrderItem>.from(currentCart);
    final existingIndex = updatedCart.indexWhere((item) => item.name == productName);

    if (existingIndex != -1) {
      // Augmenter la quantité si le produit existe déjà
      updatedCart[existingIndex] = updatedCart[existingIndex].copyWith(
        quantity: updatedCart[existingIndex].quantity + 1,
      );
    } else {
      // Ajouter le nouveau produit
      updatedCart.add(OrderItem(name: productName, price: price, quantity: 1));
    }

    return updatedCart;
  }

  // Méthode pour calculer le total du panier
  double calculateCartTotal(List<OrderItem> cart) {
    return cart.fold(0.0, (sum, item) => sum + item.total);
  }

  // Méthode pour supprimer un produit du panier
  List<OrderItem> removeFromCart(List<OrderItem> currentCart, String productName) {
    return currentCart.where((item) => item.name != productName).toList();
  }

  // Méthode pour modifier la quantité d'un produit
  List<OrderItem> updateQuantity(List<OrderItem> currentCart, String productName, int newQuantity) {
    if (newQuantity <= 0) {
      return removeFromCart(currentCart, productName);
    }

    final updatedCart = List<OrderItem>.from(currentCart);
    final existingIndex = updatedCart.indexWhere((item) => item.name == productName);

    if (existingIndex != -1) {
      updatedCart[existingIndex] = updatedCart[existingIndex].copyWith(
        quantity: newQuantity,
      );
    }

    return updatedCart;
  }

  // Méthode pour créer une commande depuis le panier
  Order createOrderFromCart(List<OrderItem> cart, {String? customerName}) {
    final total = calculateCartTotal(cart);
    final orderId = _generateOrderId();

    return Order(
      id: orderId,
      items: List<OrderItem>.from(cart),
      total: total,
      date: DateTime.now(),
      customerName: customerName,
    );
  }

  // Méthode pour valider le panier avant commande
  Map<String, String?> validateCart(List<OrderItem> cart) {
    final errors = <String, String?>{};

    if (cart.isEmpty) {
      errors['cart'] = 'Le panier ne peut pas être vide';
    }

    for (final item in cart) {
      if (item.quantity <= 0) {
        errors['item_${item.name}'] = 'La quantité doit être positive';
      }
      if (item.price < 0) {
        errors['price_${item.name}'] = 'Le prix ne peut pas être négatif';
      }
    }

    return errors;
  }

  // Méthode pour formater le prix
  String formatPrice(double price) {
    return '${price.toStringAsFixed(2)}FCFA';
  }

  // Méthode pour générer un ID de commande unique
  String _generateOrderId() {
    return 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Méthode pour filtrer les produits par catégorie
  List<Map<String, dynamic>> getProductsByCategory(String category) {
    return _availableProducts.where((product) => product['category'] == category).toList();
  }

  // Méthode pour rechercher des produits
  List<Map<String, dynamic>> searchProducts(String query) {
    final lowerQuery = query.toLowerCase();
    return _availableProducts.where((product) =>
      product['name'].toLowerCase().contains(lowerQuery) ||
      product['category'].toLowerCase().contains(lowerQuery)
    ).toList();
  }
}
