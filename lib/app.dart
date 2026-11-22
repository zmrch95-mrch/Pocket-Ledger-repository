import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_localizations.dart';
import 'data/expense_repository.dart';
import 'features/shell/app_shell.dart';

class PocketLedgerApp extends StatefulWidget {
  const PocketLedgerApp({super.key, required this.repository});

  final ExpenseRepository repository;

  @override
  State<PocketLedgerApp> createState() => _PocketLedgerAppState();
}

class _PocketLedgerAppState extends State<PocketLedgerApp> {
  String _languageCode = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final languageCode = await widget.repository.getLanguageCode();
    if (mounted) setState(() => _languageCode = languageCode);
  }

  Future<void> _changeLanguage(String languageCode) async {
    await widget.repository.setLanguageCode(languageCode);
    if (mounted) setState(() => _languageCode = languageCode);
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF246B63);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: const Color(0xFFFFFFFF),
    );

    return MaterialApp(
      title: 'Pocket Ledger',
      locale: Locale(_languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
        fontFamily: 'Segoe UI',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7F8),
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE7ECEB)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE4E2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE4E2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: seedColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: AppShell(
        repository: widget.repository,
        languageCode: _languageCode,
        onLanguageChanged: _changeLanguage,
      ),
    );
  }
}

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Ledger',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 18),
                  Text(
                    'Pocket Ledger could not start',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The local database could not be opened. Check the '
                    'application permissions and try again.',
                  ),
                  const SizedBox(height: 16),
                  SelectableText('$error'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
