// Modèle de données pour les utilisateurs
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? company;
  final DateTime createdAt;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.company,
    required this.createdAt,
    this.isActive = true,
  });

  // Méthode pour créer une copie avec des modifications
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Conversion en Map pour la persistance
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  // Factory depuis Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      company: map['company'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, company: $company)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
