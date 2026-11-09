import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'package:flutter/material.dart';

import 'expense_storage.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_storage.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/expense.dart';
import 'dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

// APP
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finora | Expense Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true),
        cardTheme: const CardThemeData(elevation: 2, margin: EdgeInsets.all(8)),

        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// HOME SCREEN
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Expense> expenses = [];
  final ExpenseStorage localStorage = ExpenseStorage();
  final FirestoreStorage storage = FirestoreStorage();
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  DateTime selectedMonth = DateTime.now();
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String? selectedCategoryFilter;
  String sortOrder = 'Newest first';

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No user is logged in.');
      }

      final migrationKey = 'firestore_migration_${user.uid}';

      final alreadyMigrated = await prefs.getBool(migrationKey) ?? false;

      var savedExpenses = await storage.loadExpenses();

      if (!alreadyMigrated) {
        if (savedExpenses.isEmpty) {
          // Firestore is empty, so check old local storage.
          final localExpenses = await localStorage.loadExpenses();

          for (final expense in localExpenses) {
            await storage.addExpense(expense);
          }

          // Reload expenses to get their Firestore document IDs.
          savedExpenses = await storage.loadExpenses();
        }

        // Mark migration as completed for this Firebase user.
        await prefs.setBool(migrationKey, true);
      }

      if (!mounted) return;

      setState(() {
        expenses
          ..clear()
          ..addAll(savedExpenses);

        isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading expenses: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load saved expenses.')),
      );
    }
  }

  Future<void> addExpense() async {
    final expense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );

    if (expense == null) return;

    try {
      final savedExpense = await storage.addExpense(expense);

      if (!mounted) return;

      setState(() {
        expenses.add(savedExpense);
      });
    } catch (error) {
      debugPrint('Error adding expense: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save expense. Please try again.'),
        ),
      );
    }
  }

  Future<void> editExpense(int index) async {
    final updatedExpense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(expense: expenses[index]),
      ),
    );

    if (updatedExpense == null) return;

    try {
      await storage.updateExpense(updatedExpense);

      if (!mounted) return;

      setState(() {
        expenses[index] = updatedExpense;
      });
    } catch (error) {
      debugPrint('Error updating expense: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update expense.')),
      );
    }
  }

  Future<void> openExpenseDetails(Expense expense) async {
    final result = await Navigator.push<ExpenseDetailsResult>(
      context,
      MaterialPageRoute(builder: (_) => ExpenseDetailsScreen(expense: expense)),
    );

    if (!mounted || result == null) return;

    if (result.deleted) {
      await deleteExpense(expense);
      return;
    }

    final updatedExpense = result.updatedExpense;

    if (updatedExpense == null) return;

    final index = expenses.indexOf(expense);

    if (index == -1) return;

    try {
      await storage.updateExpense(updatedExpense);

      if (!mounted) return;

      setState(() {
        expenses[index] = updatedExpense;
      });
    } catch (error) {
      debugPrint('Error updating expense: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update expense.')),
      );
    }
  }

  Future<void> deleteExpense(Expense expense) async {
    final deletedIndex = expenses.indexOf(expense);

    if (deletedIndex == -1) return;

    try {
      // First delete from Firestore.
      await storage.deleteExpense(expense);

      if (!mounted) return;

      // Only remove from UI after successful deletion.
      setState(() {
        expenses.removeAt(deletedIndex);
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              undoDelete(expense, deletedIndex);
            },
          ),
        ),
      );
    } catch (error) {
      debugPrint('Error deleting expense: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete expense. Please try again.'),
        ),
      );
    }
  }

  Future<void> undoDelete(Expense expense, int originalIndex) async {
    try {
      await storage.restoreExpense(expense);

      if (!mounted) return;

      setState(() {
        final insertIndex = originalIndex > expenses.length
            ? expenses.length
            : originalIndex;

        expenses.insert(insertIndex, expense);
      });
    } catch (error) {
      debugPrint('Error restoring expense: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not restore expense.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FinanceDashboard(
      expenses: expenses,
      selectedMonth: selectedMonth,
      isLoading: isLoading,
      searchController: searchController,
      searchQuery: searchQuery,
      selectedCategoryFilter: selectedCategoryFilter,
      sortOrder: sortOrder,
      onMonthChanged: (month) => setState(() => selectedMonth = month),
      onSearchChanged: (value) => setState(() => searchQuery = value),
      onCategoryChanged: (value) =>
          setState(() => selectedCategoryFilter = value),
      onSortChanged: (value) => setState(() => sortOrder = value),
      onAdd: addExpense,
      onOpenExpense: openExpenseDetails,
      onDeleteExpense: deleteExpense,
      onLogout: logout,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

// EXPENSE MODEL

class ExpenseDetailsResult {
  final Expense? updatedExpense;
  final bool deleted;

  const ExpenseDetailsResult({this.updatedExpense, this.deleted = false});
}

Future<DateTime?> _pickExpenseDate(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) {
      DateTime selectedDate = initialDate;

      return AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 320,
          child: StatefulBuilder(
            builder: (innerContext, setState) {
              return CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: firstDate,
                lastDate: lastDate,
                currentDate: DateTime.now(),
                onDateChanged: (date) {
                  selectedDate = date;
                  setState(() {});
                  Navigator.of(dialogContext).pop(date);
                },
              );
            },
          ),
        ),
      );
    },
  );
}

