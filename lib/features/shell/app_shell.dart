import 'package:flutter/material.dart';

import '../../core/app_localizations.dart';

import '../../data/expense_repository.dart';
import '../dashboard/dashboard_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';
import '../transactions/transactions_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.repository,
    required this.languageCode,
    required this.onLanguageChanged,
  });

  final ExpenseRepository repository;
  final String languageCode;
  final ValueChanged<String> onLanguageChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  String _currencyCode = 'EGP';

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final code = await widget.repository.getCurrencyCode();
    if (mounted) setState(() => _currencyCode = code);
  }

  Future<void> _changeCurrency(String code) async {
    await widget.repository.setCurrencyCode(code);
    if (mounted) setState(() => _currencyCode = code);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      OverviewPage(
        repository: widget.repository,
        currencyCode: _currencyCode,
        onViewTransactions: () => setState(() => _selectedIndex = 1),
        onViewReports: () => setState(() => _selectedIndex = 2),
      ),
      TransactionsPage(repository: widget.repository),
      ReportsPage(repository: widget.repository),
      SettingsPage(
        repository: widget.repository,
        currencyCode: _currencyCode,
        onCurrencyChanged: _changeCurrency,
        languageCode: widget.languageCode,
        onLanguageChanged: widget.onLanguageChanged,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _Sidebar(
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE7ECEB),
            ),
            Expanded(child: pages[_selectedIndex]),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (icon: Icons.space_dashboard_outlined, label: 'Overview'),
    (icon: Icons.receipt_long_outlined, label: 'Transactions'),
    (icon: Icons.insert_chart_outlined, label: 'Reports'),
    (icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    return Container(
      width: 224,
      color: Colors.white,
      padding: const EdgeInsetsDirectional.fromSTEB(18, 24, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8, bottom: 30),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Pocket Ledger',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < _items.length; index++)
            _SidebarItem(
              icon: _items[index].icon,
              label: localizations.translate(_items[index].label),
              selected: selectedIndex == index,
              onTap: () => onSelected(index),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 17, color: Color(0xFF52726D)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('Your data stays on this device.'),
                    style: TextStyle(
                      color: Color(0xFF60716E),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF61716E);

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? const Color(0xFFEAF3F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
