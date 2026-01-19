import 'category.dart';

class Transaction {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String? description;
  final String type;
  final Category? category;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    this.description,
    required this.type,
    this.category,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      amount: (json['montant'] ?? 0).toDouble(),
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      description: json['description'],
      type: json['type'] ?? (json['table'] == 'revenus' ? 'revenu' : 'depense'),
      category:
          json['categories'] != null
              ? Category.fromJson(json['categories'])
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'montant': amount,
      'date': date.toIso8601String().split('T')[0],
      'description': description,
      'categorie_id': category?.id,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isIncome => type == 'revenu';
}
