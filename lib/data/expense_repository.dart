import 'package:csv/csv.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../core/currencies.dart';
import '../core/formatters.dart';
import '../core/validators.dart';
import '../models/category.dart';
import '../models/expense.dart';

abstract interface class CategoryManagementRepository {
  Future<List<CategorySummary>> getCategorySummaries();

  Future<void> addCategory(String name);

  Future<void> deleteCategory(String name, {String? reassignTo});
}

class ExpenseRepository implements CategoryManagementRepository {
  ExpenseRepository(this._database);

  final Database _database;

  static const List<String> _csvHeaders = [
    'exp name',
    'exp value',
    'exp date',
    'exp time',
    'exp category',
  ];

  static const List<String> _csvExportHeaders = [
    ..._csvHeaders,
    'exp notes',
    'exp currency',
  ];

  Future<List<Expense>> listExpenses({
    String search = '',
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String? currencyCode,
    ExpenseSort sort = const ExpenseSort(
      ExpenseSortField.date,
      ascending: true,
    ),
  }) async {
    final conditions = <String>[];
    final arguments = <Object?>[];

    if (search.trim().isNotEmpty) {
      conditions.add('(e.title LIKE ? OR e.notes LIKE ?)');
      final query = '%${search.trim()}%';
      arguments
        ..add(query)
        ..add(query);
    }

    if (category != null && category.isNotEmpty) {
      conditions.add('c.name = ?');
      arguments.add(category);
    }

    if (fromDate != null) {
      conditions.add('e.spent_on >= ?');
      arguments.add(toIsoDate(fromDate));
    }

    if (toDate != null) {
      conditions.add('e.spent_on <= ?');
      arguments.add(toIsoDate(toDate));
    }

    if (currencyCode != null && currencyCode.isNotEmpty) {
      conditions.add('e.currency_code = ?');
      arguments.add(currencyCode);
    }

    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';

    final direction = sort.ascending ? 'ASC' : 'DESC';
    final orderParts = <String>[];

    switch (sort.field) {
      case ExpenseSortField.date:
        // Use time as a secondary key to keep same-day expenses chronological.
        orderParts
          ..add('e.spent_on $direction')
          ..add('e.spent_time $direction');
      case ExpenseSortField.time:
        // Time-of-day is the selected key, with date breaking equal-time ties.
        orderParts
          ..add('e.spent_time $direction')
          ..add('e.spent_on $direction');
      case ExpenseSortField.amount:
        // Amounts in different currencies are not directly comparable.
        // Group by currency, then sort the numeric amount within each group.
        orderParts
          ..add('e.currency_code COLLATE NOCASE ASC')
          ..add('e.amount_cents $direction');
    }
    orderParts.add('e.id ASC');

    final rows = await _database.rawQuery('''
      SELECT
        e.id,
        e.title,
        e.amount_cents,
        e.currency_code,
        e.spent_on,
        e.spent_time,
        e.notes,
        c.name AS category
      FROM expenses e
      INNER JOIN categories c ON c.id = e.category_id
      $whereClause
      ORDER BY ${orderParts.join(', ')}
    ''', arguments);

    return rows.map(Expense.fromMap).toList(growable: false);
  }

