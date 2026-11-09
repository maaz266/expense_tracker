import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('creates an expense from the add-expense form', (
    WidgetTester tester,
  ) async {
    Expense? createdExpense;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  createdExpense = await Navigator.of(context).push<Expense>(
                    MaterialPageRoute(
                      builder: (_) => const AddExpenseScreen(),
                    ),
                  );
                },
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '19.95');
    await tester.enterText(find.byType(TextField).at(1), 'Lunch');

    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select Date'));
    await tester.pumpAndSettle();
    final today = DateTime.now();
    await tester.tap(find.text('${today.day}').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    expect(createdExpense, isNotNull);
    expect(createdExpense!.amount, 19.95);
    expect(createdExpense!.description, 'Lunch');
    expect(createdExpense!.category, 'Food');
    expect(createdExpense!.date, DateTime(today.year, today.month, today.day));
  });

  testWidgets('shows validation feedback when required fields are missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AddExpenseScreen()));

    await tester.tap(find.text('Save Expense'));
    await tester.pump();

    expect(
      find.text('Please enter all expense details correctly'),
      findsOneWidget,
    );
    expect(find.text('Add Expense'), findsOneWidget);
  });
}
