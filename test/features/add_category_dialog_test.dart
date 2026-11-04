import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/app_localizations.dart';
import 'package:pocket_ledger/features/transactions/expense_form_dialog.dart';

void main() {
  testWidgets('adding a custom category closes its dialog cleanly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _CategoryDialogTestHost(),
      ),
    );
    await tester.pumpAndSettle();

    final openDialogButton = find.byKey(
      const ValueKey('open-category-dialog-test-button'),
    );
    expect(openDialogButton, findsOneWidget);
    await tester.tap(openDialogButton);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Groceries');
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Created category: Groceries'), findsOneWidget);
  });

  testWidgets('Arabic entry rejects a duplicate translated category label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                key: const ValueKey('open-arabic-category-dialog'),
                onPressed: () => showAddCategoryDialog(
                  context,
                  existingCategories: const ['Food'],
                ),
                child: const Text('Open category dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('open-arabic-category-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('open-arabic-category-dialog')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'الطعام');
    await tester.tap(find.text('إضافة فئة'));
    await tester.pump();

    expect(find.text('توجد فئة بهذا الاسم بالفعل.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}

class _CategoryDialogTestHost extends StatefulWidget {
  const _CategoryDialogTestHost();

  @override
  State<_CategoryDialogTestHost> createState() =>
      _CategoryDialogTestHostState();
}

class _CategoryDialogTestHostState extends State<_CategoryDialogTestHost> {
  String? _createdCategory;

  Future<void> _openCategoryDialog() async {
    final category = await showAddCategoryDialog(context);
    if (!mounted || category == null) return;
    setState(() => _createdCategory = category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              key: const ValueKey('open-category-dialog-test-button'),
              onPressed: _openCategoryDialog,
              child: const Text('Open category dialog'),
            ),
            if (_createdCategory != null)
              Text('Created category: $_createdCategory'),
          ],
        ),
      ),
    );
  }
}
