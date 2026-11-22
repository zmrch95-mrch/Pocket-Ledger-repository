# Changelog

## 1.1.0

- Added category management from Settings and the expense form.
- Added custom category creation and deletion.
- When deleting a category with linked expenses, the user can reassign those expenses to another category in one database transaction.
- Added Unicode-aware validation so expense names and categories must contain at least one letter; English, Arabic, and other scripts are supported.
- Added a category dropdown to the expense form with Add custom category and Manage categories actions.
- Renamed the built-in Groceries category to Food. Existing Groceries expenses are merged into Food during the database migration.
- Made the transaction date-range filter more explicit in the interface.
- Added validation tests and upgraded the SQLite schema to version 2.

## 1.2.0

- Fixed the add-custom-category dialog lifecycle: its text controller is now owned and disposed by the dialog state, avoiding disposal while the dialog is still leaving the widget tree.
- Added transaction sorting by date/time (oldest first or newest first).
- Added alphabetical category sorting (A–Z or Z–A); transactions within each category are shown newest first.
- Added widget and repository tests for dialog completion and all transaction sort modes.

## 1.2.1

- Removed redundant SQLite API imports.
- Removed an unused category-management helper.
- Updated dropdown form fields to use `initialValue` instead of deprecated `value`.
- Simplified an unused callback parameter name.


## 1.3.0

- Replaced the lifetime spending tile with average expense per recorded transaction for the current month, quarter, or year, with a shortcut to Reports.
- Added an explicit currency to every expense. Existing expenses inherit the previously configured default currency during the schema migration; changing the default later affects new expenses only.
- Separated mixed-currency totals and averages by currency. No unsupported or implicit exchange-rate conversion is performed.
- Added a currency filter to Transactions and amount sorting within each currency.
- Added two-level transaction sorting across date/time, amount, and category.
- Added English and Arabic interface language preferences with Flutter's right-to-left layout for Arabic.
- Improved currency spacing and localized currency labels.
- Extended CSV imports/exports with an optional `exp currency` column while preserving compatibility with older CSV files.


## 1.3.1

- Resolved all six Dart analyzer informational lints reported against 1.3.0.
- Captured the export dialog title before awaiting the CSV export to avoid using a BuildContext across an asynchronous gap.
- Reworked the custom-category dialog widget test to use a stable keyed trigger, settle the initial route, and assert that the dialog closes and returns the entered category.


## 1.3.2

- Reworked the category manager into a height-constrained dialog with a flexible, scrollable category list. Validation messages no longer push the dialog content beyond the available window height.
- Added Arabic display translations for the built-in categories in category management, expense entry, transaction filters and tables, dashboard activity, and reports. User-defined category names remain as entered.
- Localized currency names in the transaction currency filter; ISO currency codes remain unchanged in monetary values and CSV exports.
- Simplified transaction sorting to one active field at a time: date, amount, or category. Removed secondary sorting and date/time sorting; date sorting now uses the date only, with stable record order for expenses on the same date.
- Added tests for Arabic category/currency display and category-manager behavior in a compact window.


## 1.3.3

- Fixed the compact-window category-manager widget test to wait for loaded category data instead of using `pumpAndSettle` while an indeterminate loading animation is active.
- Kept the regression coverage for numeric-only category validation and verified the dialog stays within the compact test viewport without layout exceptions.
- No application behavior or database schema changes.


## 1.3.4

- Added stable keys to category list rows so widget tests can locate category records independently of their translated display names.
- Made the compact-window category-manager test use an explicit English test locale for deterministic validation-message assertions.
- Replaced the localized `Food` text finder with a stable category-row key, preventing Arabic translation or host locale settings from causing false test failures.
- No database schema or application data changes.


## 1.3.5

- Fixed the compact-window category-management test so it no longer waits for a lazily rendered category row as a proxy for database readiness.
- Added a direct repository assertion to verify that the in-memory SQLite fixture returns its seeded categories.
- Kept the compact-window validation and overflow assertions focused on dialog layout, independent of the category list's asynchronous loading animation.
- No application behavior, production database schema, or user data changes.
