import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/app_localizations.dart';
import 'package:pocket_ledger/data/expense_repository.dart';
import 'package:pocket_ledger/features/categories/category_management_dialog.dart';
import 'package:pocket_ledger/models/category.dart';

void main() {
  testWidgets(
    'category dialog remains within a compact window when validation fails',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 520);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeCategoryManagementRepository();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: _CategoryManagerTestHost(repository: repository),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('open-category-manager')));
      // Advance the route transition by a fixed duration. Do not use
      // pumpAndSettle here because the category list has an indeterminate
      // progress indicator while its FutureBuilder request is pending.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), '2');
      await tester.tap(find.text('Add'));
      // Validation is synchronous; one frame is enough to render its message.
      await tester.pump();

      expect(
        find.text('The category name must contain at least one letter.'),
        findsOneWidget,
      );
      expect(repository.addedCategories, isEmpty);

      final dialogRect = tester.getRect(find.byType(Dialog));
      expect(dialogRect.left, greaterThanOrEqualTo(0));
      expect(dialogRect.right, lessThanOrEqualTo(900));
      expect(dialogRect.top, greaterThanOrEqualTo(0));
      expect(dialogRect.bottom, lessThanOrEqualTo(520));
      expect(tester.takeException(), isNull);
    },
  );
}

class _CategoryManagerTestHost extends StatelessWidget {
  const _CategoryManagerTestHost({required this.repository});

  final CategoryManagementRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: const ValueKey('open-category-manager'),
          onPressed: () =>
              showCategoryManagementDialog(context, repository: repository),
          child: const Text('Manage categories'),
        ),
      ),
    );
  }
}

class _FakeCategoryManagementRepository
    implements CategoryManagementRepository {
  final addedCategories = <String>[];

  @override
  Future<List<CategorySummary>> getCategorySummaries() async => const [
    CategorySummary(name: 'Food', expenseCount: 0),
    CategorySummary(name: 'Transport', expenseCount: 0),
  ];

  @override
  Future<void> addCategory(String name) async {
    addedCategories.add(name);
  }

  @override
  Future<void> deleteCategory(String name, {String? reassignTo}) async {}
}
