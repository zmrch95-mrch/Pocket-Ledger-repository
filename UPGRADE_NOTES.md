# Updating an existing Pocket Ledger installation

1. Open the current Pocket Ledger app and use **Settings → Export CSV**. Keep the exported backup somewhere safe.
2. Close Pocket Ledger.
3. Extract this update archive to a temporary folder.
4. Copy the extracted `lib` and `test` folders, `pubspec.yaml`, `README.md`, `CHANGELOG.md`, and `UPGRADE_NOTES.md` into your existing `pocket_ledger_source` folder. Allow Windows to replace matching files.
5. Keep your existing `windows` folder, `.metadata`, and other Flutter-generated platform files. Do not delete your local database or application-support folder.
6. Open a terminal in your existing project folder and run:

   ```powershell
   flutter pub get
   dart format lib test
   flutter analyze
   flutter test
   flutter run -d windows
   ```

## Version 1.2.0

This update does not change the SQLite schema and does not require a database migration. Your existing local database can be kept as-is.

The add-custom-category dialog now owns its text controller in its own widget state. This prevents the controller from being disposed while the dialog's text field is still being removed during the route transition.

The Transactions screen now offers four sort modes:

- Date/time: oldest first
- Date/time: newest first
- Category: A–Z
- Category: Z–A

When sorting by category, transactions within each category are ordered newest-first. Search, category filters, and date-range filters continue to work with every sort mode.

If you are upgrading directly from version 1.0.0 and have not yet used version 1.1.0, the existing version-2 database migration will still run as part of app startup. It merges the old built-in `Groceries` category into `Food` while preserving linked expenses.


## Version 1.2.1 — analyzer cleanup

This is a source-only maintenance update. It does not change the database schema or stored expense data. Replace the project's `lib`, `test`, `pubspec.yaml`, and `CHANGELOG.md` with the corresponding files from this archive, then run:

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
```

The update removes redundant imports and an unused helper, updates deprecated `DropdownButtonFormField.value` arguments to `initialValue`, and simplifies a callback parameter.
