# Pocket Ledger 1.3.5 upgrade notes

This is a test-only maintenance release. No production Dart code or database schema changes are required.

Replace the `test` folder and `CHANGELOG.md` from this archive in your existing project. You may also replace `pubspec.yaml` if you want the project version to display as 1.3.5+10. Keep your existing database and platform folders.

Run:

```powershell
flutter pub get
flutter test test/features/category_management_responsive_test.dart
flutter test
```

The compact-window category-management test now verifies the repository's category query directly, then tests the dialog's validation and layout without relying on a lazy ListView child being built during the asynchronous FutureBuilder load. The indeterminate loading animation is not disabled or removed from the application.
