import 'package:flutter/material.dart';
import 'app_dev.dart';
import 'data/app_database.dart';
import 'data/expense_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final database = await AppDatabase.open();
    final repository = ExpenseRepository(database);
    runApp(PocketLedgerApp(repository: repository));
  } catch (error, stackTrace) {
    debugPrint('Pocket Ledger startup failed: $error\n$stackTrace');
    runApp(StartupFailureApp(error: error));
  }
}
