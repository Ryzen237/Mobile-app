import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/quote.dart';
import '../models/user.dart';
import '../services/quote_service.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppState extends ChangeNotifier {
  // Services
  final QuoteService _quoteService = QuoteService();
  final OrderService _orderService = OrderService();
  final UserService _userService = UserService();
  final DatabaseService _databaseService = DatabaseService();

  // État de l'application
  List<Quote> _quotes = [];
  List<Order> _orders = [];
  List<OrderItem> _cart = [];
  User? _currentUser;
  bool _isLoading = false;

  // Getters
  QuoteService get quoteService => _quoteService;
  OrderService get orderService => _orderService;
  UserService get userService => _userService;
  DatabaseService get databaseService => _databaseService;

  List<Quote> get quotes => _quotes;
  List<Order> get orders => _orders;
  List<OrderItem> get cart => _cart;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  double get cartTotal => _orderService.calculateCartTotal(_cart);

  // Gestion des devis
  void addQuote(Quote quote) {
    _quotes.add(quote);
    notifyListeners();
  }

  void removeQuote(String clientName) {
    _quotes.removeWhere((quote) => quote.clientName == clientName);
    notifyListeners();
  }

  // Gestion du panier
  void addToCart(String productName, double price) {
    _cart = _orderService.addToCart(_cart, productName, price);
    notifyListeners();
  }

  void removeFromCart(String productName) {
    _cart = _orderService.removeFromCart(_cart, productName);
    notifyListeners();
  }

  void updateCartQuantity(String productName, int quantity) {
    _cart = _orderService.updateQuantity(_cart, productName, quantity);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // Gestion des commandes
  void addOrder(Order order) {
    _orders.add(order);
    clearCart(); // Vider le panier après commande
    notifyListeners();
  }

  void removeOrder(String orderId) {
    _orders.removeWhere((order) => order.id == orderId);
    notifyListeners();
  }

  // Méthode publique pour mettre à jour les commandes (utilisée par les screens)
  void updateOrders(List<Order> orders) {
    _orders.clear();
    _orders.addAll(orders);
    notifyListeners();
  }

  // Méthode publique pour mettre à jour les devis (utilisée par les screens)
  void updateQuotes(List<Quote> quotes) {
    _quotes.clear();
    _quotes.addAll(quotes);
    notifyListeners();
  }

  // État de chargement
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Création d'une commande depuis le panier
  Order? createOrderFromCart({String? customerName}) {
    if (_cart.isEmpty) return null;

    final order = _orderService.createOrderFromCart(_cart, customerName: customerName);
    addOrder(order);
    return order;
  }

  // Gestion de l'utilisateur actuel
  void setCurrentUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _cart.clear();
    _quotes.clear();
    _orders.clear();
    notifyListeners();
  }

  // ==================== CROSS-PLATFORM OPERATIONS ====================

  // Charger les données depuis la base de données
  Future<void> loadUserData() async {
    if (_currentUser == null) {
      print('Aucun utilisateur actuel défini');
      return;
    }

    print('Chargement des données pour l\'utilisateur: ${_currentUser!.id}');

    setLoading(true);
    try {
      if (kIsWeb) {
        // Use StorageService for web
        final storageService = StorageService();
        _quotes = await storageService.getAllQuotes();
        _orders = await storageService.getAllOrders();
        print('Données web chargées: ${_quotes.length} devis, ${_orders.length} commandes');
      } else {
        // Use DatabaseService for mobile
        try {
          _quotes = await _databaseService.getQuotesByUserId(_currentUser!.id);
          _orders = await _databaseService.getOrdersByUserId(_currentUser!.id);
          print('Données mobile chargées: ${_quotes.length} devis, ${_orders.length} commandes');
        } catch (e) {
          print('Erreur lors du chargement des données utilisateur mobile: $e');
          // Fallback to all data
          try {
            _quotes = await _databaseService.getAllQuotes();
            _orders = await _databaseService.getAllOrders();
            print('Données fallback chargées: ${_quotes.length} devis, ${_orders.length} commandes');
          } catch (fallbackError) {
            print('Erreur fallback mobile: $fallbackError');
            _quotes = [];
            _orders = [];
          }
        }
      }

      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
      // En cas d'erreur, essayer de charger toutes les données comme fallback
      try {
        if (kIsWeb) {
          final storageService = StorageService();
          _quotes = await storageService.getAllQuotes();
          _orders = await storageService.getAllOrders();
        } else {
          _quotes = await _databaseService.getAllQuotes();
          _orders = await _databaseService.getAllOrders();
        }
        notifyListeners();
      } catch (fallbackError) {
        print('Erreur fallback: $fallbackError');
        // Reset to empty lists if everything fails
        _quotes = [];
        _orders = [];
        notifyListeners();
      }
    } finally {
      setLoading(false);
    }
  }

  // Sauvegarder un devis dans la base de données
  Future<bool> saveQuote(Quote quote) async {
    try {
      if (kIsWeb) {
        final storageService = StorageService();
        final success = await storageService.insertQuote(quote, _currentUser?.id);
        if (success > 0) {
          _quotes.add(quote);
          notifyListeners();
          return true;
        }
      } else {
        final id = await _databaseService.insertQuote(quote, _currentUser?.id);
        if (id > 0) {
          _quotes.add(quote);
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Erreur lors de la sauvegarde du devis: $e');
      return false;
    }
  }

  // Sauvegarder une commande dans la base de données
  Future<bool> saveOrder(Order order) async {
    try {
      if (kIsWeb) {
        final storageService = StorageService();
        final orderId = await storageService.insertOrder(order, _currentUser?.id);
        if (orderId.isNotEmpty) {
          _orders.add(order);
          clearCart();
          notifyListeners();
          return true;
        }
      } else {
        final orderId = await _databaseService.insertOrder(order, _currentUser?.id);
        if (orderId.isNotEmpty) {
          _orders.add(order);
          clearCart();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Erreur lors de la sauvegarde de la commande: $e');
      return false;
    }
  }

  // ==================== INITIALIZATION ====================

  // Initialiser l'application avec les données de démonstration
  Future<void> initialize() async {
    setLoading(true);
    try {
      // Créer un utilisateur de démonstration si nécessaire
      if (_currentUser == null) {
        final demoUser = await _createDemoUser();
        if (demoUser != null) {
          _currentUser = demoUser;
        }
      }

      // Charger les données depuis la base de données
      await loadUserData();
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<User?> _createDemoUser() async {
    try {
      final demoUser = User(
        id: 'USER_DEMO_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Utilisateur Demo',
        email: 'demo@exemple.com',
        createdAt: DateTime.now(),
      );

      if (kIsWeb) {
        final storageService = StorageService();
        return await storageService.insertUser(demoUser);
      } else {
        try {
          return await _databaseService.insertUser(demoUser);
        } catch (e) {
          print('Erreur base de données mobile: $e');
          // Return the user even if database insertion fails
          return demoUser;
        }
      }
    } catch (e) {
      print('Erreur lors de la création de l\'utilisateur de démonstration: $e');
      return null;
    }
  }

  // Statistiques
  int get totalQuotes => _quotes.length;
  int get totalOrders => _orders.length;
  double get totalSales => _orders.fold(0.0, (sum, order) => sum + order.total);
  int get totalCartItems => _cart.fold(0, (sum, item) => sum + item.quantity);
}
