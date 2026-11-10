enum UserRole {
  admin('Administrador'),
  user('Usuário comum');

  const UserRole(this.label);

  final String label;

  static UserRole fromName(String name) =>
      UserRole.values.firstWhere((r) => r.name == name, orElse: () => user);
}

/// Usuário do aplicativo. O hash da senha nunca sai da camada de dados.
class AppUser {
  const AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  bool get isAdmin => role == UserRole.admin;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  AppUser copyWith({
    String? name,
    String? email,
    UserRole? role,
    bool? isActive,
  }) => AppUser(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
    id: map['id'] as int,
    name: map['name'] as String,
    email: map['email'] as String,
    role: UserRole.fromName(map['role'] as String),
    isActive: (map['is_active'] as int) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };
}
