import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quote.dart';
import '../models/order.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  SharedPreferences? _prefs;

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (isWeb) {
      // For web, we'll use a mock database that doesn't actually persist
      // In a real app, you'd use a web-compatible storage solution
      throw UnsupportedError('Database not supported on web platform');
    }

    _database = await _initDatabase();
    return _database!;
  }

  // Safe database access method
  Future<Database?> getDatabaseSafe() async {
    try {
      return await database;
    } catch (e) {
      print('Erreur d\'accès à la base de données: $e');
      return null;
    }
  }

  // Platform detection method
  bool get isWeb => kIsWeb;

  Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'quote_order_app.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      print('Erreur lors de l\'initialisation de la base de données: $e');
      throw UnsupportedError('Database initialization failed: $e');
    }
  }

  Future _onCreate(Database db, int version) async {
    // Créer la table users
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        company TEXT,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Créer la table quotes
    await db.execute('''
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_name TEXT NOT NULL,
        product TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        description TEXT,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        user_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Créer la table orders
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        total REAL NOT NULL,
        date TEXT NOT NULL,
        customer_name TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Créer la table order_items
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // Créer la table products (pour le catalogue)
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Insérer des produits de démonstration
    await _insertDemoProducts(db);
  }

  Future _insertDemoProducts(Database db) async {
    final demoProducts = [
      {'name': 'Produit A', 'price': 25.0, 'category': 'Électronique', 'description': 'Produit électronique haute qualité'},
      {'name': 'Produit B', 'price': 40.0, 'category': 'Électronique', 'description': 'Innovation technologique'},
      {'name': 'Service C', 'price': 60.0, 'category': 'Services', 'description': 'Service professionnel'},
      {'name': 'Produit D', 'price': 15.0, 'category': 'Accessoires', 'description': 'Accessoire pratique'},
      {'name': 'Produit E', 'price': 80.0, 'category': 'Premium', 'description': 'Produit haut de gamme'},
      {'name': 'Service F', 'price': 120.0, 'category': 'Services', 'description': 'Service expert'},
    ];

    for (var product in demoProducts) {
      await db.insert('products', {
        ...product,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ==================== USER OPERATIONS ====================

  Future<User?> insertUser(User user) async {
    try {
      final db = await database;
      final id = await db.insert('users', user.toMap());
      return user;
    } catch (e) {
      print('Erreur lors de l\'insertion utilisateur: $e');
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final db = await database;
      final maps = await db.query(
        'users',
        where: 'email = ? AND is_active = 1',
        whereArgs: [email],
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération utilisateur: $e');
      return null;
    }
  }

  Future<User?> getUserById(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération utilisateur par ID: $e');
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final db = await database;
      final maps = await db.query('users', where: 'is_active = 1');
      return maps.map((map) => User.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  // ==================== DATABASE RESET ====================

  Future<void> resetDatabase() async {
    try {
      final db = await database;
      await db.delete('order_items');
      await db.delete('orders');
      await db.delete('quotes');
      await db.delete('users');
      await db.delete('products');

      // Recreate tables
      await _onCreate(db, 1);

      print('Base de données réinitialisée avec succès');
    } catch (e) {
      print('Erreur lors de la réinitialisation de la base de données: $e');
    }
  }

  // ==================== QUOTE OPERATIONS ====================

  Future<int> insertQuote(Quote quote, String? userId) async {
    try {
      final db = await database;
      return await db.insert('quotes', {
        'client_name': quote.clientName,
        'product': quote.product,
        'quantity': quote.quantity,
        'description': quote.description,
        'unit_price': quote.unitPrice,
        'total': quote.total,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erreur lors de l\'insertion du devis: $e');
      return 0;
    }
  }

  Future<List<Quote>> getQuotesByUserId(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'quotes',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => Quote(
        clientName: map['client_name'] as String,
        product: map['product'] as String,
        quantity: map['quantity'] as int,
        description: map['description'] as String,
        unitPrice: map['unit_price'] as double,
      )).toList();
    } catch (e) {
      print('Erreur lors de la récupération des devis: $e');
      return [];
    }
  }

  Future<List<Quote>> getAllQuotes() async {
    try {
      final db = await database;
      final maps = await db.query('quotes', orderBy: 'created_at DESC');
      return maps.map((map) => Quote(
        clientName: map['client_name'] as String,
        product: map['product'] as String,
        quantity: map['quantity'] as int,
        description: map['description'] as String,
        unitPrice: map['unit_price'] as double,
      )).toList();
    } catch (e) {
      print('Erreur lors de la récupération de tous les devis: $e');
      return [];
    }
  }

  // ==================== ORDER OPERATIONS ====================

  Future<String> insertOrder(Order order, String? userId) async {
    try {
      final db = await database;
      final orderId = order.id;

      // Insérer la commande
      await db.insert('orders', {
        'id': orderId,
        'user_id': userId,
        'total': order.total,
        'date': order.date.toIso8601String(),
        'customer_name': order.customerName,
        'status': 'pending',
      });

      // Insérer les éléments de commande
      for (var item in order.items) {
        await db.insert('order_items', {
          'order_id': orderId,
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
        });
      }

      return orderId;
    } catch (e) {
      print('Erreur lors de l\'insertion de la commande: $e');
      return '';
    }
  }

  Future<List<Order>> getOrdersByUserId(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'orders',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );

      final orders = <Order>[];

      for (var map in maps) {
        try {
          final orderId = map['id'] as String?;
          if (orderId == null || orderId.isEmpty) continue;

          final items = await getOrderItems(orderId);

          // Gestion sécurisée de la date
          DateTime orderDate;
          try {
            final dateStr = map['date'] as String?;
            orderDate = dateStr != null && dateStr.isNotEmpty
                ? DateTime.parse(dateStr)
                : DateTime.now();
          } catch (e) {
            print('Erreur de date pour la commande $orderId: $e');
            orderDate = DateTime.now();
          }

          orders.add(Order(
            id: orderId,
            items: items,
            total: (map['total'] as num?)?.toDouble() ?? 0.0,
            date: orderDate,
            customerName: map['customer_name'] as String?,
          ));
        } catch (e) {
          print('Erreur lors du traitement de la commande ${map['id']}: $e');
          continue; // Skip this order and continue with others
        }
      }

      return orders;
    } catch (e) {
      print('Erreur lors de la récupération des commandes: $e');
      return [];
    }
  }

  Future<List<Order>> getAllOrders() async {
    try {
      final db = await database;
      final maps = await db.query('orders', orderBy: 'date DESC');

      final orders = <Order>[];

      for (var map in maps) {
        try {
          final orderId = map['id'] as String?;
          if (orderId == null || orderId.isEmpty) continue;

          final items = await getOrderItems(orderId);

          // Gestion sécurisée de la date
          DateTime orderDate;
          try {
            final dateStr = map['date'] as String?;
            orderDate = dateStr != null && dateStr.isNotEmpty
                ? DateTime.parse(dateStr)
                : DateTime.now();
          } catch (e) {
            print('Erreur de date pour la commande $orderId: $e');
            orderDate = DateTime.now();
          }

          orders.add(Order(
            id: orderId,
            items: items,
            total: (map['total'] as num?)?.toDouble() ?? 0.0,
            date: orderDate,
            customerName: map['customer_name'] as String?,
          ));
        } catch (e) {
          print('Erreur lors du traitement de la commande ${map['id']}: $e');
          continue; // Skip this order and continue with others
        }
      }

      return orders;
    } catch (e) {
      print('Erreur lors de la récupération de toutes les commandes: $e');
      return [];
    }
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      return maps.map((map) => OrderItem(
        name: map['name']?.toString() ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      )).toList();
    } catch (e) {
      print('Erreur lors de la récupération des éléments de commande: $e');
      return [];
    }
  }

  // ==================== PRODUCT OPERATIONS ====================

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final db = await database;
      return await db.query('products', where: 'is_active = 1');
    } catch (e) {
      print('Erreur lors de la récupération des produits: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    try {
      final db = await database;
      return await db.query(
        'products',
        where: 'category = ? AND is_active = 1',
        whereArgs: [category],
      );
    } catch (e) {
      print('Erreur lors de la récupération des produits par catégorie: $e');
      return [];
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final db = await database;
      final maps = await db.rawQuery(
        'SELECT DISTINCT category FROM products WHERE is_active = 1 ORDER BY category'
      );
      return maps.map((map) => map['category'] as String).toList();
    } catch (e) {
      print('Erreur lors de la récupération des catégories: $e');
      return [];
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('order_items');
      await db.delete('orders');
      await db.delete('quotes');
      await db.delete('users');
    } catch (e) {
      print('Erreur lors de la suppression des données: $e');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
