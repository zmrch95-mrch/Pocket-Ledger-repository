import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/app_localizations.dart';
import '../../core/currencies.dart';
import '../../data/expense_repository.dart';
import '../categories/category_management_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.repository,
    required this.currencyCode,
    required this.onCurrencyChanged,
    required this.languageCode,
    required this.onLanguageChanged,
  });

  final ExpenseRepository repository;
  final String currencyCode;
  final ValueChanged<String> onCurrencyChanged;
  final String languageCode;
  final ValueChanged<String> onLanguageChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;

  Future<void> _manageCategories() async {
    await showCategoryManagementDialog(context, repository: widget.repository);
  }

  Future<void> _importCsv() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (files.isEmpty || !mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.tr('Import expenses?')),
          content: Text(
            context.tr(
              'Imported rows are added to your existing records. Importing the same CSV more than once will create duplicate expenses. Continue?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.tr('Import')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      setState(() => _busy = true);
      final bytes = await files.first.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: false);
      final result = await widget.repository.importCsv(content);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.tr('Imported')} ${context.localizeNumber(result.imported)} ${context.tr('expenses')}. '
            '${context.localizeNumber(result.skipped)} ${context.tr('invalid rows skipped')}.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('Import failed')}: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv() async {
    final exportDialogTitle = context.tr('Export expenses');
    try {
      setState(() => _busy = true);
      final content = await widget.repository.exportCsv();
      final savedFile = await FilePicker.saveFile(
        dialogTitle: exportDialogTitle,
        fileName: 'pocket_ledger_expenses.csv',
        bytes: Uint8List.fromList(utf8.encode(content)),
      );

      if (!mounted) return;
      if (savedFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('CSV export saved successfully.'))),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('Export failed')}: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Settings'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.tr(
                  'Manage how Pocket Ledger stores and displays your data.',
                ),
                style: const TextStyle(color: Color(0xFF71807D)),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeading(
                        icon: Icons.tune_outlined,
                        title: context.tr('Preferences'),
                        subtitle: context.tr(
                          'Choose the default currency for new expenses and your app language.',
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 380,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(
                            'default-currency-${widget.currencyCode}',
                          ),
                          initialValue: widget.currencyCode,
                          decoration: InputDecoration(
                            labelText: context.tr(
                              'Default currency for new expenses',
                            ),
                          ),
                          items: supportedCurrencies.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(
                                    context.tr(entry.value),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _busy
                              ? null
                              : (value) {
                                  if (value != null) {
                                    widget.onCurrencyChanged(value);
                                  }
                                },
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 380,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('language-${widget.languageCode}'),
                          initialValue: widget.languageCode,
                          decoration: InputDecoration(
                            labelText: context.tr('Language'),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(context.tr('English')),
                            ),
                            DropdownMenuItem(
                              value: 'ar',
                              child: Text(context.tr('Arabic')),
                            ),
                          ],
                          onChanged: _busy
                              ? null
                              : (value) {
                                  if (value != null) {
                                    widget.onLanguageChanged(value);
                                  }
                                },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr(
                          'Each expense keeps its own currency. Changing this default will not convert existing records.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF788681),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeading(
                        icon: Icons.category_outlined,
                        title: context.tr('Categories'),
                        subtitle: context.tr(
                          'Create, organize, and remove expense categories.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr(
                          'Categories are shared by the add-expense form, transaction filters, and reports. When deleting a category that is already used, you can move its expenses to another category.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF788681),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _manageCategories,
                        icon: const Icon(Icons.tune_outlined),
                        label: Text(context.tr('Manage categories')),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeading(
                        icon: Icons.swap_horiz,
                        title: context.tr('Import and export'),
                        subtitle: context.tr(
                          'Move your records between Pocket Ledger and spreadsheet apps.',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _importCsv,
                            icon: const Icon(Icons.file_upload_outlined),
                            label: Text(context.tr('Import CSV')),
                          ),
                          FilledButton.icon(
                            onPressed: _busy ? null : _exportCsv,
                            icon: const Icon(Icons.file_download_outlined),
                            label: Text(context.tr('Export CSV')),
                          ),
                        ],
                      ),
                      if (_busy) ...[
                        const SizedBox(height: 18),
                        const LinearProgressIndicator(),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        context.tr(
                          'You can import the expenses.csv file created by your earlier Python app. The importer accepts both DD-MM-YYYY and YYYY-MM-DD dates. Export a CSV backup regularly and keep it somewhere safe. Exports include the currency stored with each expense.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF788681),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeading(
                        icon: Icons.shield_outlined,
                        title: context.tr('Privacy and storage'),
                        subtitle: context.tr(
                          'Your expenses are stored locally on this computer.',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.tr(
                          'Pocket Ledger does not require an account and does not send your expense records to a server. The application uses a SQLite database in your operating system’s application-support folder. CSV export is provided so you can keep an independent copy of your records.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF788681),
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5F3),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: const Color(0xFF47766F)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF82908C), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
