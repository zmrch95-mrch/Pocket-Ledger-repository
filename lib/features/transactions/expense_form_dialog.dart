import 'package:flutter/material.dart';

import '../../core/app_localizations.dart';
import '../../core/formatters.dart';
import '../../core/currencies.dart';
import '../../core/validators.dart';
import '../../data/expense_repository.dart';
import '../../models/expense.dart';
import '../categories/category_management_dialog.dart';

const _addCategoryAction = '__pocket_ledger_add_category__';
const _manageCategoriesAction = '__pocket_ledger_manage_categories__';

Future<ExpenseDraft?> showExpenseFormDialog(
  BuildContext context, {
  required ExpenseRepository repository,
  Expense? expense,
}) {
  return showDialog<ExpenseDraft>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ExpenseFormDialog(repository: repository, expense: expense),
  );
}

Future<String?> showAddCategoryDialog(
  BuildContext context, {
  List<String> existingCategories = const [],
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _AddCategoryDialog(existingCategories: existingCategories),
  );
}

/// Owns its controller for exactly as long as the dialog's text field exists.
/// This avoids disposing a controller while the dialog route is still leaving
/// the widget tree.
class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog({required this.existingCategories});

  final List<String> existingCategories;

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('Add custom category')),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            maxLength: 50,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: context.tr('Category name'),
              hintText: context.tr('e.g. Pets, Dining out, Education'),
              counterText: '',
            ),
            validator: (value) {
              final error = validateTextLabel(
                value,
                label: 'category name',
                maxLength: 50,
              );
              if (error != null) return context.tr(error);
              if (context.hasCategoryNameCollision(
                value!,
                widget.existingCategories,
              )) {
                return context.tr('A category with this name already exists.');
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.tr('Add category')),
        ),
      ],
    );
  }
}

class ExpenseFormDialog extends StatefulWidget {
  const ExpenseFormDialog({super.key, required this.repository, this.expense});

  final ExpenseRepository repository;
  final Expense? expense;

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  late final TextEditingController _notesController;
  late Future<List<String>> _categoriesFuture;

  String? _selectedCategory;
  late String _selectedCurrencyCode;
  bool _currencyManuallySelected = false;
  int _categoryDropdownVersion = 0;
  late DateTime _spentOn;
  late TimeOfDay _spentTime;
  String? _dateLocaleCode;
  bool _dateInputEdited = false;
  bool _amountInputEdited = false;

  String get _storedTime =>
      '${_spentTime.hour.toString().padLeft(2, '0')}:${_spentTime.minute.toString().padLeft(2, '0')}';

  Future<void> _loadDefaultCurrency() async {
    final currencyCode = await widget.repository.getCurrencyCode();
    if (!mounted || widget.expense != null || _currencyManuallySelected) return;
    setState(() => _selectedCurrencyCode = currencyCode);
  }

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(
      text: expense == null ? '' : formatCentsForInput(expense.amountCents),
    );
    _notesController = TextEditingController(text: expense?.notes ?? '');
    _selectedCategory = expense?.category;
    _selectedCurrencyCode = expense?.currencyCode ?? 'EGP';
    if (expense == null) _loadDefaultCurrency();
    _categoriesFuture = widget.repository.getCategories();
    _spentOn = expense?.spentOn ?? DateTime.now();
    _dateController = TextEditingController(text: formatDate(_spentOn));

    if (expense == null) {
      _spentTime = TimeOfDay.now();
    } else {
      final parts = expense.spentTime.split(':');
      _spentTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = context.localeCode;
    if (_dateLocaleCode == localeCode) return;

    _dateLocaleCode = localeCode;
    if (!_dateInputEdited) {
      _dateController.text = formatDate(_spentOn, locale: localeCode);
    }
    if (!_amountInputEdited && widget.expense != null) {
      _amountController.text = formatCentsForInput(
        widget.expense!.amountCents,
        locale: localeCode,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _reloadCategories({String? select}) async {
    final categories = await widget.repository.getCategories();
    if (!mounted) return;

    setState(() {
      _categoriesFuture = Future.value(categories);
      if (select != null && categories.contains(select)) {
        _selectedCategory = select;
      } else if (_selectedCategory != null &&
          !categories.contains(_selectedCategory)) {
        _selectedCategory = null;
      }
      _categoryDropdownVersion++;
    });
  }

  Future<void> _addCustomCategory() async {
    try {
      final existingCategories = await widget.repository.getCategories();
      if (!mounted) return;
      final name = await showAddCategoryDialog(
        context,
        existingCategories: existingCategories,
      );
      if (name == null || !mounted) return;

      final latestCategories = await widget.repository.getCategories();
      if (!mounted) return;
      if (context.hasCategoryNameCollision(name, latestCategories)) {
        throw StateError('A category with this name already exists.');
      }
      await widget.repository.addCategory(name);
      await _reloadCategories(select: name);
    } catch (error) {
      if (!mounted) return;
      final message = error
          .toString()
          .replaceFirst('Bad state: ', '')
          .replaceFirst('FormatException: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.tr('Could not add category')}: ${context.tr(message)}',
          ),
        ),
      );
    }
  }

  Future<void> _manageCategories() async {
    await showCategoryManagementDialog(context, repository: widget.repository);
    await _reloadCategories();
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _spentOn,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: context.tr('Choose expense date'),
    );

    if (selected != null && mounted) {
      setState(() {
        _spentOn = selected;
        _dateInputEdited = false;
        _dateController.text = formatDate(selected, locale: context.localeCode);
      });
    }
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _spentTime,
      helpText: context.tr('Choose expense time'),
    );