  Future<List<String>> getCategories() async {
    final rows = await _database.query(
      'categories',
      columns: ['name'],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((row) => row['name'] as String).toList(growable: false);
  }

  @override
  Future<List<CategorySummary>> getCategorySummaries() async {
    final rows = await _database.rawQuery('''
      SELECT
        c.name,
        COUNT(e.id) AS expense_count
      FROM categories c
      LEFT JOIN expenses e ON e.category_id = c.id
      GROUP BY c.id, c.name
      ORDER BY c.name COLLATE NOCASE ASC
    ''');

    return rows.map(CategorySummary.fromMap).toList(growable: false);
  }

  @override
  Future<void> addCategory(String name) async {
    final normalizedName = name.trim();
    requireTextLabel(normalizedName, label: 'category name', maxLength: 50);

    await _database.transaction((transaction) async {
      final existing = await transaction.query(
        'categories',
        columns: ['id'],
        where: 'name = ?',
        whereArgs: [normalizedName],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        throw StateError('A category with this name already exists.');
      }

      await transaction.insert('categories', {
        'name': normalizedName,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  /// Deletes [name]. If it is already used, all linked expenses are moved to
  /// [reassignTo] in the same transaction before the category is removed.
  @override
  Future<void> deleteCategory(String name, {String? reassignTo}) async {
    await _database.transaction((transaction) async {
      final categories = await transaction.query(
        'categories',
        columns: ['id', 'name'],
        orderBy: 'name COLLATE NOCASE ASC',
      );

      if (categories.length <= 1) {
        throw StateError('At least one category must remain.');
      }

      final sourceRows = await transaction.query(
        'categories',
        columns: ['id'],
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (sourceRows.isEmpty) return;
      final sourceId = sourceRows.single['id'] as int;

      final usageRows = await transaction.rawQuery(
        'SELECT COUNT(*) AS expense_count FROM expenses WHERE category_id = ?',
        [sourceId],
      );
      final expenseCount = (usageRows.single['expense_count'] as int?) ?? 0;

      if (expenseCount > 0) {
        if (reassignTo == null || reassignTo.trim().isEmpty) {
          throw StateError(
            'Choose another category for the $expenseCount linked expenses.',
          );
        }

        final targetRows = await transaction.query(
          'categories',
          columns: ['id'],
          where: 'name = ?',
          whereArgs: [reassignTo.trim()],
          limit: 1,
        );

        if (targetRows.isEmpty) {
          throw StateError('The replacement category no longer exists.');
        }

        final targetId = targetRows.single['id'] as int;
        if (targetId == sourceId) {
          throw StateError('Choose a different replacement category.');
        }

        await transaction.update(
          'expenses',
          {
            'category_id': targetId,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'category_id = ?',
          whereArgs: [sourceId],
        );
      }

      await transaction.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [sourceId],
      );
    });
  }

  Future<void> saveExpense(ExpenseDraft draft, {int? id}) async {
    requireTextLabel(draft.title, label: 'expense name', maxLength: 120);
    requireTextLabel(draft.category, label: 'category name', maxLength: 50);
    final currencyCode = normalizeCurrencyCode(draft.currencyCode);
    final now = DateTime.now().toIso8601String();

    await _database.transaction((transaction) async {
      final categoryId = await _ensureCategory(
        transaction,
        draft.category.trim(),
        now,
      );

      final values = <String, Object?>{
        'title': draft.title.trim(),
        'amount_cents': draft.amountCents,
        'currency_code': currencyCode,
        'spent_on': toIsoDate(draft.spentOn),
        'spent_time': formatTime(draft.spentTime),
        'category_id': categoryId,
        'notes': draft.notes.trim(),
        'updated_at': now,
      };

      if (id == null) {
        values['created_at'] = now;
        await transaction.insert('expenses', values);
      } else {
        final updated = await transaction.update(
          'expenses',
          values,
          where: 'id = ?',
          whereArgs: [id],
        );
        if (updated == 0) {
          throw StateError('This expense no longer exists.');
        }
      }
    });
  }

  Future<void> deleteExpense(int id) async {
    await _database.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<DashboardSummary> getDashboardSummary(
    DateTime referenceDate,
    DashboardPeriod period,
  ) async {
    final monthStart = DateTime(referenceDate.year, referenceDate.month);
    final nextMonth = DateTime(referenceDate.year, referenceDate.month + 1);
    final (periodStart, periodEnd) = _periodBounds(referenceDate, period);

    final monthRows = await _database.rawQuery(
      '''
      SELECT
        currency_code,
        COALESCE(SUM(amount_cents), 0) AS total_cents,
        COUNT(*) AS expense_count
      FROM expenses
      WHERE spent_on >= ? AND spent_on < ?
      GROUP BY currency_code
      ORDER BY currency_code ASC
    ''',
      [toIsoDate(monthStart), toIsoDate(nextMonth)],
    );

    final periodRows = await _database.rawQuery(
      '''
      SELECT
        currency_code,
        SUM(amount_cents) AS total_cents,
        COUNT(*) AS expense_count
      FROM expenses
      WHERE spent_on >= ? AND spent_on < ?
      GROUP BY currency_code
      ORDER BY currency_code ASC
    ''',
      [toIsoDate(periodStart), toIsoDate(periodEnd)],
    );

    final monthCountRows = await _database.rawQuery(
      '''
      SELECT COUNT(*) AS expense_count
      FROM expenses
      WHERE spent_on >= ? AND spent_on < ?
    ''',
      [toIsoDate(monthStart), toIsoDate(nextMonth)],
    );

    final recentRows = await _database.rawQuery('''
      SELECT
        e.id,
        e.title,
        e.amount_cents,
        e.currency_code,
        e.spent_on,
        e.spent_time,
        e.notes,
        c.name AS category
      FROM expenses e
      INNER JOIN categories c ON c.id = e.category_id
      ORDER BY e.spent_on DESC, e.spent_time DESC, e.id DESC
      LIMIT 7
    ''');

    final averages = <CurrencyAmount>[];
    for (final row in periodRows) {
      final count = (row['expense_count'] as int?) ?? 0;
      if (count == 0) continue;
      averages.add(
        CurrencyAmount(
          currencyCode: row['currency_code'] as String,
          amountCents: ((row['total_cents'] as int) / count).round(),
        ),
      );
    }

    return DashboardSummary(
      monthTotals: monthRows
          .map(
            (row) => CurrencyAmount(
              currencyCode: row['currency_code'] as String,
              amountCents: (row['total_cents'] as int?) ?? 0,
            ),
          )
          .toList(growable: false),
      monthExpenseCount: (monthCountRows.single['expense_count'] as int?) ?? 0,
      periodAverages: averages,
      periodExpenseCount: periodRows.fold<int>(
        0,
        (sum, row) => sum + ((row['expense_count'] as int?) ?? 0),
      ),
      recentExpenses: recentRows.map(Expense.fromMap).toList(growable: false),
    );
  }

  (DateTime, DateTime) _periodBounds(DateTime date, DashboardPeriod period) {
    switch (period) {
      case DashboardPeriod.month:
        return (
          DateTime(date.year, date.month),
          DateTime(date.year, date.month + 1),
        );
      case DashboardPeriod.quarter:
        final firstMonth = ((date.month - 1) ~/ 3) * 3 + 1;
        return (
          DateTime(date.year, firstMonth),
          DateTime(date.year, firstMonth + 3),
        );
      case DashboardPeriod.year:
        return (DateTime(date.year), DateTime(date.year + 1));
    }
  }

  Future<List<CategoryTotal>> getCategoryTotals(DateTime month) async {
    final firstDay = DateTime(month.year, month.month);
    final nextMonth = DateTime(month.year, month.month + 1);

    final rows = await _database.rawQuery(
      '''
      SELECT
        c.name AS category,
        e.currency_code,
        COALESCE(SUM(e.amount_cents), 0) AS total_cents,
        COUNT(e.id) AS expense_count
      FROM expenses e
      INNER JOIN categories c ON c.id = e.category_id
      WHERE e.spent_on >= ? AND e.spent_on < ?
      GROUP BY c.id, c.name, e.currency_code
      ORDER BY e.currency_code ASC, total_cents DESC, c.name COLLATE NOCASE ASC
    ''',
      [toIsoDate(firstDay), toIsoDate(nextMonth)],
    );

    return rows
        .map(
          (row) => CategoryTotal(
            category: row['category'] as String,
            currencyCode: row['currency_code'] as String,
            amountCents: (row['total_cents'] as int?) ?? 0,
            expenseCount: (row['expense_count'] as int?) ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<String> getCurrencyCode() async {
    final rows = await _database.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['currency_code'],
      limit: 1,
    );

    if (rows.isEmpty) return 'EGP';
    try {
      return normalizeCurrencyCode(rows.single['setting_value'] as String);
    } on FormatException {
      return 'EGP';
    }
  }

  Future<void> setCurrencyCode(String currencyCode) async {
    final normalized = normalizeCurrencyCode(currencyCode);
    await _database.insert('app_settings', {
      'setting_key': 'currency_code',
      'setting_value': normalized,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> getLanguageCode() async {
    final rows = await _database.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['language_code'],
      limit: 1,
    );
    final storedCode = rows.isEmpty
        ? 'en'
        : rows.single['setting_value'] as String;
    return {'en', 'ar'}.contains(storedCode) ? storedCode : 'en';
  }

  Future<void> setLanguageCode(String languageCode) async {
    if (!{'en', 'ar'}.contains(languageCode)) {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
    await _database.insert('app_settings', {
      'setting_key': 'language_code',
      'setting_value': languageCode,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> exportCsv() async {
    final expenses = await listExpenses();
    final rows = <List<dynamic>>[
      _csvExportHeaders,
      for (final expense in expenses)
        [
          expense.title,
          formatCentsForInput(expense.amountCents),
          formatDate(expense.spentOn),
          expense.spentTime,
          expense.category,
          expense.notes,
          expense.currencyCode,
        ],
    ];

    return '\uFEFF${Csv(lineDelimiter: '\n').encode(rows)}';
  }

  Future<ImportResult> importCsv(String content) async {
    final cleanedContent = content.startsWith('\uFEFF')
        ? content.substring(1)
        : content;
    final decodedRows = Csv().decode(cleanedContent);

    if (decodedRows.isEmpty) {
      throw const FormatException('The selected CSV file is empty.');
    }

    final headers = decodedRows.first
        .map((value) => value.toString().trim().toLowerCase())
        .toList(growable: false);

    final requiredColumns = <String, int>{};
    for (final header in _csvHeaders) {
      final index = headers.indexOf(header);
      if (index < 0) {
        throw FormatException(
          'The CSV file is missing the required column "$header".',
        );
      }
      requiredColumns[header] = index;
    }

    String cell(List<dynamic> row, String column) {
      final index = requiredColumns[column]!;
      if (index >= row.length) return '';
      return (row[index]?.toString() ?? '').trim();
    }

    final notesColumn = headers.indexOf('exp notes');
    final currencyColumn = headers.indexOf('exp currency');
    final defaultCurrency = await getCurrencyCode();
    final drafts = <ExpenseDraft>[];
    var skipped = 0;

    for (final row in decodedRows.skip(1)) {
      if (row.every((value) => value.toString().trim().isEmpty)) continue;

      try {
        final title = cell(row, 'exp name');
        final category = cell(row, 'exp category');
        final amount = parseAmountToCents(cell(row, 'exp value'));
        final spentOn = parseExpenseDate(cell(row, 'exp date'));
        final spentTime = formatTime(
          _normalizeImportedTime(cell(row, 'exp time')),
        );
        final currencyCode =
            currencyColumn >= 0 &&
                currencyColumn < row.length &&
                row[currencyColumn].toString().trim().isNotEmpty
            ? normalizeCurrencyCode(row[currencyColumn].toString())
            : defaultCurrency;

        requireTextLabel(title, label: 'expense name', maxLength: 120);
        requireTextLabel(category, label: 'category name', maxLength: 50);

        drafts.add(
          ExpenseDraft(
            title: title,
            amountCents: amount,
            currencyCode: currencyCode,
            spentOn: spentOn,
            spentTime: spentTime,
            category: category,
            notes: notesColumn >= 0 && notesColumn < row.length
                ? row[notesColumn].toString().trim()
                : '',
          ),
        );
      } on FormatException {
        skipped++;
      }
    }

    final now = DateTime.now().toIso8601String();
    await _database.transaction((transaction) async {
      for (final draft in drafts) {
        final categoryId = await _ensureCategory(
          transaction,
          draft.category,
          now,
        );

        await transaction.insert('expenses', {
          'title': draft.title,
          'amount_cents': draft.amountCents,
          'currency_code': draft.currencyCode,
          'spent_on': toIsoDate(draft.spentOn),
          'spent_time': draft.spentTime,
          'category_id': categoryId,
          'notes': draft.notes,
          'created_at': now,
          'updated_at': now,
        });
      }
    });

    return ImportResult(imported: drafts.length, skipped: skipped);
  }

  String _normalizeImportedTime(String value) {
    final input = normalizeDigits(value).trim();

    if (RegExp(r'^\d{1,2}$').hasMatch(input)) {
      return '${input.padLeft(2, '0')}:00';
    }
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(input)) {
      final parts = input.split(':');
      return '${parts[0].padLeft(2, '0')}:${parts[1]}';
    }
    if (RegExp(r'^\d{3,4}$').hasMatch(input)) {
      final padded = input.padLeft(4, '0');
      return '${padded.substring(0, 2)}:${padded.substring(2)}';
    }
    return input;
  }

  Future<int> _ensureCategory(
    Transaction transaction,
    String name,
    String timestamp,
  ) async {
    requireTextLabel(name, label: 'category name', maxLength: 50);
    final normalizedName = name.trim();

    await transaction.insert('categories', {
      'name': normalizedName,
      'created_at': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final rows = await transaction.query(
      'categories',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [normalizedName],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw StateError('Unable to create or find category "$normalizedName".');
    }

    return rows.single['id'] as int;
  }
}
