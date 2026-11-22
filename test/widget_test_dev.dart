import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/app_dev.dart';

void main() {
  testWidgets('shows a helpful message when the local database cannot start', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const StartupFailureApp(error: 'Test database failure'),
    );

    expect(find.text('Pocket Ledger could not start'), findsOneWidget);
    expect(find.text('Test database failure'), findsOneWidget);
  });
}
