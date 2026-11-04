enum ExpenseSortField { date, time, amount }

class ExpenseSort {
  const ExpenseSort(this.field, {required this.ascending});

  final ExpenseSortField field;
  final bool ascending;
}

enum DashboardPeriod { month, quarter, year }

class CurrencyAmount {
  const CurrencyAmount({required this.currencyCode, required this.amountCents});

  final String currencyCode;
  final int amountCents;
}

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.currencyCode,
    required this.spentOn,
    required this.spentTime,
    required this.category,
    required this.notes,
  });

  final int id;
  final String title;
  final int amountCents;
  final String currencyCode;
  final DateTime spentOn;
  final String spentTime;
  final String category;
  final String notes;

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int,
      title: map['title'] as String,
      amountCents: map['amount_cents'] as int,
      currencyCode: (map['currency_code'] as String?) ?? 'EGP',
      spentOn: DateTime.parse(map['spent_on'] as String),
      spentTime: map['spent_time'] as String,
      category: map['category'] as String,
      notes: (map['notes'] as String?) ?? '',
    );
  }
}

class ExpenseDraft {
  const ExpenseDraft({
    required this.title,
    required this.amountCents,
    required this.currencyCode,
    required this.spentOn,
    required this.spentTime,
    required this.category,
    required this.notes,
  });

  final String title;
  final int amountCents;
  final String currencyCode;
  final DateTime spentOn;
  final String spentTime;
  final String category;
  final String notes;
}

class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.currencyCode,
    required this.amountCents,
    required this.expenseCount,
  });

  final String category;
  final String currencyCode;
  final int amountCents;
  final int expenseCount;
}

class DashboardSummary {
  const DashboardSummary({
    required this.monthTotals,
    required this.monthExpenseCount,
    required this.periodAverages,
    required this.periodExpenseCount,
    required this.recentExpenses,
  });

  final List<CurrencyAmount> monthTotals;
  final int monthExpenseCount;
  final List<CurrencyAmount> periodAverages;
  final int periodExpenseCount;
  final List<Expense> recentExpenses;
}

class ImportResult {
  const ImportResult({required this.imported, required this.skipped});

  final int imported;
  final int skipped;
}
