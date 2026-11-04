import 'package:flutter/material.dart';

import '../../core/app_localizations.dart';
import '../../core/formatters.dart';
import '../../core/currencies.dart';
import '../../data/expense_repository.dart';
import '../../models/expense.dart';
import 'expense_form_dialog.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key, required this.repository});

  final ExpenseRepository repository;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _searchController = TextEditingController();
  late Future<List<Expense>> _expensesFuture;
  late Future<List<String>> _categoriesFuture;
  String _selectedCategory = '';
  DateTimeRange? _dateRange;
  ExpenseSortField _sortField = ExpenseSortField.date;
  bool _sortAscending = true;
  String _selectedCurrency = '';

  ExpenseSort get _sort => ExpenseSort(_sortField, ascending: _sortAscending);

  @override
  void initState() {
    super.initState();
    _refresh();
    _categoriesFuture = widget.repository.getCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    _expensesFuture = widget.repository.listExpenses(
      search: _searchController.text,
      category: _selectedCategory.isEmpty ? null : _selectedCategory,
      fromDate: _dateRange?.start,
      toDate: _dateRange?.end,
      currencyCode: _selectedCurrency.isEmpty ? null : _selectedCurrency,
      sort: _sort,
    );
  }

  Future<void> _reloadCategories() async {
    final categories = await widget.repository.getCategories();
    if (!mounted) return;

    setState(() {
      _categoriesFuture = Future.value(categories);
      if (_selectedCategory.isNotEmpty &&
          !categories.contains(_selectedCategory)) {
        _selectedCategory = '';
      }
      _refresh();
    });
  }

  Future<void> _addExpense() async {
    await _editExpense();
  }

  Future<void> _editExpense([Expense? expense]) async {
    final draft = await showExpenseFormDialog(
      context,
      repository: widget.repository,
      expense: expense,
    );

    // The form also allows category management, so refresh filters even when
    // the user closes the form without saving the expense.
    if (!mounted) return;
    await _reloadCategories();
    if (draft == null || !mounted) return;

    try {
      await widget.repository.saveExpense(draft, id: expense?.id);
      if (!mounted) return;
      setState(() {
        _refresh();
        _categoriesFuture = widget.repository.getCategories();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(expense == null ? 'Expense added.' : 'Expense updated.'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('Could not save expense')}: $error'),
        ),
      );
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Delete expense?')),
        content: Text(
          context.trf('"{name}" will be permanently deleted.', {
            'name': expense.title,
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.repository.deleteExpense(expense.id);
      if (!mounted) return;
      setState(_refresh);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('Expense deleted.'))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('Could not delete expense')}: $error'),
        ),
      );
    }
  }

  Future<void> _chooseDateRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
      helpText: context.tr('Filter by expense date'),
      saveText: context.tr('Apply'),
      currentDate: now,
    );

    if (selected != null && mounted) {
      setState(() {
        _dateRange = selected;
        _refresh();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = '';
      _selectedCurrency = '';
      _dateRange = null;
      _searchController.clear();
      _refresh();
    });
  }

  bool _isSortActive(ExpenseSortField field) => _sortField == field;

  bool _sortDirection(ExpenseSortField field) =>
      _isSortActive(field) ? _sortAscending : true;

  void _activateSort(ExpenseSortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
      _refresh();
    });
  }

  void _setSortDirection(ExpenseSortField field, bool ascending) {
    setState(() {
      _sortField = field;
      _sortAscending = ascending;
      _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        _selectedCategory.isNotEmpty ||
        _selectedCurrency.isNotEmpty ||
        _dateRange != null ||
        _searchController.text.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Transactions'),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          context.tr(
                            'Review, search, edit, and organize every expense.',
                          ),
                          style: const TextStyle(color: Color(0xFF71807D)),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _addExpense,
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('Add expense')),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 760;
                      final search = SizedBox(
                        width: compact ? double.infinity : 360,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(_refresh),
                          decoration: InputDecoration(
                            hintText: context.tr('Search name or notes'),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: context.tr('Clear search'),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(_refresh);
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                      );

                      final categoryFilter = FutureBuilder<List<String>>(
                        future: _categoriesFuture,
                        builder: (context, snapshot) {
                          final categories =
                              (snapshot.data ?? const <String>[]).toList()
                                ..sort(
                                  (a, b) => context
                                      .trCategory(a)
                                      .compareTo(context.trCategory(b)),
                                );
                          return SizedBox(
                            width: compact ? double.infinity : 210,
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(_selectedCategory),
                              initialValue: _selectedCategory,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: context.tr('Category'),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: '',
                                  child: Text(context.tr('All categories')),
                                ),
                                for (final category in categories)
                                  DropdownMenuItem(
                                    value: category,
                                    child: Text(context.trCategory(category)),
                                  ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value ?? '';
                                  _refresh();
                                });
                              },
                            ),
                          );
                        },
                      );

                      final currencyFilter = SizedBox(
                        width: compact ? double.infinity : 185,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('currency-$_selectedCurrency'),
                          initialValue: _selectedCurrency,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: context.tr('Currency'),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text(context.tr('All currencies')),
                            ),
                            for (final code in supportedCurrencies.keys)
                              DropdownMenuItem(
                                value: code,
                                child: Text(
                                  context.trCurrencyCode(code),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCurrency = value ?? '';
                              _refresh();
                            });
                          },
                        ),
                      );

                      final dateFilter = Tooltip(
                        message: context.tr(
                          'Show expenses within a selected date range',
                        ),
                        child: OutlinedButton.icon(
                          onPressed: _chooseDateRange,
                          icon: const Icon(Icons.date_range_outlined),
                          label: Text(
                            _dateRange == null
                                ? context.tr('Filter by date')
                                : '${formatDate(_dateRange!.start, locale: context.localeCode)} – ${formatDate(_dateRange!.end, locale: context.localeCode)}',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                          ),
                        ),
                      );

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            search,
                            const SizedBox(height: 10),
                            categoryFilter,
                            const SizedBox(height: 10),
                            currencyFilter,
                            const SizedBox(height: 10),
                            dateFilter,
                            if (hasFilters)
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed: _clearFilters,
                                  child: Text(context.tr('Clear filters')),
                                ),
                              ),
                          ],
                        );
                      }

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          search,
                          categoryFilter,
                          currencyFilter,
                          dateFilter,
                          if (hasFilters)
                            TextButton(
                              onPressed: _clearFilters,
                              child: Text(context.tr('Clear filters')),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Expense>>(
                future: _expensesFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _TableMessage(
                      icon: Icons.error_outline,
                      title: context.tr('Unable to load transactions'),
                      message: '${snapshot.error}',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(50),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final expenses = snapshot.data!.toList();
                  if (expenses.isEmpty) {
                    return _TableMessage(
                      icon: Icons.search_off_outlined,
                      title: context.tr(
                        hasFilters ? 'No matching expenses' : 'No expenses yet',
                      ),
                      message: hasFilters
                          ? context.tr('Try changing or clearing your filters.')
                          : context.tr(
                              'Select “Add expense” to record your first transaction.',
                            ),
                    );
                  }

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                          child: Row(
                            children: [
                              Text(
                                '${context.localizeNumber(expenses.length)} ${context.tr(expenses.length == 1 ? 'transaction' : 'transactions')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF43534F),
                                ),
                              ),
                              const Spacer(),
                              Expanded(
                                child: Text(
                                  context.tr(
                                    'Choose one column to sort by, then select ascending or descending.',
                                  ),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: Color(0xFF71807D),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 48,
                            dataRowMinHeight: 64,
                            dataRowMaxHeight: 76,
                            columnSpacing: 32,
                            horizontalMargin: 20,
                            columns: [
                              DataColumn(
                                label: _SortHeader(
                                  label: context.tr('Date'),
                                  active: _isSortActive(ExpenseSortField.date),
                                  ascending: _sortDirection(
                                    ExpenseSortField.date,
                                  ),
                                  onTap: () =>
                                      _activateSort(ExpenseSortField.date),
                                  onAscendingTap: () => _setSortDirection(
                                    ExpenseSortField.date,
                                    true,
                                  ),
                                  onDescendingTap: () => _setSortDirection(
                                    ExpenseSortField.date,
                                    false,
                                  ),
                                ),
                              ),
                              DataColumn(label: Text(context.tr('Expense'))),
                              DataColumn(label: Text(context.tr('Category'))),
                              DataColumn(
                                label: _SortHeader(
                                  label: context.tr('Time'),
                                  active: _isSortActive(ExpenseSortField.time),
                                  ascending: _sortDirection(
                                    ExpenseSortField.time,
                                  ),
                                  onTap: () =>
                                      _activateSort(ExpenseSortField.time),
                                  onAscendingTap: () => _setSortDirection(
                                    ExpenseSortField.time,
                                    true,
                                  ),
                                  onDescendingTap: () => _setSortDirection(
                                    ExpenseSortField.time,
                                    false,
                                  ),
                                ),
                              ),
                              DataColumn(
                                numeric: true,
                                label: Tooltip(
                                  message: context.tr(
                                    'Amounts are sorted within each currency; no exchange-rate conversion is applied.',
                                  ),
                                  child: _SortHeader(
                                    label: context.tr('Amount'),
                                    active: _isSortActive(
                                      ExpenseSortField.amount,
                                    ),
                                    ascending: _sortDirection(
                                      ExpenseSortField.amount,
                                    ),
                                    onTap: () =>
                                        _activateSort(ExpenseSortField.amount),
                                    onAscendingTap: () => _setSortDirection(
                                      ExpenseSortField.amount,
                                      true,
                                    ),
                                    onDescendingTap: () => _setSortDirection(
                                      ExpenseSortField.amount,
                                      false,
                                    ),
                                  ),
                                ),
                              ),
                              const DataColumn(label: Text('')),
                            ],
                            rows: [
                              for (final expense in expenses)
                                DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        formatDate(
                                          expense.spentOn,
                                          locale: context.localeCode,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 190,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              expense.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (expense.notes.isNotEmpty)
                                              Text(
                                                expense.notes,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFF87938F),
                                                  fontSize: 11,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      _CategoryChip(
                                        label: context.trCategory(
                                          expense.category,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        formatTimeForDisplay(
                                          expense.spentTime,
                                          locale: context.localeCode,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Text(
                                          formatCurrency(
                                            expense.amountCents,
                                            expense.currencyCode,
                                            locale: context.localeCode,
                                            currencyDisplayName:
                                                context.localeCode == 'ar'
                                                ? context.trCurrencyCode(
                                                    expense.currencyCode,
                                                  )
                                                : null,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: context.tr('Edit expense'),
                                            onPressed: () =>
                                                _editExpense(expense),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 19,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: context.tr(
                                              'Delete expense',
                                            ),
                                            onPressed: () =>
                                                _deleteExpense(expense),
                                            color: const Color(0xFFB45D57),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 19,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF52716B),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TableMessage extends StatelessWidget {
  const _TableMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 54),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 36, color: const Color(0xFF9AA7A3)),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(
                message,
                style: const TextStyle(color: Color(0xFF7F8B87)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortHeader extends StatelessWidget {
  const _SortHeader({
    required this.label,
    required this.active,
    required this.ascending,
    required this.onTap,
    required this.onAscendingTap,
    required this.onDescendingTap,
  });

  final String label;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;
  final VoidCallback onAscendingTap;
  final VoidCallback onDescendingTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    const inactiveColor = Color(0xFF9AA6A2);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
            child: Text(
              label,
              style: TextStyle(
                color: active ? activeColor : const Color(0xFF788681),
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 1),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onAscendingTap,
              tooltip: context.tr('Sort ascending'),
              constraints: const BoxConstraints.tightFor(width: 22, height: 20),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              iconSize: 17,
              color: active && ascending ? activeColor : inactiveColor,
              icon: const Icon(Icons.arrow_drop_up),
            ),
            IconButton(
              onPressed: onDescendingTap,
              tooltip: context.tr('Sort descending'),
              constraints: const BoxConstraints.tightFor(width: 22, height: 20),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              iconSize: 17,
              color: active && !ascending ? activeColor : inactiveColor,
              icon: const Icon(Icons.arrow_drop_down),
            ),
          ],
        ),
      ],
    );
  }
}
