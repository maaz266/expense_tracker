import 'package:expense_tracker/models/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense data round-trips through the storage map', () {
    final expense = Expense(
      id: 'expense-1',
      amount: 19.95,
      description: 'Lunch',
      category: 'Food',
      date: DateTime(2026, 11, 5),
    );

    final restored = Expense.fromMap({
      ...expense.toMap(),
      'id': expense.id,
    });

    expect(restored.id, expense.id);
    expect(restored.amount, expense.amount);
    expect(restored.description, expense.description);
    expect(restored.category, expense.category);
    expect(restored.date, expense.date);
  });
}
