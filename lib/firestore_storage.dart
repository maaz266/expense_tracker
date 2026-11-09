import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/expense.dart';

class FirestoreStorage {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get expensesCollection {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No user is logged in.');
    }

    return firestore.collection('users').doc(user.uid).collection('expenses');
  }

  Future<List<Expense>> loadExpenses() async {
    final snapshot = await expensesCollection.get();

    return snapshot.docs.map((document) {
      return Expense.fromMap({...document.data(), 'id': document.id});
    }).toList();
  }

  // create: add an expense and assign it a unique document ID
  Future<Expense> addExpense(Expense expense) async {
    final document = expensesCollection.doc();

    await document.set(expense.toMap());

    return expense.copyWith(id: document.id);
  }

  //update:  update one existing expense
  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) {
      throw Exception('Expense ID is missing.');
    }

    await expensesCollection.doc(expense.id).update(expense.toMap());
  }

  // Delete: permanently remove one expense from Firestore
  Future<void> deleteExpense(Expense expense) async {
    if (expense.id == null) {
      throw Exception('Expense ID is missing.');
    }

    await expensesCollection.doc(expense.id).delete();
  }

  //delete: remove one expense
  Future<void> restoreExpense(Expense expense) async {
    if (expense.id == null) {
      throw Exception('Expense ID is missing.');
    }

    await expensesCollection.doc(expense.id).set(expense.toMap());
  }
}
