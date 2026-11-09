class Expense {
  final String? id;
  final double amount;
  final String description;
  final String category;
  final DateTime date;

  Expense({
    this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  Expense copyWith({String? id}) {
    return Expense(
      id: id ?? this.id,
      amount: amount,
      description: description,
      category: category,
      date: date,
    );
  }
}
