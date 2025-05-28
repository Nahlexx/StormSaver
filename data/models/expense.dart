// ... existing code ...
class Expense {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final String? notes;
  final String? teamId;
  final String? userId;
  final String? status;
  final String? receipt;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.notes,
    this.teamId,
    this.userId,
    this.status,
    this.receipt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? json['_id'] ?? '',
      description: json['description'] ?? json['Subject'] ?? '',
      amount: (json['amount'] ?? json['Amount'] ?? 0).toDouble(),
      date: (json['date'] != null)
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : (json['Date'] != null
              ? DateTime.tryParse(json['Date']) ?? DateTime.now()
              : DateTime.now()),
      category: json['category'] ?? json['Category'] ?? '',
      notes: json['notes'] ?? json['Notes'],
      teamId: json['teamId'] ?? json['Team'],
      userId: json['userId'] ?? json['User'],
      status: json['status'] ?? json['Status'],
      receipt: json['receipt'] ?? json['Receipt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'notes': notes,
      'teamId': teamId,
      'userId': userId,
      'status': status,
      'receipt': receipt,
    };
  }

  Expense copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    String? notes,
    String? teamId,
    String? userId,
    String? status,
    String? receipt,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      receipt: receipt ?? this.receipt,
    );
  }
}
// ... existing code ...