import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_localizations.dart';
import '../../core/validators.dart';
import '../../data/expense_repository.dart';
import '../../models/category.dart';

Future<void> showCategoryManagementDialog(
  BuildContext context, {
  required CategoryManagementRepository repository,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => CategoryManagementDialog(repository: repository),
  );
}

class CategoryManagementDialog extends StatefulWidget {
  const CategoryManagementDialog({super.key, required this.repository});

  final CategoryManagementRepository repository;

  @override
  State<CategoryManagementDialog> createState() =>
      _CategoryManagementDialogState();
}

class _CategoryManagementDialogState extends State<CategoryManagementDialog> {
  final _nameController = TextEditingController();
  late Future<List<CategorySummary>> _categoriesFuture;
  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = widget.repository.getCategorySummaries();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final name = _nameController.text.trim();
    final validationError = validateTextLabel(
      name,
      label: 'category name',
      maxLength: 50,
    );

    if (validationError != null) {
      setState(() => _errorMessage = context.tr(validationError));
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final existingCategories = await widget.repository.getCategorySummaries();
      if (!mounted) return;
      if (context.hasCategoryNameCollision(
        name,
        existingCategories.map((category) => category.name),
      )) {
        setState(
          () => _errorMessage = context.tr(
            'A category with this name already exists.',
          ),
        );
        return;
      }

      await widget.repository.addCategory(name);
      if (!mounted) return;
      _nameController.clear();
      setState(() {
        _categoriesFuture = widget.repository.getCategorySummaries();
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteCategory(
    CategorySummary category,
    List<CategorySummary> categories,
  ) async {
    if (categories.length <= 1) {
      setState(() {
        _errorMessage = context.tr(
          'At least one category must remain in the app.',
        );
      });
      return;
    }

    final otherCategories = categories
        .where((item) => item.name != category.name)
        .toList(growable: false);

    final request = await showDialog<_DeleteCategoryRequest>(
      context: context,
      builder: (dialogContext) {
        String? replacement = otherCategories.first.name;

        if (category.expenseCount == 0) {
          return AlertDialog(
            title: Text(context.tr('Delete category?')),
            content: Text(
              context.trf(
                '{category} has no linked expenses and can be deleted safely.',
                {'category': context.trCategory(category.name)},
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.tr('Cancel')),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  const _DeleteCategoryRequest(),
                ),
                child: Text(context.tr('Delete category')),
              ),
            ],
          );
        }

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(context.tr('Move expenses and delete category?')),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.trf(
                      '{category} is used by {count} expenses. Choose where those records should be moved before deleting it.',
                      {
                        'category': context.trCategory(category.name),
                        'count': category.expenseCount,
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: replacement,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.tr('Move expenses to'),
                    ),
                    items: [
                      for (final item in otherCategories)
                        DropdownMenuItem(
                          value: item.name,
                          child: Text(context.trCategory(item.name)),
                        ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => replacement = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.tr('Cancel')),
              ),
              FilledButton.tonal(
                onPressed: replacement == null
                    ? null
                    : () => Navigator.pop(
                        dialogContext,
                        _DeleteCategoryRequest(replacement: replacement),
                      ),
                child: Text(context.tr('Move and delete')),
              ),
            ],
          ),
        );
      },
    );

    if (request == null || !mounted) return;

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.deleteCategory(
        category.name,
        reassignTo: request.replacement,
      );
      if (!mounted) return;
      setState(() {
        _categoriesFuture = widget.repository.getCategorySummaries();
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is StateError || error is FormatException) {
      final message = error
          .toString()
          .replaceFirst('Bad state: ', '')
          .replaceFirst('FormatException: ', '');
      final linkedExpenses = RegExp(
        r'^Choose another category for the (\d+) linked expenses\.$',
      ).firstMatch(message);
      if (linkedExpenses != null) {
        return context.trf(
          'Choose another category for the {count} linked expenses.',
          {'count': int.parse(linkedExpenses.group(1)!)},
        );
      }
      return context.tr(message);
    }
    return '${context.tr('The category could not be changed')}: $error';
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final dialogWidth = math
        .max(240.0, math.min(560.0, viewport.width - 48))
        .toDouble();
    final dialogHeight = math
        .max(240.0, math.min(720.0, viewport.height - 48))
        .toDouble();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('Manage categories'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                context.tr(
                  'Add your own categories or remove ones you no longer need. When a category contains expenses, you can move them to another category before deleting it.',
                ),
                style: const TextStyle(height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      enabled: !_busy,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 50,
                      decoration: InputDecoration(
                        labelText: context.tr('New category'),
                        hintText: context.tr(
                          'e.g. Pets, Education, Dining out',
                        ),
                        counterText: '',
                      ),
                      onSubmitted: (_) => _addCategory(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _busy ? null : _addCategory,
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('Add')),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Expanded(
                child: FutureBuilder<List<CategorySummary>>(
                  future: _categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          '${context.tr('Could not load categories')}: ${snapshot.error}',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final categories = snapshot.data!.toList()
                      ..sort(
                        (a, b) => context
                            .trCategory(a.name)
                            .compareTo(context.trCategory(b.name)),
                      );
                    return ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final count = category.expenseCount;
                        final displayName = context.trCategory(category.name);
                        return ListTile(
                          key: ValueKey('category-row-${category.name}'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          leading: const Icon(Icons.label_outline),
                          title: Text(displayName),
                          subtitle: Text(
                            '${context.localizeNumber(count)} ${context.tr(count == 1 ? 'expense' : 'expenses')}',
                          ),
                          trailing: IconButton(
                            tooltip: categories.length <= 1
                                ? context.tr(
                                    'At least one category must remain',
                                  )
                                : '${context.tr('Delete')} $displayName',
                            onPressed: _busy || categories.length <= 1
                                ? null
                                : () => _deleteCategory(category, categories),
                            color: Theme.of(context).colorScheme.error,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_busy) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: Text(context.tr('Done')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteCategoryRequest {
  const _DeleteCategoryRequest({this.replacement});

  final String? replacement;
}
