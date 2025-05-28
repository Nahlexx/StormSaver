class TeamMember {
  final String userId;
  final String role;

  TeamMember({
    required this.userId,
    required this.role,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['user'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'role': role,
    };
  }
}

class Team {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<TeamMember> members;
  final double budget;
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.members,
    required this.budget,
    required this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['_id'],
      name: json['name'],
      description: json['description'] ?? '',
      createdBy: json['createdBy'],
      members: (json['members'] as List)
          .map((member) => TeamMember.fromJson(member))
          .toList(),
      budget: json['budget'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'members': members.map((member) => member.toJson()).toList(),
      'budget': budget,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 