import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/expense.dart';

class ExpenseStorage {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  static const String expensesKey = "expenses";

  Future<void> saveExpenses(List<Expense> expenses) async {
    final expenseMaps = expenses.map((expense) => expense.toMap()).toList();

    final jsonString = jsonEncode(expenseMaps);

    await prefs.setString(expensesKey, jsonString);
  }

  Future<List<Expense>> loadExpenses() async {
    final jsonString = await prefs.getString(expensesKey);

    if (jsonString == null) {
      return [];
    }

    final List<dynamic> decodedData = jsonDecode(jsonString);

    return decodedData
        .map((item) => Expense.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }
}
