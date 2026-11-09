import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models/expense.dart';

const _navy = Color(0xFF111D35);
const _teal = Color(0xFF0EAD91);
const _muted = Color(0xFF718096);
const _canvas = Color(0xFFF4F7FB);
const _colors = <Color>[
  Color(0xFF0EAD91),
  Color(0xFF5C76E8),
  Color(0xFFF5B44B),
  Color(0xFFEE7285),
  Color(0xFF9C7AE8),
  Color(0xFF4B9BD8),
];

class FinanceDashboard extends StatefulWidget {
  final List<Expense> expenses;
  final DateTime selectedMonth;
  final bool isLoading;
  final TextEditingController searchController;
  final String searchQuery;
  final String? selectedCategoryFilter;
  final String sortOrder;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onAdd;
  final ValueChanged<Expense> onOpenExpense;
  final ValueChanged<Expense> onDeleteExpense;
  final VoidCallback onLogout;

  const FinanceDashboard({
    super.key,
    required this.expenses,
    required this.selectedMonth,
    required this.isLoading,
    required this.searchController,
    required this.searchQuery,
    required this.selectedCategoryFilter,
    required this.sortOrder,
    required this.onMonthChanged,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onAdd,
    required this.onOpenExpense,
    required this.onDeleteExpense,
    required this.onLogout,
  });

  @override
  State<FinanceDashboard> createState() => _FinanceDashboardState();
}

class _FinanceDashboardState extends State<FinanceDashboard> {
  int section = 0;

