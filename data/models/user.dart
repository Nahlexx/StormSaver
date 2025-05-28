class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> teams;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.teams,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      teams: List<String>.from(json['teams']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'teams': teams,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 