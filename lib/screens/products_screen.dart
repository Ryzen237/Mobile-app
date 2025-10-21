import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/app_state.dart';
import '../services/storage_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'cart_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<String> _categories = [];
  String _selectedCategory = 'Tous';
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load products after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      if (kIsWeb) {
        // Use StorageService for web
        final storageService = StorageService();
        _allProducts = await storageService.getAllProducts();
        _categories = await storageService.getCategories();
        _categories.insert(0, 'Tous');
        _filteredProducts = _allProducts;
      } else {
        // Use DatabaseService for mobile
        try {
          _allProducts = await appState.databaseService.getAllProducts();
          _categories = await appState.databaseService.getCategories();
          _categories.insert(0, 'Tous');
          _filteredProducts = _allProducts;
        } catch (e) {
          print('Erreur base de données mobile: $e');
          _loadDemoProducts();
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des produits: $e');
      _loadDemoProducts();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadDemoProducts() {
    _allProducts = [
      {'id': 1, 'name': 'Produit A', 'price': 25.0, 'category': 'Électronique', 'description': 'Produit électronique haute qualité'},
      {'id': 2, 'name': 'Produit B', 'price': 40.0, 'category': 'Électronique', 'description': 'Innovation technologique'},
      {'id': 3, 'name': 'Service C', 'price': 60.0, 'category': 'Services', 'description': 'Service professionnel'},
      {'id': 4, 'name': 'Produit D', 'price': 15.0, 'category': 'Accessoires', 'description': 'Accessoire pratique'},
      {'id': 5, 'name': 'Produit E', 'price': 80.0, 'category': 'Premium', 'description': 'Produit haut de gamme'},
      {'id': 6, 'name': 'Service F', 'price': 120.0, 'category': 'Services', 'description': 'Service expert'},
    ];
    _categories = ['Tous', 'Électronique', 'Services', 'Accessoires', 'Premium'];
    _filteredProducts = _allProducts;
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesCategory = _selectedCategory == 'Tous' || product['category'] == _selectedCategory;
        final matchesSearch = _searchQuery.isEmpty ||
            product['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product['description'].toLowerCase().contains(_searchQuery.toLowerCase());

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category ?? 'Tous';
      _filterProducts();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue de produits'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(width: 4),
                        ..._categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              height: 40,
                              child: FilterChip(
                                label: Text(category),
                                selected: _selectedCategory == category,
                                onSelected: (selected) => _onCategoryChanged(category),
                                backgroundColor: Colors.grey[100],
                                selectedColor: Colors.blue[100],
                                checkmarkColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun produit trouvé',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Essayez de changer les filtres ou la recherche',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey.shade50,
                        Colors.white,
                      ],
                    ),
                  ),
                  child: AnimationLimiter(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85, // Adjusted for more compact cards
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          columnCount: 2, // Fixed to 2 for consistent animation
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: ProductCard(
                                product: product,
                                onAddToCart: () {
                                  final appState = Provider.of<AppState>(context, listen: false);
                                  appState.addToCart(product['name'], product['price']);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${product['name']} ajouté au panier'),
                                      action: SnackBarAction(
                                        label: 'Voir le panier',
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => CartScreen(
                                                cart: appState.cart,
                                                total: appState.cartTotal,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Optional: Show product details on tap
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image/Icon section
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    size: 32,
                    color: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Product info
              Text(
                product['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product['category'],
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Price and button in a row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${product['price'].toStringAsFixed(2)}€',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(
                    height: 28,
                    child: ElevatedButton(
                      onPressed: onAddToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 1,
                        minimumSize: const Size(50, 24),
                      ),
                      child: const Text(
                        'Ajouter',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
