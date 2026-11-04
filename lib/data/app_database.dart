import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract final class AppDatabase {
  static Future<Database> open() async {
    sqfliteFfiInit();

    final supportDirectory = await getApplicationSupportDirectory();
    final databaseDirectory = Directory(
      p.join(supportDirectory.path, 'PocketLedger'),
    );
    await databaseDirectory.create(recursive: true);

    final databasePath = p.join(databaseDirectory.path, 'pocket_ledger.sqlite');

    return databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
          await database.rawQuery('PRAGMA journal_mode = WAL');
        },
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL COLLATE NOCASE UNIQUE,
              created_at TEXT NOT NULL
            )
          ''');

          await database.execute('''
            CREATE TABLE expenses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
              currency_code TEXT NOT NULL DEFAULT 'EGP',
              spent_on TEXT NOT NULL,
              spent_time TEXT NOT NULL,
              category_id INTEGER NOT NULL,
              notes TEXT NOT NULL DEFAULT '',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (category_id)
                REFERENCES categories(id)
                ON UPDATE CASCADE
                ON DELETE RESTRICT
            )
          ''');

          await database.execute(
            'CREATE INDEX idx_expenses_date_time '
            'ON expenses(spent_on, spent_time, id)',
          );
          await database.execute(
            'CREATE INDEX idx_expenses_category_date '
            'ON expenses(category_id, spent_on)',
          );
          await database.execute(
            'CREATE INDEX idx_expenses_currency_date '
            'ON expenses(currency_code, spent_on)',
          );

          await database.execute('''
            CREATE TABLE app_settings (
              setting_key TEXT PRIMARY KEY,
              setting_value TEXT NOT NULL
            )
          ''');

          final now = DateTime.now().toIso8601String();
          final batch = database.batch();
          for (final category in [
            'Food',
            'Transport',
            'Bills',
            'Shopping',
            'Health',
            'Education',
            'Entertainment',
            'Other',
          ]) {
            batch.insert('categories', {'name': category, 'created_at': now});
          }
          batch.insert('app_settings', {
            'setting_key': 'currency_code',
            'setting_value': 'EGP',
          });
          batch.insert('app_settings', {
            'setting_key': 'language_code',
            'setting_value': 'en',
          });
          await batch.commit(noResult: true);
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            // Food is a broader category than Groceries. Merge any existing
            // Groceries transactions into Food so users do not end up with
            // overlapping categories after upgrading.
            final now = DateTime.now().toIso8601String();

            await database.insert('categories', {
              'name': 'Food',
              'created_at': now,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
            await database.insert('categories', {
              'name': 'Education',
              'created_at': now,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);

            final foodRows = await database.query(
              'categories',
              columns: ['id'],
              where: 'name = ?',
              whereArgs: ['Food'],
              limit: 1,
            );
            final groceriesRows = await database.query(
              'categories',
              columns: ['id'],
              where: 'name = ?',
              whereArgs: ['Groceries'],
              limit: 1,
            );

            if (foodRows.isNotEmpty && groceriesRows.isNotEmpty) {
              final foodId = foodRows.single['id'] as int;
              final groceriesId = groceriesRows.single['id'] as int;

              await database.update(
                'expenses',
                {'category_id': foodId},
                where: 'category_id = ?',
                whereArgs: [groceriesId],
              );
              await database.delete(
                'categories',
                where: 'id = ?',
                whereArgs: [groceriesId],
              );
            }
          }
          if (oldVersion < 3) {
            final settingRows = await database.query(
              'app_settings',
              columns: ['setting_value'],
              where: 'setting_key = ?',
              whereArgs: ['currency_code'],
              limit: 1,
            );
            final existingDefaultCurrency = settingRows.isEmpty
                ? 'EGP'
                : settingRows.single['setting_value'] as String;

            await database.execute(
              "ALTER TABLE expenses ADD COLUMN currency_code TEXT NOT NULL DEFAULT 'EGP'",
            );
            await database.update('expenses', {
              'currency_code': existingDefaultCurrency,
            });
            await database.execute(
              'CREATE INDEX idx_expenses_currency_date '
              'ON expenses(currency_code, spent_on)',
            );
            await database.insert('app_settings', {
              'setting_key': 'language_code',
              'setting_value': 'en',
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        },
      ),
    );
  }
}
