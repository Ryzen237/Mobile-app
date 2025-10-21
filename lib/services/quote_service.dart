import '../models/quote.dart';

class QuoteService {
  // Singleton pattern
  static final QuoteService _instance = QuoteService._internal();
  factory QuoteService() => _instance;
  QuoteService._internal();

  // Méthode pour calculer le total d'un devis
  double calculateTotal(int quantity, double unitPrice) {
    return quantity * unitPrice;
  }

  // Méthode pour valider les données du devis
  Map<String, String?> validateQuoteData({
    required String clientName,
    required String product,
    required String quantity,
    required String unitPrice,
  }) {
    final errors = <String, String?>{};

    if (clientName.trim().isEmpty) {
      errors['clientName'] = 'Le nom du client est obligatoire';
    }

    if (product.trim().isEmpty) {
      errors['product'] = 'Le produit/service est obligatoire';
    }

    final quantityNum = int.tryParse(quantity);
    if (quantityNum == null || quantityNum <= 0) {
      errors['quantity'] = 'La quantité doit être un nombre positif';
    }

    final priceNum = double.tryParse(unitPrice);
    if (priceNum == null || priceNum <= 0) {
      errors['unitPrice'] = 'Le prix doit être un nombre positif';
    }

    return errors;
  }

  // Méthode pour créer un devis depuis les données du formulaire
  Quote createQuoteFromFormData({
    required String clientName,
    required String product,
    required String quantity,
    required String description,
    required String unitPrice,
  }) {
    return Quote(
      clientName: clientName.trim(),
      product: product.trim(),
      quantity: int.parse(quantity),
      description: description.trim(),
      unitPrice: double.parse(unitPrice),
    );
  }

  // Méthode pour formater le prix en euros
  String formatPrice(double price) {
    return '${price.toStringAsFixed(2)}FCFA';
  }

  // Méthode pour générer un ID unique pour le devis (simulé)
  String generateQuoteId() {
    return 'QUOTE_${DateTime.now().millisecondsSinceEpoch}';
  }
}
