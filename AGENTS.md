# Pocket Ledger — Codex project instructions

## Product
Pocket Ledger is a local-first personal expense tracker built with Flutter/Dart and SQLite. The current target is a Windows desktop app, with Android support planned. Users need reliable data preservation and a maintainable architecture suitable for future features.

## Existing product expectations
- Add, edit, and delete expenses.
- Manage categories, including safe reassignment of linked expenses before deleting a category.
- Reject numeric-only expense names and category names; accept names containing Unicode letters, including Arabic.
- Category picker supports predefined and custom categories.
- Transactions support date filtering and one active sort field at a time: date, amount, or category, each with ascending/descending direction. Date sorting is date-only; time is displayed separately.
- Expenses can use different currencies. Never sum amounts from different currencies into one total unless a clearly specified exchange-rate conversion is implemented. Keep mixed-currency summaries grouped by currency.
- Overview includes average spending over a selected current period.
- English and Arabic UI are supported. Arabic uses RTL layout. Translate built-in categories and currency display names; preserve custom category names as entered. Keep ISO currency codes (EGP, USD, etc.) as codes.
- SQLite is the source of truth. CSV import/export is for portability and backups.

## Engineering rules
- Preserve existing user data. Never delete, reset, or recreate the production database as a debugging shortcut.
- Do not make schema changes without a versioned migration and a migration test.
- Keep monetary calculations precise (integer minor units / cents, not binary floating-point).
- Keep UI, repository, and database responsibilities separated.
- Use small, focused changes. Do not rewrite the app or add packages without a clear need.
- Respect the existing Flutter/Dart versions and dependency constraints. Do not run blanket major-version upgrades.
- Add stable widget keys where tests need to locate controls; do not couple tests to translated UI strings unless the test is explicitly about localization.
- Avoid `pumpAndSettle()` when an indeterminate animation (for example, `CircularProgressIndicator`) may remain active. Prefer finite pumps or wait for a specific condition.
- Tests must have bounded waits and fail with a useful diagnostic instead of hanging.
- After changes, run `dart format lib test`, `flutter analyze`, and the relevant targeted test; then run `flutter test` if possible. Report any command not actually run.
- Do not claim tests passed unless their output confirms it.

## Current priority
Investigate and fix the hang in `test/features/category_management_responsive_test.dart`. Preserve the actual behavior being tested: the category-management dialog must fit in a compact window, reject a numeric-only category name, show validation feedback, and produce no Flutter layout exception. Do not weaken or delete these assertions just to make the test pass.
