# Pocket Ledger

A local-first expense tracker for Windows, macOS, and Linux, built with Flutter and SQLite.

## What is included

- Desktop interface with Overview, Transactions, Reports, and Settings.
- Create, edit, and delete expenses.
- Manage categories: add custom categories, remove unused categories, or move linked expenses to another category before deleting.
- Expense names and category names must contain at least one Unicode letter; English, Arabic, and other writing systems are supported.
- Search by expense name or notes.
- Filter by category and an explicitly labeled date range.
- Sort transactions by date/time (oldest-first or newest-first) or category (A–Z or Z–A). When grouped by category, transactions within each group are newest-first.
- Monthly totals, all-time totals, and spending by category.
- Day-first dates (`DD-MM-YYYY`) in the interface and CSV exports.
- Configurable display currency (EGP, USD, EUR, GBP, SAR, AED).
- CSV import and export. The importer understands both the old Python app's
  `DD-MM-YYYY` and `YYYY-MM-DD` date formats.
- SQLite storage, integer minor-unit money values, foreign keys, indexes, and
  a schema version so future database changes can be introduced as migrations.
- No account or cloud service is required. Data stays on the computer.

## Requirements

- Flutter stable with Dart 3.10 or later.
- Windows: Visual Studio 2022 with the **Desktop development with C++** workload.
  The C++ workload is used by Flutter's generated Windows runner and build tools;
  this app does not need custom C++ business logic.
- For macOS or Linux builds, install the platform-specific desktop development
  prerequisites from the Flutter documentation.

Official Flutter desktop setup: <https://docs.flutter.dev/platform-integration/desktop>

## First-time setup on Windows

1. Extract this folder to a normal development location, for example
   `C:\Projects\pocket_ledger`.
2. Open PowerShell in the extracted `pocket_ledger_source` folder.
3. Generate the Windows runner files:

   ```powershell
   flutter create --platforms=windows .
   ```

4. Download dependencies:

   ```powershell
   flutter pub get
   ```

5. Check the project:

   ```powershell
   flutter analyze
   flutter test
   ```

6. Run the app:

   ```powershell
   flutter run -d windows
   ```

If Flutter reports that Windows is not an available device, run `flutter doctor`
and resolve the Windows desktop toolchain items it reports. You can also use
`flutter doctor -v` for more detail.

## Build a release version

```powershell
flutter build windows --release
```

Flutter writes the Windows release bundle under `build\windows\` (the exact
architecture subfolder depends on your Flutter version). Distribute the complete
runner bundle, not just the `.exe`, because the executable uses the adjacent
Flutter and plugin runtime files.

## Import your existing Python CSV

1. Start Pocket Ledger.
2. Open **Settings**.
3. Choose **Import CSV**.
4. Select the `expenses app\expenses.csv` file from your old Python project.
5. Review the import result. Rows with invalid or missing required values are
   skipped and counted; valid rows are imported in one database transaction.

The importer expects these column headings (matching your Python app):

```text
exp name, exp value, exp date, exp time, exp category
```

An optional `exp notes` column is also recognized. Exports include this extra
column so notes can be preserved when moving data between app installations.

It accepts the old `YYYY-MM-DD` format and the newer `DD-MM-YYYY` format. A
one- or two-digit hour in the old time column is interpreted as that hour at
`:00`; a three- or four-digit time is interpreted as `HMM` or `HHMM`. Exported
CSV files use `DD-MM-YYYY` and UTF-8 encoding.

## Upgrading from the first Pocket Ledger version

Before replacing the app, use **Settings → Export CSV** in your current installation to create a backup. Keep that file somewhere safe. The next launch upgrades the local database schema automatically. During this
migration, the built-in `Groceries` category is merged into `Food`: all linked
expenses are retained and reassigned to `Food`. If you had already created a
`Food` category, the two sets of expenses are combined under that category.

**Important:** importing the same CSV more than once imports its rows again.
Export a backup before experimenting with imports, and do not import the same
file repeatedly unless you intentionally want another copy of those expenses.

## Data location and backups

The SQLite database is stored in the operating system's application-support
folder, inside a `PocketLedger` directory. It is not stored beside the app's
executable, so updating or moving the app does not normally move or overwrite
your data.

Use **Settings → Export CSV** periodically to create a portable backup. Keep
that export somewhere separate from the computer running Pocket Ledger. The
SQLite database is local but is not encrypted by the app; protect the Windows
user account and any exported backups accordingly.

## Architecture

```text
lib/
  core/             Shared date and money formatting/validation
  data/             SQLite setup and expense repository
  models/           Domain models used by the UI and data layer
  features/
    shell/          Main navigation and application shell
    dashboard/      Overview and monthly summary
    transactions/   Expense table, sorting, and add/edit dialog
    categories/     Category management and custom-category dialog
    reports/        Monthly category breakdown
    settings/       Currency and CSV import/export
```

The UI talks to `ExpenseRepository`; screens do not issue SQL directly. The
repository owns queries, transactions, and CSV conversion. The database schema
is versioned through `sqflite`'s `onCreate` / `onUpgrade` callbacks. This keeps
new capabilities (budgets, recurring expenses, charts, more reports, or sync)
from being tightly coupled to the widgets.

## Current scope

This is a local-first desktop expense tracker, not a cloud accounting product. It currently
has no user accounts, multi-device synchronization, receipt scanning, recurring
transactions, or automated cloud backups. CSV export is the user-controlled
backup mechanism in this release.
