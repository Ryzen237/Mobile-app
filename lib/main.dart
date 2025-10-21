import 'package:flutter/material.dart';

void main() {
  runApp(const QuoteOrderApp());
}

class QuoteOrderApp extends StatelessWidget {
  const QuoteOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quote & Order App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote & Order App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Gestion des Devis et Commandes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuotePage()),
                );
              },
              icon: const Icon(Icons.request_quote),
              label: const Text('Faire un devis'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderPage()),
                );
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Passer une commande'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrdersListPage()),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('Voir mes commandes'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
}

// Modèle de données pour les commandes
class OrderItem {
  final String name;
  final double price;
  final int quantity;

  OrderItem({required this.name, required this.price, required this.quantity});
}

class Order {
  final String id;
  final List<OrderItem> items;
  final double total;
  final DateTime date;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.date,
  });
}

// Écran de création de devis
class QuotePage extends StatefulWidget {
  const QuotePage({super.key});

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  double? _total;

  void _calculateTotal() {
    if (_quantityController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      final price = double.tryParse(_priceController.text) ?? 0.0;
      setState(() {
        _total = quantity * price;
      });
    }
  }

  void _submitQuote() {
    if (_formKey.currentState!.validate()) {
      final quote = Quote(
        clientName: _clientController.text,
        product: _productController.text,
        quantity: int.parse(_quantityController.text),
        description: _descriptionController.text,
        unitPrice: double.parse(_priceController.text),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Devis créé pour ${quote.clientName} - Total: ${quote.total}€')),
      );

      // Réinitialiser le formulaire
      _clientController.clear();
      _productController.clear();
      _quantityController.clear();
      _descriptionController.clear();
      _priceController.clear();
      setState(() {
        _total = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un devis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _clientController,
                decoration: const InputDecoration(
                  labelText: 'Nom du client',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom du client';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productController,
                decoration: const InputDecoration(
                  labelText: 'Produit/Service',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le produit/service';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantité',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _calculateTotal(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Entrez une quantité';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Prix unitaire (€)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _calculateTotal(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Entrez un prix';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              if (_total != null)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Total estimé: ${_total!.toStringAsFixed(2)}€',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitQuote,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Créer le devis'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Écran de commandes
class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final List<OrderItem> _cart = [];
  final List<Map<String, dynamic>> _products = [
    {'name': 'Produit A', 'price': 25.0},
    {'name': 'Produit B', 'price': 40.0},
    {'name': 'Service C', 'price': 60.0},
    {'name': 'Produit D', 'price': 15.0},
  ];

  void _addToCart(String name, double price) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.name == name);
      if (existingIndex != -1) {
        _cart[existingIndex] = OrderItem(
          name: name,
          price: price,
          quantity: _cart[existingIndex].quantity + 1,
        );
      } else {
        _cart.add(OrderItem(name: name, price: price, quantity: 1));
      }
    });
  }

  double get _total => _cart.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passer une commande'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage(cart: _cart, total: _total)),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(product['name']),
              subtitle: Text('${product['price']}€'),
              trailing: ElevatedButton(
                onPressed: () => _addToCart(product['name'], product['price']),
                child: const Text('Ajouter'),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Écran du panier
class CartPage extends StatelessWidget {
  final List<OrderItem> cart;
  final double total;

  const CartPage({super.key, required this.cart, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panier'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final item = cart[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('Quantité: ${item.quantity}'),
                  trailing: Text('${(item.price * item.quantity).toStringAsFixed(2)}€'),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${total.toStringAsFixed(2)}€',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Commande envoyée!')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Confirmer la commande'),
            ),
          ),
        ],
      ),
    );
  }
}

// Écran de liste des commandes
class OrdersListPage extends StatelessWidget {
  const OrdersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes commandes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'Liste des commandes (à implémenter avec stockage)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
