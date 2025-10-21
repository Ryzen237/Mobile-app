import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/quote.dart';
import '../models/user.dart';
import '../providers/app_state.dart';
import 'quote_screen.dart';

class QuotesListScreen extends StatefulWidget {
  const QuotesListScreen({super.key});

  @override
  State<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends State<QuotesListScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Initialize date formatting and load quotes after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Initialize date formatting for French locale
        await initializeDateFormatting('fr_FR');
        print('Date formatting initialized successfully');
      } catch (e) {
        print('Erreur lors de l\'initialisation du formatage des dates: $e');
      }

      _loadQuotes();
    });
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      // Vérifier si l'utilisateur actuel est défini
      if (appState.currentUser == null) {
        print('Aucun utilisateur actuel, tentative de chargement...');
        await _ensureUserExists(appState);
      }

      // Charger les données utilisateur
      await appState.loadUserData();

      // Si toujours pas de données, essayer de charger tous les devis comme fallback
      if (appState.quotes.isEmpty && appState.currentUser != null) {
        print('Aucun devis trouvé pour l\'utilisateur, chargement de tous les devis...');
        try {
          final allQuotes = await appState.databaseService.getAllQuotes();
          if (allQuotes.isNotEmpty && mounted) {
            // Mettre à jour les devis dans l'état global
            appState.updateQuotes(allQuotes);
          }
        } catch (e) {
          print('Erreur lors du chargement fallback: $e');
        }
      }

    } catch (e) {
      print('Erreur lors du chargement des devis: $e');
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _ensureUserExists(AppState appState) async {
    try {
      // Essayer de récupérer l'utilisateur le plus récent depuis la base de données
      final users = await appState.databaseService.getAllUsers();
      if (users.isNotEmpty) {
        appState.setCurrentUser(users.first);
        print('Utilisateur trouvé et défini: ${users.first.email}');
      } else {
        // Créer un utilisateur de démonstration
        final demoUser = await appState.databaseService.insertUser(
          User(
            id: 'USER_DEMO_${DateTime.now().millisecondsSinceEpoch}',
            name: 'Utilisateur Demo',
            email: 'demo@exemple.com',
            createdAt: DateTime.now(),
          ),
        );
        if (demoUser != null) {
          appState.setCurrentUser(demoUser);
          print('Utilisateur de démonstration créé: ${demoUser.email}');
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification de l\'utilisateur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes devis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotes,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (_isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des devis...'),
                ],
              ),
            );
          }

          if (_errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadQuotes,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (appState.quotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.request_quote_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun devis trouvé',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez votre premier devis depuis l\'écran "Faire un devis"',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const QuoteScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Créer un devis'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: appState.quotes.length,
            itemBuilder: (context, index) {
              try {
                final quote = appState.quotes[index];
                if (quote == null) {
                  return const SizedBox.shrink();
                }
                return QuoteCard(quote: quote);
              } catch (e) {
                print('Erreur lors de l\'affichage du devis $index: $e');
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Text(
                    'Erreur d\'affichage de ce devis',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class QuoteCard extends StatelessWidget {
  final Quote quote;

  const QuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    try {
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      quote.clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Devis',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Produit: ${quote.product}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quantité: ${quote.quantity}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Prix unitaire: ${quote.unitPrice.toStringAsFixed(2)}€',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              if (quote.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Description: ${quote.description}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${quote.total.toStringAsFixed(2)}€',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Erreur lors de l\'affichage du devis: $e');
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          'Erreur d\'affichage de ce devis',
          style: TextStyle(color: Colors.red.shade700),
        ),
      );
    }
  }
}
