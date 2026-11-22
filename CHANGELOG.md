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
