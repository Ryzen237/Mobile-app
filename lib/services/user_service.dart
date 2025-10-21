import '../models/user.dart';

class UserService {
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Liste des utilisateurs (simulée - en production utiliserait une base de données)
  final List<User> _users = [];

  // Utilisateur actuellement connecté
  User? _currentUser;

  // Getter pour l'utilisateur actuel
  User? get currentUser => _currentUser;

  // Vérifier si un utilisateur est connecté
  bool get isLoggedIn => _currentUser != null;

  // Méthode pour créer un nouvel utilisateur
  User createUser({
    required String name,
    required String email,
    String? phone,
    String? company,
  }) {
    final user = User(
      id: _generateUserId(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone?.trim(),
      company: company?.trim(),
      createdAt: DateTime.now(),
    );

    _users.add(user);
    return user;
  }

  // Méthode pour connecter un utilisateur
  User? login(String email, String password) {
    // Simulation - en production, vérifier le mot de passe hashé
    final user = _users.where((user) => user.email == email.toLowerCase()).cast<User?>().first;

    if (user != null) {
      _currentUser = user;
      return user;
    }

    return null;
  }

  // Méthode pour déconnecter l'utilisateur actuel
  void logout() {
    _currentUser = null;
  }

  // Méthode pour valider les données d'inscription
  Map<String, String?> validateRegistrationData({
    required String name,
    required String email,
    String? phone,
    String? company,
  }) {
    final errors = <String, String?>{};

    if (name.trim().isEmpty) {
      errors['name'] = 'Le nom est obligatoire';
    } else if (name.trim().length < 2) {
      errors['name'] = 'Le nom doit contenir au moins 2 caractères';
    }

    if (email.trim().isEmpty) {
      errors['email'] = 'L\'email est obligatoire';
    } else if (!_isValidEmail(email.trim())) {
      errors['email'] = 'Format d\'email invalide';
    } else if (_users.any((user) => user.email == email.trim().toLowerCase())) {
      errors['email'] = 'Cet email est déjà utilisé';
    }

    if (phone != null && phone.trim().isNotEmpty && !_isValidPhone(phone.trim())) {
      errors['phone'] = 'Format de téléphone invalide';
    }

    return errors;
  }

  // Méthode pour valider les données de connexion
  Map<String, String?> validateLoginData({
    required String email,
    required String password,
  }) {
    final errors = <String, String?>{};

    if (email.trim().isEmpty) {
      errors['email'] = 'L\'email est obligatoire';
    }

    if (password.isEmpty) {
      errors['password'] = 'Le mot de passe est obligatoire';
    }

    return errors;
  }

  // Méthode pour récupérer un utilisateur par ID
  User? getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // Méthode pour récupérer un utilisateur par email
  User? getUserByEmail(String email) {
    try {
      return _users.firstWhere((user) => user.email == email.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  // Méthode pour mettre à jour les informations utilisateur
  User? updateUser(String userId, {
    String? name,
    String? email,
    String? phone,
    String? company,
  }) {
    final userIndex = _users.indexWhere((user) => user.id == userId);
    if (userIndex == -1) return null;

    final updatedUser = _users[userIndex].copyWith(
      name: name,
      email: email?.toLowerCase(),
      phone: phone,
      company: company,
    );

    _users[userIndex] = updatedUser;

    // Mettre à jour l'utilisateur actuel si c'est lui
    if (_currentUser?.id == userId) {
      _currentUser = updatedUser;
    }

    return updatedUser;
  }

  // Méthode pour supprimer un utilisateur
  bool deleteUser(String userId) {
    final initialLength = _users.length;
    _users.removeWhere((user) => user.id == userId);

    // Déconnecter si c'était l'utilisateur actuel
    if (_currentUser?.id == userId) {
      _currentUser = null;
    }

    return _users.length < initialLength;
  }

  // Méthode pour récupérer tous les utilisateurs (admin seulement)
  List<User> getAllUsers() {
    return List<User>.from(_users);
  }

  // Validation de l'email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validation du téléphone
  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  // Génération d'ID utilisateur unique
  String _generateUserId() {
    return 'USER_${DateTime.now().millisecondsSinceEpoch}_${_users.length}';
  }
}