// ADD EXPENSE SCREEN
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  DateTime? selectedDate;
  String? selectedCategory;

  Future<void> selectDate() async {
    final today = DateTime.now();
    final pickedDate = await _pickExpenseDate(
      context,
      initialDate: selectedDate ?? today,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void saveExpense() {
    final amount = double.tryParse(amountController.text.trim());
    final description = descriptionController.text.trim();

    if (amount == null ||
        amount <= 0 ||
        description.isEmpty ||
        selectedCategory == null ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all expense details correctly'),
        ),
      );
      return;
    }

    final expense = Expense(
      amount: amount,
      description: description,
      category: selectedCategory!,
      date: selectedDate!,
    );

    Navigator.pop(context, expense);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Food', child: Text('Food')),
                DropdownMenuItem(value: 'Travel', child: Text('Travel')),
                DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectDate,
              child: const Text('Select Date'),
            ),
            const SizedBox(height: 8),
            Text(
              selectedDate == null
                  ? 'No date selected'
                  : '${selectedDate!.day}/'
                        '${selectedDate!.month}/'
                        '${selectedDate!.year}',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: saveExpense,
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}

// EDIT EXPENSE SCREEN
class EditExpenseScreen extends StatefulWidget {
  final Expense expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  String? selectedCategory;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    amountController.text = widget.expense.amount.toString();
    descriptionController.text = widget.expense.description;
    selectedCategory = widget.expense.category;
    selectedDate = widget.expense.date;
  }

  Future<void> selectDate() async {
    final today = DateTime.now();
    final currentSelectedDate = selectedDate ?? today;

    final initialDate = currentSelectedDate.isBefore(DateTime(2020))
        ? DateTime(2020)
        : currentSelectedDate.isAfter(DateTime(2030, 12, 31))
        ? DateTime(2030, 12, 31)
        : currentSelectedDate;

    final pickedDate = await _pickExpenseDate(
      context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void updateExpense() {
    final amount = double.tryParse(amountController.text.trim());
    final description = descriptionController.text.trim();

    if (amount == null ||
        amount <= 0 ||
        description.isEmpty ||
        selectedCategory == null ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all expense details correctly'),
        ),
      );
      return;
    }

    final updatedExpense = Expense(
      id: widget.expense.id,
      amount: amount,
      description: description,
      category: selectedCategory!,
      date: selectedDate!,
    );

    Navigator.pop(context, updatedExpense);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Food', child: Text('Food')),
                DropdownMenuItem(value: 'Travel', child: Text('Travel')),
                DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectDate,
              child: const Text('Select Date'),
            ),
            const SizedBox(height: 8),
            Text(
              selectedDate == null
                  ? 'No date selected'
                  : '${selectedDate!.day}/'
                        '${selectedDate!.month}/'
                        '${selectedDate!.year}',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: updateExpense,
              child: const Text('Update Expense'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}

class ExpenseDetailsScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailsScreen({super.key, required this.expense});

  Future<void> editExpense(BuildContext context) async {
    final updatedExpense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(builder: (_) => EditExpenseScreen(expense: expense)),
    );

    if (!context.mounted || updatedExpense == null) return;

    Navigator.pop(
      context,
      ExpenseDetailsResult(updatedExpense: updatedExpense),
    );
  }

  Future<void> deleteExpense(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Are you sure want to delete "${expense.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!context.mounted || shouldDelete != true) return;
    Navigator.pop(context, const ExpenseDetailsResult(deleted: true));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final categoryIcon = switch (expense.category) {
      'Food' => Icons.restaurant,
      'Travel' => Icons.directions_car,
      'Shopping' => Icons.shopping_bag,
      'Bills' => Icons.receipt_long,
      _ => Icons.category,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        categoryIcon,
                        size: 32,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      expense.description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${expense.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const Divider(height: 32),
                    ListTile(
                      leading: const Icon(Icons.category),
                      title: const Text('Category'),
                      trailing: Text(expense.category),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      trailing: Text(
                        '${expense.date.day}/'
                        '${expense.date.month}/'
                        '${expense.date.year}',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => editExpense(context),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Expense'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => deleteExpense(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Expense'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategorySummaryCard extends StatelessWidget {
  final String category;
  final double amount;

  const CategorySummaryCard({
    super.key,
    required this.category,
    required this.amount,
  });

  IconData get categoryIcon {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Travel':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills':
        return Icons.receipt_long;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(categoryIcon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  bool isRegistering = false;
  bool isLoading = false;

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (isRegistering && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }
    setState(() => isLoading = true);

    try {
      if (isRegistering) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        await credential.user?.updateDisplayName(name);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Authentication failed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Something went wrong.')));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Tracker'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isRegistering ? 'Create Account' : 'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                if (isRegistering) ...[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submit,
                    child: Text(
                      isLoading
                          ? 'Please wait...'
                          : isRegistering
                          ? 'Register'
                          : 'Log In',
                    ),
                  ),
                ),

                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            isRegistering = !isRegistering;
                          });
                        },

                  child: Text(
                    isRegistering
                        ? 'Already have an account> Log in'
                        : 'New here? Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
