import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/data/expense_repository.dart';
import 'package:pocket_ledger/models/expense.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late ExpenseRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE expenses (
              id INTEGER PRIMARY KEY,
              title TEXT NOT NULL,
              amount_cents INTEGER NOT NULL,
              currency_code TEXT NOT NULL DEFAULT 'EGP',
              spent_on TEXT NOT NULL,
              spent_time TEXT NOT NULL,
              category_id INTEGER NOT NULL,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
        },
      ),
    );

    await database.insert('categories', {'id': 1, 'name': 'Food'});
    await database.insert('categories', {'id': 2, 'name': 'Transport'});
    await database.insert('categories', {'id': 3, 'name': 'Education'});

    final rows = [
      (1, 'Breakfast', 1250, '2026-10-15', '08:00', 1, 'EGP'),
      (2, 'Bus', 500, '2026-10-16', '09:00', 2, 'EGP'),
      (3, 'Course', 5000, '2026-10-16', '18:00', 3, 'EGP'),
      (4, 'Coffee', 250, '2026-10-16', '09:00', 1, 'EGP'),
      (5, 'Taxi USD', 1000, '2026-10-16', '09:00', 2, 'USD'),
    ];
    for (final row in rows) {
      await database.insert('expenses', {
        'id': row.$1,
        'title': row.$2,
        'amount_cents': row.$3,
        'spent_on': row.$4,
        'spent_time': row.$5,
        'category_id': row.$6,
        'currency_code': row.$7,
        'notes': '',
      });
    }

    repository = ExpenseRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('sorts transactions by date oldest-first', () async {
    final expenses = await repository.listExpenses(
      currencyCode: 'EGP',
      sort: const ExpenseSort(ExpenseSortField.date, ascending: true),
    );

    expect(expenses.map((expense) => expense.title).toList(), [
      'Breakfast',
      'Bus',
      'Coffee',
      'Course',
    ]);
  });

  test('sorts transactions by date newest-first', () async {
    final expenses = await repository.listExpenses(
      currencyCode: 'EGP',
      sort: const ExpenseSort(ExpenseSortField.date, ascending: false),
    );

    expect(expenses.map((expense) => expense.title).toList(), [
      'Course',
      'Bus',
      'Coffee',
      'Breakfast',
    ]);
  });

  test('sorts transactions by time of day from early to late', () async {
    final expenses = await repository.listExpenses(
      currencyCode: 'EGP',
      sort: const ExpenseSort(ExpenseSortField.time, ascending: true),
    );

    expect(expenses.map((expense) => expense.title).toList(), [
      'Breakfast',
      'Bus',
      'Coffee',
      'Course',
    ]);
  });

  test('loads category summaries with linked expense counts', () async {
    final categories = await repository.getCategorySummaries();

    expect(
      categories
          .map((category) => (category.name, category.expenseCount))
          .toList(),
      [('Education', 1), ('Food', 2), ('Transport', 2)],
    );
  });

  test('sorts amounts within a currency from low to high', () async {
    final expenses = await repository.listExpenses(
      currencyCode: 'EGP',
      sort: const ExpenseSort(ExpenseSortField.amount, ascending: true),
    );

    expect(expenses.map((expense) => expense.title).toList(), [
      'Coffee',
      'Bus',
      'Breakfast',
      'Course',
    ]);
  });

  test('sorts transactions by time of day from late to early', () async {
    final expenses = await repository.listExpenses(
      currencyCode: 'EGP',
      sort: const ExpenseSort(ExpenseSortField.time, ascending: false),
    );

    expect(expenses.map((expense) => expense.title).toList(), [
      'Course',
      'Bus',
      'Coffee',
      'Breakfast',
    ]);
  });

  test('sorts amounts from high to low within each currency', () async {
    final expenses = await repository.listExpenses(
      currencyCode: 'EGP',
      sort: const ExpenseSort(ExpenseSortField.amount, ascending: false),
    );

    expect(expenses.map((expense) => expense.title).toList(), [
      'Course',
      'Breakfast',
      'Bus',
      'Coffee',
    ]);
  });

  test('calculates quarter averages using only the current quarter', () async {
    await database.insert('expenses', {
      'id': 6,
      'title': 'Previous quarter expense',
      'amount_cents': 9000,
      'currency_code': 'EGP',
      'spent_on': '2026-09-30',
      'spent_time': '12:00',
      'category_id': 1,
      'notes': '',
    });

    final summary = await repository.getDashboardSummary(
      DateTime(2026, 10, 16),
      DashboardPeriod.quarter,
    );

    expect(summary.periodExpenseCount, 5);
    expect(summary.periodAverages.first.amountCents, 1750);
    expect(summary.periodAverages.last.currencyCode, 'USD');
  });

  test(
    'calculates yearly averages across months but not other years',
    () async {
      await database.insert('expenses', {
        'id': 6,
        'title': 'September expense',
        'amount_cents': 3000,
        'currency_code': 'EGP',
        'spent_on': '2026-09-30',
        'spent_time': '12:00',
        'category_id': 1,
        'notes': '',
      });
      await database.insert('expenses', {
        'id': 7,
        'title': 'Previous year expense',
        'amount_cents': 9900,
        'currency_code': 'EGP',
        'spent_on': '2025-12-31',
        'spent_time': '12:00',
        'category_id': 1,
        'notes': '',
      });

      final summary = await repository.getDashboardSummary(
        DateTime(2026, 10, 16),
        DashboardPeriod.year,
      );

      expect(summary.periodExpenseCount, 6);
      expect(summary.periodAverages.first.amountCents, 2000);
      expect(summary.periodAverages.last.amountCents, 1000);
    },
  );

  test('calculates dashboard averages separately for each currency', () async {
    final summary = await repository.getDashboardSummary(
      DateTime(2026, 10, 16),
      DashboardPeriod.month,
    );

    expect(summary.monthExpenseCount, 5);
    expect(summary.periodExpenseCount, 5);
    expect(summary.periodAverages.map((entry) => entry.currencyCode).toList(), [
      'EGP',
      'USD',
    ]);
    expect(summary.periodAverages.first.amountCents, 1750);
    expect(summary.periodAverages.last.amountCents, 1000);
  });
}