  String get monthName {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[widget.selectedMonth.month - 1]} ${widget.selectedMonth.year}';
  }

  List<Expense> get monthExpenses => widget.expenses
      .where(
        (e) =>
            e.date.month == widget.selectedMonth.month &&
            e.date.year == widget.selectedMonth.year,
      )
      .toList();

  List<Expense> get filteredExpenses {
    final list = monthExpenses
        .where(
          (e) =>
              e.description.toLowerCase().contains(
                widget.searchQuery.trim().toLowerCase(),
              ) &&
              (widget.selectedCategoryFilter == null ||
                  e.category == widget.selectedCategoryFilter),
        )
        .toList();
    switch (widget.sortOrder) {
      case 'Oldest first':
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Highest amount':
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Lowest amount':
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      default:
        list.sort((a, b) => b.date.compareTo(a.date));
    }
    return list;
  }

  Map<String, double> get categoryTotals {
    final result = <String, double>{};
    for (final e in monthExpenses) {
      result[e.category] = (result[e.category] ?? 0) + e.amount;
    }
    return result;
  }

  double get monthlyTotal =>
      monthExpenses.fold(0, (double sum, e) => sum + e.amount);
  String money(num value) => '₹${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _canvas,
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: _teal),
      ),
      child: Scaffold(
        backgroundColor: _canvas,
        body: Row(
          children: [
            if (desktop) _sidebar(),
            Expanded(
              child: SafeArea(
                child: Column(
                  children: [
                    _topBar(desktop),
                    Expanded(
                      child: widget.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: desktop ? 32 : 16,
                                vertical: 20,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1220,
                                  ),
                                  child: section == 0
                                      ? _overview(desktop)
                                      : section == 1
                                      ? _transactions()
                                      : _analytics(desktop),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: desktop
            ? null
            : NavigationBar(
                backgroundColor: Colors.white,
                selectedIndex: section,
                onDestinationSelected: (v) => setState(() => section = v),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Overview',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: 'Transactions',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.insights_outlined),
                    selectedIcon: Icon(Icons.insights),
                    label: 'Analytics',
                  ),
                ],
              ),
        floatingActionButton: desktop
            ? null
            : FloatingActionButton.extended(
                onPressed: widget.onAdd,
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Add expense'),
              ),
      ),
    );
  }

  Widget _sidebar() => Container(
    width: 238,
    color: _navy,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(25, 30, 20, 42),
            child: Row(
              children: [
                Icon(Icons.donut_large_rounded, color: _teal, size: 30),
                SizedBox(width: 12),
                Text(
                  'finora.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          for (final item in <(int, IconData, String)>[
            (0, Icons.dashboard_rounded, 'Overview'),
            (1, Icons.receipt_long_rounded, 'Transactions'),
            (2, Icons.insights_rounded, 'Analytics'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                selected: section == item.$1,
                selectedTileColor: const Color(0xFF253751),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(
                  item.$2,
                  color: section == item.$1 ? _teal : const Color(0xFFA9B6CA),
                ),
                title: Text(
                  item.$3,
                  style: TextStyle(
                    color: section == item.$1
                        ? Colors.white
                        : const Color(0xFFA9B6CA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => setState(() => section = item.$1),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text(
                'Sign out',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: widget.onLogout,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _topBar(bool desktop) => Container(
    color: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: desktop ? 32 : 16, vertical: 15),
    child: Row(
      children: [
        if (!desktop) ...[
          const Icon(Icons.donut_large_rounded, color: _teal),
          const SizedBox(width: 8),
          const Text(
            'finora.',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
        ] else
          Text(
            ['Overview', 'Transactions', 'Analytics'][section],
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
        const Spacer(),
        if (desktop) ...[
          FilledButton.icon(
            onPressed: widget.onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add expense'),
            style: FilledButton.styleFrom(backgroundColor: _teal),
          ),
          const SizedBox(width: 18),
        ],
        PopupMenuButton<String>(
          tooltip: 'Account',
          onSelected: (value) {
            if (value == 'logout') widget.onLogout();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'logout', child: Text('Sign out')),
          ],
          child: const CircleAvatar(
            backgroundColor: Color(0xFFE0F5F0),
            child: Icon(Icons.person_outline, color: _teal),
          ),
        ),
      ],
    ),
  );

  Widget _monthPicker() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Previous month',
        onPressed: () => widget.onMonthChanged(
          DateTime(widget.selectedMonth.year, widget.selectedMonth.month - 1),
        ),
        icon: const Icon(Icons.chevron_left),
      ),
      Flexible(
        child: Text(
          monthName,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _navy),
        ),
      ),
      IconButton(
        tooltip: 'Next month',
        onPressed: () => widget.onMonthChanged(
          DateTime(widget.selectedMonth.year, widget.selectedMonth.month + 1),
        ),
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );

  Widget _heading(String title, {String? subtitle}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: _navy,
        ),
      ),
      if (subtitle != null)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle, style: const TextStyle(color: _muted)),
        ),
    ],
  );

  Widget _panel(
    Widget child, {
    EdgeInsets padding = const EdgeInsets.all(22),
  }) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEBEFF5)),
    ),
    child: child,
  );

  Widget _overview(bool desktop) {
    final sorted = monthExpenses..sort((a, b) => b.date.compareTo(a.date));
    final topCategory = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 10,
          children: [
            _heading(
              'Your money, at a glance',
              subtitle: 'Track your spending and stay in control.',
            ),
            _monthPicker(),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 690;
            final cards = [
              _statCard(
                'Total spent',
                money(monthlyTotal),
                Icons.account_balance_wallet_outlined,
                _teal,
              ),
              _statCard(
                'Transactions',
                '${monthExpenses.length}',
                Icons.receipt_long_outlined,
                const Color(0xFF5C76E8),
              ),
              _statCard(
                'Top category',
                topCategory.isEmpty ? '—' : topCategory.first.key,
                Icons.pie_chart_outline,
                const Color(0xFFF5B44B),
              ),
            ];
            return wide
                ? Row(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 14),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      for (final card in cards)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: card,
                        ),
                    ],
                  );
          },
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 720;
            final chart = _categoryPanel();
            final trend = _dailyTrendPanel();
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: chart),
                      const SizedBox(width: 16),
                      Expanded(child: trend),
                    ],
                  )
                : Column(children: [chart, const SizedBox(height: 16), trend]);
          },
        ),
        const SizedBox(height: 20),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recent transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => section = 1),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (sorted.isEmpty)
                _empty('No transactions for this month yet.')
              else
                for (final expense in sorted.take(5)) _transactionTile(expense),
            ],
          ),
        ),
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accent) =>
      _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const Spacer(),
                const Icon(Icons.more_horiz, color: _muted),
              ],
            ),
            const SizedBox(height: 18),
            Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _categoryPanel() {
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending by category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 190,
            child: Center(
              child: entries.isEmpty
                  ? const Text(
                      'No data to visualize',
                      style: TextStyle(color: _muted),
                    )
                  : CustomPaint(
                      size: const Size(190, 190),
                      painter: _DonutPainter(
                        entries.map((e) => e.value).toList(),
                      ),
                      child: SizedBox(
                        width: 190,
                        height: 190,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Total spent',
                              style: TextStyle(color: _muted, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              child: Text(
                                money(monthlyTotal),
                                style: const TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colors[i % _colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entries[i].key,
                      style: const TextStyle(color: _navy),
                    ),
                  ),
                  Text(
                    '${monthlyTotal == 0 ? 0 : (entries[i].value / monthlyTotal * 100).round()}%',
                    style: const TextStyle(color: _muted),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    money(entries[i].value),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _dailyTrendPanel() {
    final days = DateUtils.getDaysInMonth(
      widget.selectedMonth.year,
      widget.selectedMonth.month,
    );
    final sums = List<double>.filled(days, 0);
    for (final e in monthExpenses) {
      sums[e.date.day - 1] += e.amount;
    }
    final maxValue = sums.fold<double>(0, (a, b) => math.max(a, b));
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily spending',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Spending activity throughout the month',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < days; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Tooltip(
                        message: '${i + 1}: ${money(sums[i])}',
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: maxValue == 0
                                ? .025
                                : math.max(.025, sums[i] / maxValue),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: sums[i] > 0
                                    ? _teal
                                    : const Color(0xFFE7EDF3),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: _axisStyle),
              Text('${(days / 2).round()}', style: _axisStyle),
              Text('$days', style: _axisStyle),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFEEF1F5)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.trending_up, color: _teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  monthExpenses.isEmpty
                      ? 'Add an expense to start tracking trends.'
                      : 'Your spending is recorded across ${sums.where((v) => v > 0).length} day(s).',
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _axisStyle = TextStyle(color: _muted, fontSize: 11);

  Widget _transactions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 14,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _heading('Transactions', subtitle: 'Find and manage your expenses.'),
          _monthPicker(),
        ],
      ),
      const SizedBox(height: 22),
      _panel(
        Column(
          children: [
            TextField(
              controller: widget.searchController,
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search expenses',
                suffixIcon: widget.searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          widget.searchController.clear();
                          widget.onSearchChanged('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                final filters = [
                  DropdownButtonFormField<String>(
                    key: ValueKey(widget.selectedCategoryFilter),
                    initialValue: widget.selectedCategoryFilter ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('All categories'),
                      ),
                      ...[
                        'Food',
                        'Travel',
                        'Shopping',
                        'Bills',
                        'Other',
                      ].map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (v) => widget.onCategoryChanged(
                      v == null || v.isEmpty ? null : v,
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    key: ValueKey(widget.sortOrder),
                    initialValue: widget.sortOrder,
                    decoration: const InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        [
                              'Newest first',
                              'Oldest first',
                              'Highest amount',
                              'Lowest amount',
                            ]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                    onChanged: (v) {
                      if (v != null) widget.onSortChanged(v);
                    },
                  ),
                ];
                return c.maxWidth >= 550
                    ? Row(
                        children: [
                          Expanded(child: filters[0]),
                          const SizedBox(width: 12),
                          Expanded(child: filters[1]),
                        ],
                      )
                    : Column(
                        children: [
                          filters[0],
                          const SizedBox(height: 12),
                          filters[1],
                        ],
                      );
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  '${filteredExpenses.length} transactions',
                  style: const TextStyle(color: _muted),
                ),
                const Spacer(),
                Text(
                  money(
                    filteredExpenses.fold<double>(
                      0,
                      (sum, e) => sum + e.amount,
                    ),
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            if (filteredExpenses.isEmpty)
              _empty('No expenses match this month and filters.')
            else
              for (final expense in filteredExpenses)
                _transactionTile(expense, showDelete: true),
          ],
        ),
      ),
      const SizedBox(height: 28),
    ],
  );

  Widget _analytics(bool desktop) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 14,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _heading(
            'Spending analytics',
            subtitle: 'Understand where your money goes.',
          ),
          _monthPicker(),
        ],
      ),
      const SizedBox(height: 22),
      _statCard(
        'Total monthly spending',
        money(monthlyTotal),
        Icons.insights,
        _teal,
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, c) => c.maxWidth >= 720
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _categoryPanel()),
                  const SizedBox(width: 16),
                  Expanded(child: _dailyTrendPanel()),
                ],
              )
            : Column(
                children: [
                  _categoryPanel(),
                  const SizedBox(height: 16),
                  _dailyTrendPanel(),
                ],
              ),
      ),
      const SizedBox(height: 28),
    ],
  );

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 35),
    child: Center(
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: Color(0xFFB5C2D2),
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: widget.onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add expense'),
          ),
        ],
      ),
    ),
  );

  Widget _transactionTile(Expense expense, {bool showDelete = false}) {
    final icon = switch (expense.category) {
      'Food' => Icons.restaurant_outlined,
      'Travel' => Icons.directions_car_outlined,
      'Shopping' => Icons.shopping_bag_outlined,
      'Bills' => Icons.receipt_long_outlined,
      _ => Icons.category_outlined,
    };
    final index = [
      'Food',
      'Travel',
      'Shopping',
      'Bills',
      'Other',
    ].indexOf(expense.category);
    final color = _colors[(index < 0 ? 5 : index) % _colors.length];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => widget.onOpenExpense(expense),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          expense.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _navy),
        ),
        subtitle: Text(
          '${expense.category} · ${expense.date.day}/${expense.date.month}/${expense.date.year}',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '-${money(expense.amount)}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: _navy),
            ),
            if (showDelete)
              IconButton(
                tooltip: 'Delete expense',
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFD66875),
                ),
                onPressed: () => widget.onDeleteExpense(expense),
              ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  _DonutPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final total = values.fold<double>(0, (sum, v) => sum + v);
    final base = Paint()
      ..color = const Color(0xFFEDF1F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 21;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    if (total <= 0) return;
    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      final paint = Paint()
        ..color = _colors[i % _colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 21
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
