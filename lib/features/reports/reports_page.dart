import 'package:flutter/material.dart';

import '../../core/app_localizations.dart';
import '../../core/formatters.dart';
import '../../data/expense_repository.dart';
import '../../models/expense.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.repository});

  final ExpenseRepository repository;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late DateTime _month;
  late Future<List<CategoryTotal>> _totalsFuture;

  @override
  void initState() {
    super.initState();
    _month = DateTime.now();
    _load();
  }

  void _load() {
    _totalsFuture = widget.repository.getCategoryTotals(_month);
  }

  void _moveMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _load();
    });
  }

  void _moveToCurrentMonth() {
    setState(() {
      _month = DateTime.now();
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Reports'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.tr('Understand where your money is going.'),
                style: const TextStyle(color: Color(0xFF71807D)),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: context.tr('Previous month'),
                        onPressed: () => _moveMonth(-1),
                        icon: Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.chevron_right
                              : Icons.chevron_left,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          formatMonthLabel(
                            _month,
                            Localizations.localeOf(context).languageCode,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.tr('Next month'),
                        onPressed: () => _moveMonth(1),
                        icon: Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.chevron_left
                              : Icons.chevron_right,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _moveToCurrentMonth,
                        child: Text(context.tr('This month')),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FutureBuilder<List<CategoryTotal>>(
                future: _totalsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _ReportMessage(
                      title: context.tr('Unable to load report'),
                      message: '${snapshot.error}',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final totals = snapshot.data!;
                  if (totals.isEmpty) {
                    return _ReportMessage(
                      title: context.tr('Nothing to report yet'),
                      message: context.tr(
                        'There are no expenses recorded for this month. Try another month or add an expense.',
                      ),
                    );
                  }

                  final totalsByCurrency = <String, int>{};
                  final maxByCurrency = <String, int>{};
                  for (final total in totals) {
                    totalsByCurrency.update(
                      total.currencyCode,
                      (value) => value + total.amountCents,
                      ifAbsent: () => total.amountCents,
                    );
                    final currentMax = maxByCurrency[total.currencyCode] ?? 0;
                    if (total.amountCents > currentMax) {
                      maxByCurrency[total.currencyCode] = total.amountCents;
                    }
                  }
                  final expenseCount = totals.fold<int>(
                    0,
                    (sum, item) => sum + item.expenseCount,
                  );
                  final currencyCodes = totalsByCurrency.keys.toList()..sort();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('Total spending'),
                                style: const TextStyle(
                                  color: Color(0xFF71807D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final code in currencyCodes)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      formatCurrency(
                                        totalsByCurrency[code]!,
                                        code,
                                        locale: context.localeCode,
                                        currencyDisplayName:
                                            context.localeCode == 'ar'
                                            ? context.trCurrencyName(code)
                                            : null,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                '${context.localizeNumber(expenseCount)} ${context.tr('expenses')} · ${context.localizeNumber(currencyCodes.length)} ${context.tr('currencies')}',
                                style: const TextStyle(
                                  color: Color(0xFF82908C),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('Spending by category'),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 22),
                              for (
                                var index = 0;
                                index < totals.length;
                                index++
                              )
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == totals.length - 1 ? 0 : 22,
                                  ),
                                  child: _CategoryBreakdownRow(
                                    total: totals[index],
                                    maxCents:
                                        maxByCurrency[totals[index]
                                            .currencyCode] ??
                                        0,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
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

class _CategoryBreakdownRow extends StatelessWidget {
  const _CategoryBreakdownRow({required this.total, required this.maxCents});

  final CategoryTotal total;
  final int maxCents;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCents == 0 ? 0.0 : total.amountCents / maxCents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.trCategory(total.category),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                formatCurrency(
                  total.amountCents,
                  total.currencyCode,
                  locale: context.localeCode,
                  currencyDisplayName: context.localeCode == 'ar'
                      ? context.trCurrencyName(total.currencyCode)
                      : null,
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEAF0EE),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${context.localizeNumber(total.expenseCount)} ${context.tr(total.expenseCount == 1 ? 'expense' : 'expenses')}',
              style: const TextStyle(color: Color(0xFF84918D), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReportMessage extends StatelessWidget {
  const _ReportMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.insert_chart_outlined,
                size: 38,
                color: Color(0xFF9AA7A3),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF7F8B87)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
