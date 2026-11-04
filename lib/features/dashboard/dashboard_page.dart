import 'package:flutter/material.dart';

import '../../core/app_localizations.dart';
import '../../core/formatters.dart';
import '../../data/expense_repository.dart';
import '../../models/expense.dart';
import '../transactions/expense_form_dialog.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({
    super.key,
    required this.repository,
    required this.currencyCode,
    required this.onViewTransactions,
    required this.onViewReports,
  });

  final ExpenseRepository repository;
  final String currencyCode;
  final VoidCallback onViewTransactions;
  final VoidCallback onViewReports;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late Future<DashboardSummary> _summaryFuture;
  DashboardPeriod _averagePeriod = DashboardPeriod.month;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void _loadSummary() {
    _summaryFuture = widget.repository.getDashboardSummary(
      DateTime.now(),
      _averagePeriod,
    );
  }

  Future<void> _addExpense() async {
    final draft = await showExpenseFormDialog(
      context,
      repository: widget.repository,
    );
    if (draft == null) return;

    try {
      await widget.repository.saveExpense(draft);
      if (!mounted) return;
      setState(_loadSummary);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('Expense saved.'))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('Could not save expense')}: $error'),
        ),
      );
    }
  }

  String _periodLabel(BuildContext context) => switch (_averagePeriod) {
    DashboardPeriod.month => context.tr('This month'),
    DashboardPeriod.quarter => context.tr('This quarter'),
    DashboardPeriod.year => context.tr('This year'),
  };

  List<CurrencyAmount> _withZeroFallback(List<CurrencyAmount> amounts) {
    if (amounts.isNotEmpty) return amounts;
    return [CurrencyAmount(currencyCode: widget.currencyCode, amountCents: 0)];
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = formatMonthLabel(
      DateTime.now(),
      Localizations.localeOf(context).languageCode,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Overview'),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${context.tr('Your spending at a glance')} · $monthLabel',
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
              const SizedBox(height: 28),
              FutureBuilder<DashboardSummary>(
                future: _summaryFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _ErrorPanel(
                      message:
                          '${context.tr('Could not load overview')}: ${snapshot.error}',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final summary = snapshot.data!;
                  final monthTotals = _withZeroFallback(summary.monthTotals);
                  final averageValues = _withZeroFallback(
                    summary.periodAverages,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 900 ? 3 : 2;
                          final cardWidth =
                              (constraints.maxWidth - (columns - 1) * 16) /
                              columns;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: _MetricCard(
                                  label: context.tr('Spent this month'),
                                  value: _CurrencyValues(values: monthTotals),
                                  detail: monthLabel,
                                  icon: Icons.account_balance_wallet_outlined,
                                  accent: const Color(0xFF246B63),
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _MetricCard(
                                  label: context.tr('Expenses this month'),
                                  value: Text(
                                    context.localizeNumber(
                                      summary.monthExpenseCount,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 29,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1F302D),
                                    ),
                                  ),
                                  detail: context.tr('Recorded transactions'),
                                  icon: Icons.receipt_long_outlined,
                                  accent: const Color(0xFF5278A8),
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _MetricCard(
                                  label: context.tr('Average expense'),
                                  headerTrailing: DropdownButtonHideUnderline(
                                    child: DropdownButton<DashboardPeriod>(
                                      value: _averagePeriod,
                                      isDense: true,
                                      items: [
                                        DropdownMenuItem(
                                          value: DashboardPeriod.month,
                                          child: Text(context.tr('Month')),
                                        ),
                                        DropdownMenuItem(
                                          value: DashboardPeriod.quarter,
                                          child: Text(context.tr('Quarter')),
                                        ),
                                        DropdownMenuItem(
                                          value: DashboardPeriod.year,
                                          child: Text(context.tr('Year')),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() {
                                          _averagePeriod = value;
                                          _loadSummary();
                                        });
                                      },
                                    ),
                                  ),
                                  value: summary.periodExpenseCount == 0
                                      ? Text(
                                          context.tr(
                                            'No spending in this period',
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFF7B8985),
                                            fontSize: 13,
                                          ),
                                        )
                                      : _CurrencyValues(values: averageValues),
                                  detail:
                                      '${_periodLabel(context)} · ${context.tr('Average per recorded transaction')}',
                                  icon: Icons.calculate_outlined,
                                  accent: const Color(0xFF9A7440),
                                  footer: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: TextButton(
                                      onPressed: widget.onViewReports,
                                      child: Text(context.tr('More details')),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('Recent expenses'),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: widget.onViewTransactions,
                            icon: Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Icons.arrow_back
                                  : Icons.arrow_forward,
                              size: 17,
                            ),
                            label: Text(context.tr('View all')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _RecentExpensesCard(expenses: summary.recentExpenses),
                    ],
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

class _CurrencyValues extends StatelessWidget {
  const _CurrencyValues({required this.values});

  final List<CurrencyAmount> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                formatCurrency(
                  value.amountCents,
                  value.currencyCode,
                  locale: context.localeCode,
                  currencyDisplayName: context.localeCode == 'ar'
                      ? context.trCurrencyName(value.currencyCode)
                      : null,
                ),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Color(0xFF1F302D),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.accent,
    this.headerTrailing,
    this.footer,
  });

  final String label;
  final Widget value;
  final String detail;
  final IconData icon;
  final Color accent;
  final Widget? headerTrailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF687773),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ?headerTrailing,
                if (headerTrailing == null)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 17),
            value,
            const SizedBox(height: 7),
            Text(
              detail,
              style: const TextStyle(color: Color(0xFF899490), fontSize: 12),
            ),
            if (footer != null) ...[const SizedBox(height: 4), footer!],
          ],
        ),
      ),
    );
  }
}

class _RecentExpensesCard extends StatelessWidget {
  const _RecentExpensesCard({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
          child: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 34,
                  color: Color(0xFF9AA7A3),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('No expenses yet'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(
                    'Add your first expense to start tracking your spending.',
                  ),
                  style: const TextStyle(color: Color(0xFF788681)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (var index = 0; index < expenses.length; index++) ...[
            _RecentExpenseTile(expense: expenses[index]),
            if (index != expenses.length - 1)
              const Divider(height: 1, indent: 18, endIndent: 18),
          ],
        ],
      ),
    );
  }
}

class _RecentExpenseTile extends StatelessWidget {
  const _RecentExpenseTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5F3),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 19,
              color: Color(0xFF47766F),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${context.trCategory(expense.category)} · ${formatDate(expense.spentOn, locale: context.localeCode)} · ${formatTimeForDisplay(expense.spentTime, locale: context.localeCode)}',
                  style: const TextStyle(
                    color: Color(0xFF82908C),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              formatCurrency(
                expense.amountCents,
                expense.currencyCode,
                locale: context.localeCode,
                currencyDisplayName: context.localeCode == 'ar'
                    ? context.trCurrencyName(expense.currencyCode)
                    : null,
              ),
              style: const TextStyle(
                color: Color(0xFF263A35),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
