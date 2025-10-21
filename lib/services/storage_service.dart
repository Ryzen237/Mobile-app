import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/quote.dart';
import '../models/order.dart';
import '../models/user.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==================== PLATFORM DETECTION ====================

  bool get isWeb => kIsWeb;

  // ==================== USER OPERATIONS ====================

  Future<User?> insertUser(User user) async {
    try {
      if (isWeb) {
        final prefs = await this.prefs;
        await prefs.setString('user_${user.id}', user.toJson());
        return user;
      } else {
        // For mobile, this would use the database service
        throw UnsupportedError('Use DatabaseService for mobile platforms');
      }
    } catch (e) {
      print('Erreur lors de l\'insertion utilisateur: $e');
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      if (isWeb) {
        final prefs = await this.prefs;
        final keys = prefs.getKeys().where((key) => key.startsWith('user_'));

        for (String key in keys) {
          final userJson = prefs.getString(key);
          if (userJson != null) {
            final user = JsonConverters.userFromJson(userJson);
            if (user.email == email && user.isActive) {
              return user;
            }
          }
        }
        return null;
      } else {
        throw UnsupportedError('Use DatabaseService for mobile platforms');
      }
    } catch (e) {
      print('Erreur lors de la récupération utilisateur: $e');
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      if (isWeb) {
        final prefs = await this.prefs;
        final keys = prefs.getKeys().where((key) => key.startsWith('user_'));
        final users = <User>[];

        for (String key in keys) {
          final userJson = prefs.getString(key);
          if (userJson != null) {
            final user = JsonConverters.userFromJson(userJson);
            if (user.isActive) {
              users.add(user);
            }
          }
        }
        return users;
      } else {
        throw UnsupportedError('Use DatabaseService for mobile platforms');
      }
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  // ==================== QUOTE OPERATIONS ====================

  Future<int> insertQuote(Quote quote, String? userId) async {
    try {
      if (isWeb) {
        final prefs = await this.prefs;
        final quoteId = 'quote_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString(quoteId, quote.toJson());
        return 1; // Return 1 to indicate success
      } else {
        throw UnsupportedError('Use DatabaseService for mobile platforms');
      }
    } catch (e) {
      print('Erreur lors de l\'insertion du devis: $e');
      return 0;
    }
  }

  Future<List<Quote>> getAllQuotes() async {
    try {
      if (isWeb) {
        final prefs = await this.prefs;
        final keys = prefs.getKeys().where((key) => key.startsWith('quote_'));
        final quotes = <Quote>[];

        for (String key in keys) {
          final quoteJson = prefs.getString(key);
          if (quoteJson != null) {
            try {
              final quote = JsonConverters.quoteFromJson(quoteJson);
              quotes.add(quote);
            } catch (e) {
              print('Erreur lors du parsing du devis $key: $e');
            }
          }
        }
        return quotes;
      } else {
        throw UnsupportedError('Use DatabaseService for mobile platforms');
      }
    } catch (e) {
      print('Erreur lors de la récupération de tous les devis: $e');
      return [];
    }
  }

  // ==================== ORDER OPERATIONS ====================

  Future<String> insertOrder(Order order, String? userId) async {
    try {
      if (isWeb) {
        final prefs = await this.prefs;
        final orderId = order.id;
        await prefs.setString('order_$orderId', order.toJson());

        // Save order items
        for (var item in order.items) {
          await prefs.setString('order_item_${orderId}_${item.name}', item.toJson());
        }

        return orderId;
      } else {
        throw UnsupportedError('Use DatabaseService for mobile platforms');
      }
    } catch (e) {
      print('Erreur lors de l\'insertion de la commande: $e');
      return '';
    }
  }

  Future<List<Order>> getAllOrders() async {
    try {
      if (isWeb) {
        final prefs = await this.prefs;
        final keys = prefs.getKeys().where((key) => key.startsWith('order_') && !key.contains('_item_'));
        final orders = <Order>[];

        for (String key in keys) {
          final orderJson = prefs.getString(key);
          if (orderJson != null) {
            try {
              final order = JsonConverters.orderFromJson(orderJson);
              orders.add(order);
            } catch (e) {
              print('Erreur lors du parsing de la commande $key: $e');
            }
          }
        }
        return orders;
      } else {
        throw UnsupportedError('Use DatabaseService for mobile platforms');
      }
    } catch (e) {
      print('Erreur lors de la récupération de toutes les commandes: $e');
      return [];
    }
  }

  // ==================== PRODUCT OPERATIONS ====================

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      if (isWeb) {
        // Return demo products for web
        return [
          {'id': 1, 'name': 'Produit A', 'price': 25.0, 'category': 'Électronique', 'description': 'Produit électronique haute qualité'},
          {'id': 2, 'name': 'Produit B', 'price': 40.0, 'category': 'Électronique', 'description': 'Innovation technologique'},
          {'id': 3, 'name': 'Service C', 'price': 60.0, 'category': 'Services', 'description': 'Service professionnel'},
          {'id': 4, 'name': 'Produit D', 'price': 15.0, 'category': 'Accessoires', 'description': 'Accessoire pratique'},
          {'id': 5, 'name': 'Produit E', 'price': 80.0, 'category': 'Premium', 'description': 'Produit haut de gamme'},
          {'id': 6, 'name': 'Service F', 'price': 120.0, 'category': 'Services', 'description': 'Service expert'},
        ];
      } else {
        throw UnsupportedError('Use DatabaseService for mobile platforms');
      }
    } catch (e) {
      print('Erreur lors de la récupération des produits: $e');
      return [];
    }
  }

  Future<List<String>> getCategories() async {
    try {
      if (isWeb) {
        return ['Tous', 'Électronique', 'Services', 'Accessoires', 'Premium'];
      } else {
        throw UnsupportedError('Use DatabaseService for mobile platforms');
      }
    } catch (e) {
      print('Erreur lors de la récupération des catégories: $e');
      return [];
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  Future<void> clearAllData() async {
    try {
      if (isWeb) {
        final prefs = await this.prefs;
        final keys = prefs.getKeys();
        for (String key in keys) {
          await prefs.remove(key);
        }
      } else {
        throw UnsupportedError('Use DatabaseService for mobile platforms');
      }
    } catch (e) {
      print('Erreur lors de la suppression des données: $e');
    }
  }
}

// ==================== JSON EXTENSIONS ====================

extension UserJson on User {
  String toJson() {
    return '{"id":"$id","name":"$name","email":"$email","phone":${phone != null ? '"$phone"' : 'null'},"company":${company != null ? '"$company"' : 'null'},"createdAt":"$createdAt","isActive":$isActive}';
  }
}

extension QuoteJson on Quote {
  String toJson() {
    return '{"clientName":"$clientName","product":"$product","quantity":$quantity,"description":"$description","unitPrice":$unitPrice,"total":$total}';
  }
}

extension OrderJson on Order {
  String toJson() {
    return '{"id":"$id","total":$total,"date":"$date","customerName":${customerName != null ? '"$customerName"' : 'null'}}';
  }
}

extension OrderItemJson on OrderItem {
  String toJson() {
    return '{"name":"$name","price":$price,"quantity":$quantity}';
  }
}

// Static factory methods for JSON parsing
class JsonConverters {
  static User userFromJson(String json) {
    final id = _extractJsonValue(json, 'id');
    final name = _extractJsonValue(json, 'name');
    final email = _extractJsonValue(json, 'email');
    final phone = _extractJsonValue(json, 'phone');
    final company = _extractJsonValue(json, 'company');
    final createdAt = _extractJsonValue(json, 'createdAt');
    final isActive = _extractJsonValue(json, 'isActive') == 'true';

    return User(
      id: id,
      name: name,
      email: email,
      phone: phone.isEmpty ? null : phone,
      company: company.isEmpty ? null : company,
      createdAt: DateTime.parse(createdAt),
      isActive: isActive,
    );
  }

  static Quote quoteFromJson(String json) {
    final clientName = _extractJsonValue(json, 'clientName');
    final product = _extractJsonValue(json, 'product');
    final quantity = int.parse(_extractJsonValue(json, 'quantity'));
    final description = _extractJsonValue(json, 'description');
    final unitPrice = double.parse(_extractJsonValue(json, 'unitPrice'));
    final total = double.parse(_extractJsonValue(json, 'total'));

    return Quote(
      clientName: clientName,
      product: product,
      quantity: quantity,
      description: description,
      unitPrice: unitPrice,
    );
  }

  static Order orderFromJson(String json) {
    final id = _extractJsonValue(json, 'id');
    final total = double.parse(_extractJsonValue(json, 'total'));
    final date = _extractJsonValue(json, 'date');
    final customerName = _extractJsonValue(json, 'customerName');

    return Order(
      id: id,
      items: [], // Simplified for web storage
      total: total,
      date: DateTime.parse(date),
      customerName: customerName.isEmpty ? null : customerName,
    );
  }

  static OrderItem orderItemFromJson(String json) {
    final name = _extractJsonValue(json, 'name');
    final price = double.parse(_extractJsonValue(json, 'price'));
    final quantity = int.parse(_extractJsonValue(json, 'quantity'));

    return OrderItem(
      name: name,
      price: price,
      quantity: quantity,
    );
  }
}

String _extractJsonValue(String json, String key) {
  final regex = RegExp('"$key"\\s*:\\s*"([^"]*)"');
  final match = regex.firstMatch(json);
  if (match != null) {
    return match.group(1) ?? '';
  }

  // Try for numeric values
  final regexNum = RegExp('"$key"\\s*:\\s*([0-9.]+)');
  final matchNum = regexNum.firstMatch(json);
  if (matchNum != null) {
    return matchNum.group(1) ?? '';
  }

  // Try for boolean values
  final regexBool = RegExp('"$key"\\s*:\\s*(true|false)');
  final matchBool = regexBool.firstMatch(json);
  if (matchBool != null) {
    return matchBool.group(1) ?? 'false';
  }

  return '';
}