    if (selected != null && mounted) {
      setState(() => _spentTime = selected);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amountCents = parseAmountToCents(_amountController.text);
    final enteredDate = parseExpenseDate(_dateController.text);
    Navigator.of(context).pop(
      ExpenseDraft(
        title: _titleController.text.trim(),
        amountCents: amountCents,
        currencyCode: _selectedCurrencyCode,
        spentOn: DateTime(enteredDate.year, enteredDate.month, enteredDate.day),
        spentTime: _storedTime,
        category: _selectedCategory!.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    return AlertDialog(
      title: Text(context.tr(isEditing ? 'Edit expense' : 'Add expense')),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: context.tr('Expense name'),
                    hintText: context.tr('e.g. Weekly groceries'),
                    prefixIcon: Icon(Icons.edit_outlined),
                    counterText: '',
                  ),
                  validator: (value) {
                    final error = validateTextLabel(
                      value,
                      label: 'expense name',
                      maxLength: 120,
                    );
                    return error == null ? null : context.tr(error);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('Amount'),
                    hintText: localizeDigits(
                      '0.00',
                      locale: context.localeCode,
                    ),
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  onChanged: (_) => _amountInputEdited = true,
                  validator: (value) {
                    try {
                      parseAmountToCents(value ?? '');
                      return null;
                    } on FormatException catch (error) {
                      return context.tr(error.message);
                    }
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: ValueKey('expense-currency-$_selectedCurrencyCode'),
                  initialValue: _selectedCurrencyCode,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('Currency'),
                    prefixIcon: Icon(Icons.currency_exchange_outlined),
                  ),
                  items: [
                    for (final entry in supportedCurrencies.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          context.tr(entry.value),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _currencyManuallySelected = true;
                        _selectedCurrencyCode = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                FutureBuilder<List<String>>(
                  future: _categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return InputDecorator(
                        decoration: InputDecoration(
                          labelText: context.tr('Category'),
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        child: Text(
                          '${context.tr('Unable to load categories')}: ${snapshot.error}',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }

                    final categories = snapshot.data!.toList()
                      ..sort(
                        (a, b) => context
                            .trCategory(a)
                            .compareTo(context.trCategory(b)),
                      );
                    final selected = categories.contains(_selectedCategory)
                        ? _selectedCategory
                        : null;

                    return DropdownButtonFormField<String>(
                      key: ValueKey(_categoryDropdownVersion),
                      initialValue: selected,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('Category'),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      hint: Text(context.tr('Choose a category')),
                      items: [
                        for (final category in categories)
                          DropdownMenuItem(
                            value: category,
                            child: Text(context.trCategory(category)),
                          ),
                        DropdownMenuItem(
                          value: _addCategoryAction,
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline, size: 19),
                              SizedBox(width: 9),
                              Text(context.tr('Add custom category')),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: _manageCategoriesAction,
                          child: Row(
                            children: [
                              Icon(Icons.settings_outlined, size: 19),
                              SizedBox(width: 9),
                              Text(context.tr('Manage categories…')),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) async {
                        if (value == _addCategoryAction) {
                          setState(() => _categoryDropdownVersion++);
                          await _addCustomCategory();
                        } else if (value == _manageCategoriesAction) {
                          setState(() => _categoryDropdownVersion++);
                          await _manageCategories();
                        } else {
                          setState(() => _selectedCategory = value);
                        }
                      },
                      validator: (value) =>
                          value == null ||
                              value == _addCategoryAction ||
                              value == _manageCategoriesAction
                          ? context.tr('Choose a category.')
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 7),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: _manageCategories,
                    icon: const Icon(Icons.tune, size: 17),
                    label: Text(context.tr('Manage categories')),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('expense-date-input'),
                        controller: _dateController,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.datetime,
                        decoration: InputDecoration(
                          labelText: context.tr('Date'),
                          hintText: 'DD-MM-YYYY',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          suffixIcon: IconButton(
                            tooltip: context.tr('Choose expense date'),
                            onPressed: _chooseDate,
                            icon: const Icon(Icons.edit_calendar_outlined),
                          ),
                        ),
                        onChanged: (_) => _dateInputEdited = true,
                        validator: (value) {
                          try {
                            parseExpenseDate(value ?? '');
                            return null;
                          } on FormatException catch (error) {
                            return context.tr(error.message);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _chooseTime,
                        icon: const Icon(Icons.schedule_outlined),
                        label: Text(
                          formatTimeForDisplay(
                            _storedTime,
                            locale: context.localeCode,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: context.tr('Notes (optional)'),
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.tr(isEditing ? 'Save changes' : 'Save expense')),
        ),
      ],
    );
  }
}
