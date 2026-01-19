class Category {
  final String id;
  final String name;
  final String type;
  final String? emoji;
  final String? userId;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.emoji,
    this.userId,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['nom'] ?? '',
      type: json['type'] ?? 'depense',
      emoji: json['emoji'],
      userId: json['user_id'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': name,
      'type': type,
      'emoji': emoji,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'Category(name: $name, type: $type)';
}
