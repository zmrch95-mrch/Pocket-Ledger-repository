import 'package:flutter/widgets.dart';

import 'formatters.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ar')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'AppLocalizations is not available in this context.');
    return value!;
  }

  String translate(String source) {
    if (locale.languageCode != 'ar') return source;
    return localizeDigits(
      _arabic[source] ?? source,
      locale: locale.languageCode,
    );
  }

  String translateCategory(String category) {
    if (locale.languageCode != 'ar') return category;
    const builtInCategories = <String, String>{
      'food': 'Food',
      'transport': 'Transport',
      'bills': 'Bills',
      'shopping': 'Shopping',
      'health': 'Health',
      'education': 'Education',
      'entertainment': 'Entertainment',
      'other': 'Other',
      'groceries': 'Groceries',
    };
    final source = builtInCategories[category.trim().toLowerCase()];
    return source == null ? category : translate(source);
  }

  bool hasCategoryNameCollision(
    String candidate,
    Iterable<String> existingCategories,
  ) {
    final candidateName = _normalizeCategoryName(translateCategory(candidate));
    return existingCategories.any(
      (name) =>
          _normalizeCategoryName(translateCategory(name)) == candidateName,
    );
  }

  String _normalizeCategoryName(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');

  String translateCurrencyCode(String currencyCode) {
    final source = switch (currencyCode.trim().toUpperCase()) {
      'EGP' => 'Egyptian pound (EGP)',
      'USD' => 'US dollar (USD)',
      'EUR' => 'Euro (EUR)',
      'GBP' => 'British pound (GBP)',
      'SAR' => 'Saudi riyal (SAR)',
      'AED' => 'UAE dirham (AED)',
      _ => currencyCode,
    };
    return translate(source);
  }

  String translateCurrencyName(String currencyCode) {
    final source = switch (currencyCode.trim().toUpperCase()) {
      'EGP' => 'Egyptian pound',
      'USD' => 'US dollar',
      'EUR' => 'Euro',
      'GBP' => 'British pound',
      'SAR' => 'Saudi riyal',
      'AED' => 'UAE dirham',
      _ => currencyCode,
    };
    return translate(source);
  }

  String translateFormatted(String source, Map<String, Object?> values) {
    var output = translate(source);
    for (final entry in values.entries) {
      final value = entry.value;
      final formattedValue = value is num
          ? localizeDigits('$value', locale: locale.languageCode)
          : '$value';
      output = output.replaceAll('{${entry.key}}', formattedValue);
    }
    return output;
  }

  static const Map<String, String> _arabic = {
    'Overview': 'نظرة عامة',
    'Transactions': 'المعاملات',
    'Reports': 'التقارير',
    'Settings': 'الإعدادات',
    'Your data stays on this device.': 'بياناتك محفوظة على هذا الجهاز.',
    'Your spending at a glance': 'ملخص إنفاقك',
    'Add expense': 'إضافة مصروف',
    'Edit expense': 'تعديل المصروف',
    'Spent this month': 'إجمالي إنفاق هذا الشهر',
    'Expenses this month': 'مصروفات هذا الشهر',
    'Average expense': 'متوسط المصروف',
    'Recent expenses': 'أحدث المصروفات',
    'View all': 'عرض الكل',
    'More details': 'مزيد من التفاصيل',
    'This month': 'هذا الشهر',
    'This quarter': 'هذا الربع',
    'This year': 'هذه السنة',
    'No expenses yet': 'لا توجد مصروفات بعد',
    'Add your first expense to start tracking your spending.':
        'أضف أول مصروف لبدء تتبع إنفاقك.',
    'No spending in this period': 'لا يوجد إنفاق خلال هذه الفترة',
    'Average per recorded transaction': 'متوسط قيمة المعاملة المسجلة',
    'Review, search, edit, and organize every expense.':
        'راجع مصروفاتك وابحث عنها وعدّلها ونظّمها.',
    'Search name or notes': 'ابحث بالاسم أو الملاحظات',
    'Clear search': 'مسح البحث',
    'Category': 'الفئة',
    'All categories': 'كل الفئات',
    'Currency': 'العملة',
    'All currencies': 'كل العملات',
    'Filter by date': 'تصفية حسب التاريخ',
    'Show expenses within a selected date range':
        'عرض المصروفات ضمن نطاق زمني محدد',
    'Clear filters': 'مسح عوامل التصفية',
    'Unable to load transactions': 'تعذر تحميل المعاملات',
    'No matching expenses': 'لا توجد مصروفات مطابقة',
    'Try changing or clearing your filters.':
        'جرّب تغيير عوامل التصفية أو مسحها.',
    'Select “Add expense” to record your first transaction.':
        'اختر «إضافة مصروف» لتسجيل أول معاملة.',
    'Choose one column to sort by, then select ascending or descending.':
        'اختر عموداً واحداً للترتيب، ثم حدد الترتيب التصاعدي أو التنازلي.',
    'Expense': 'المصروف',
    'Date': 'التاريخ',
    'Time': 'الوقت',
    'Amount': 'المبلغ',
    'Food': 'الطعام',
    'Transport': 'المواصلات',
    'Bills': 'الفواتير',
    'Shopping': 'التسوق',
    'Health': 'الصحة',
    'Education': 'التعليم',
    'Entertainment': 'الترفيه',
    'Other': 'أخرى',
    'Groceries': 'البقالة',
    'Expense added.': 'تمت إضافة المصروف.',
    'Expense updated.': 'تم تحديث المصروف.',
    'Expense deleted.': 'تم حذف المصروف.',
    'Delete expense?': 'هل تريد حذف المصروف؟',
    'Cancel': 'إلغاء',
    'Delete': 'حذف',
    'Delete expense': 'حذف المصروف',
    'Unable to load overview': 'تعذر تحميل النظرة العامة',
    'Choose a period': 'اختر الفترة',
    'Average for this month': 'المتوسط لهذا الشهر',
    'Average for this quarter': 'المتوسط لهذا الربع',
    'Average for this year': 'المتوسط لهذه السنة',
    'Understand where your money is going.': 'تعرّف على أين يذهب إنفاقك.',
    'Previous month': 'الشهر السابق',
    'Next month': 'الشهر التالي',
    'Total spending': 'إجمالي الإنفاق',
    'Spending by category': 'الإنفاق حسب الفئة',
    'Nothing to report yet': 'لا توجد بيانات للتقرير بعد',
    'There are no expenses recorded for this month. Try another month or add an expense.':
        'لا توجد مصروفات مسجلة لهذا الشهر. جرّب شهراً آخر أو أضف مصروفاً.',
    'Unable to load report': 'تعذر تحميل التقرير',
    'expense': 'مصروف',
    'expenses': 'مصروفات',
    'Manage how Pocket Ledger stores and displays your data.':
        'تحكم في طريقة حفظ Pocket Ledger لبياناتك وعرضها.',
    'Preferences': 'التفضيلات',
    'Choose the default currency for new expenses and your app language.':
        'اختر العملة الافتراضية للمصروفات الجديدة ولغة التطبيق.',
    'Default currency for new expenses': 'العملة الافتراضية للمصروفات الجديدة',
    'Language': 'اللغة',
    'English': 'الإنجليزية',
    'Arabic': 'العربية',
    'Each expense keeps its own currency. Changing this default will not convert existing records.':
        'يحتفظ كل مصروف بعملته الخاصة. تغيير العملة الافتراضية لا يحوّل السجلات السابقة.',
    'Categories': 'الفئات',
    'Create, organize, and remove expense categories.':
        'أنشئ فئات المصروفات ونظّمها واحذفها.',
    'Categories are shared by the add-expense form, transaction filters, and reports. When deleting a category that is already used, you can move its expenses to another category.':
        'تُستخدم الفئات في نموذج إضافة المصروفات والتصفية والتقارير. عند حذف فئة مستخدمة، يمكنك نقل مصروفاتها إلى فئة أخرى.',
    'Manage categories': 'إدارة الفئات',
    'Import and export': 'الاستيراد والتصدير',
    'Move your records between Pocket Ledger and spreadsheet apps.':
        'انقل سجلاتك بين Pocket Ledger وتطبيقات الجداول.',
    'Import CSV': 'استيراد CSV',
    'Export CSV': 'تصدير CSV',
    'Import expenses?': 'هل تريد استيراد المصروفات؟',
    'Imported rows are added to your existing records. Importing the same CSV more than once will create duplicate expenses. Continue?':
        'ستُضاف الصفوف المستوردة إلى سجلاتك الحالية. استيراد الملف نفسه أكثر من مرة سينشئ مصروفات مكررة. هل تريد المتابعة؟',
    'Import': 'استيراد',
    'Export expenses': 'تصدير المصروفات',
    'CSV export saved successfully.': 'تم حفظ ملف CSV بنجاح.',
    'Privacy and storage': 'الخصوصية والتخزين',
    'Your expenses are stored locally on this computer.':
        'تُحفظ مصروفاتك محلياً على هذا الكمبيوتر.',
    'Pocket Ledger does not require an account and does not send your expense records to a server. The application uses a SQLite database in your operating system’s application-support folder. CSV export is provided so you can keep an independent copy of your records.':
        'لا يتطلب Pocket Ledger حساباً ولا يرسل سجلات مصروفاتك إلى خادم. يستخدم التطبيق قاعدة بيانات SQLite محلية على جهازك. يمكنك تصدير CSV للاحتفاظ بنسخة مستقلة من سجلاتك.',
    'Expense name': 'اسم المصروف',
    'Choose a category': 'اختر فئة',
    'Add custom category': 'إضافة فئة مخصصة',
    'Manage categories…': 'إدارة الفئات…',
    'Choose expense date': 'اختر تاريخ المصروف',
    'Notes (optional)': 'ملاحظات (اختياري)',
    'Save changes': 'حفظ التغييرات',
    'Save expense': 'حفظ المصروف',
    'Name': 'الاسم',
    'Category name': 'اسم الفئة',
    'New category': 'فئة جديدة',
    'Add': 'إضافة',
    'Add category': 'إضافة فئة',
    'Delete category?': 'هل تريد حذف الفئة؟',
    'Delete category': 'حذف الفئة',
    'Move expenses and delete category?': 'نقل المصروفات وحذف الفئة؟',
    'Move expenses to': 'نقل المصروفات إلى',
    'Move and delete': 'نقل وحذف',
    'At least one category must remain in the app.':
        'يجب الاحتفاظ بفئة واحدة على الأقل في التطبيق.',
    'Add your own categories or remove ones you no longer need. When a category contains expenses, you can move them to another category before deleting it.':
        'أضف فئاتك الخاصة أو احذف ما لم تعد تحتاج إليه. إذا كانت الفئة تحتوي على مصروفات، يمكنك نقلها إلى فئة أخرى قبل حذفها.',
    'Sort by': 'ترتيب حسب',
    'Sort ascending': 'ترتيب تصاعدي',
    'Sort descending': 'ترتيب تنازلي',
    'Amount values are sorted within each currency.':
        'تُرتب المبالغ داخل كل عملة على حدة.',
    'Month': 'الشهر',
    'Quarter': 'الربع',
    'Year': 'السنة',
    'Recorded transactions': 'المعاملات المسجلة',
    'Expense saved.': 'تم حفظ المصروف.',
    'Could not save expense': 'تعذر حفظ المصروف',
    'Could not delete expense': 'تعذر حذف المصروف',
    'Could not load overview': 'تعذر تحميل النظرة العامة',
    'Could not load categories': 'تعذر تحميل الفئات',
    'Could not add category': 'تعذرت إضافة الفئة',
    'Choose expense time': 'اختر وقت المصروف',
    'Choose a category.': 'اختر فئة.',
    'Unable to load categories': 'تعذر تحميل الفئات',
    'The category could not be changed': 'تعذر تعديل الفئة',
    'At least one category must remain': 'يجب الاحتفاظ بفئة واحدة على الأقل',
    'Amounts are sorted within each currency; no exchange-rate conversion is applied.':
        'يتم ترتيب المبالغ داخل كل عملة على حدة، ولا يتم تطبيق تحويل لأسعار الصرف.',
    'Apply': 'تطبيق',
    'Filter by expense date': 'تصفية حسب تاريخ المصروف',
    'Import failed': 'فشل الاستيراد',
    'Export failed': 'فشل التصدير',
    'Imported': 'تم استيراد',
    'invalid rows skipped': 'صفوف غير صالحة تم تخطيها',
    'currencies': 'عملات',
    'transaction': 'معاملة',
    'transactions': 'معاملات',
    'e.g. Pets, Dining out, Education':
        'مثال: الحيوانات الأليفة، تناول الطعام بالخارج، التعليم',
    'e.g. Pets, Education, Dining out':
        'مثال: الحيوانات الأليفة، التعليم، تناول الطعام بالخارج',
    'e.g. Weekly groceries': 'مثال: مشتريات الأسبوع',
    '"{name}" will be permanently deleted.': 'سيتم حذف «{name}» نهائياً.',
    '{category} has no linked expenses and can be deleted safely.':
        'لا توجد مصروفات مرتبطة بفئة {category} ويمكن حذفها بأمان.',
    '{category} is used by {count} expenses. Choose where those records should be moved before deleting it.':
        'تُستخدم فئة {category} في {count} مصروفات. اختر الفئة التي تريد نقل هذه السجلات إليها قبل الحذف.',
    'A category with this name already exists.': 'توجد فئة بهذا الاسم بالفعل.',
    'Choose another category for the {count} linked expenses.':
        'اختر فئة أخرى لنقل المصروفات المرتبطة وعددها {count}.',
    'The replacement category no longer exists.':
        'الفئة البديلة لم تعد موجودة.',
    'Choose a different replacement category.': 'اختر فئة بديلة مختلفة.',
    'At least one category must remain.': 'يجب الاحتفاظ بفئة واحدة على الأقل.',
    'Enter an expense name.': 'أدخل اسم المصروف.',
    'Enter a category name.': 'أدخل اسم الفئة.',
    'The expense name must contain at least one letter.':
        'يجب أن يحتوي اسم المصروف على حرف واحد على الأقل.',
    'The category name must contain at least one letter.':
        'يجب أن يحتوي اسم الفئة على حرف واحد على الأقل.',
    'The expense name must be 120 characters or fewer.':
        'يجب ألا يتجاوز اسم المصروف 120 حرفاً.',
    'The category name must be 50 characters or fewer.':
        'يجب ألا يتجاوز اسم الفئة 50 حرفاً.',
    'Enter a positive amount with up to two decimal places.':
        'أدخل مبلغاً موجباً بحد أقصى منزلتين عشريتين.',
    'The amount must be greater than zero.': 'يجب أن يكون المبلغ أكبر من صفر.',
    'Use DD-MM-YYYY, for example 15-10-2026.':
        'استخدم التنسيق يوم-شهر-سنة، مثل ١٥-١٠-٢٠٢٦.',
    'Egyptian pound': 'جنيه مصري',
    'US dollar': 'دولار أمريكي',
    'Euro': 'يورو',
    'British pound': 'جنيه إسترليني',
    'Saudi riyal': 'ريال سعودي',
    'UAE dirham': 'درهم إماراتي',
    'Egyptian pound (EGP)': 'جنيه مصري (EGP)',
    'US dollar (USD)': 'دولار أمريكي (USD)',
    'Euro (EUR)': 'يورو (EUR)',
    'British pound (GBP)': 'جنيه إسترليني (GBP)',
    'Saudi riyal (SAR)': 'ريال سعودي (SAR)',
    'UAE dirham (AED)': 'درهم إماراتي (AED)',
    'Done': 'تم',
    'You can import the expenses.csv file created by your earlier Python app. The importer accepts both DD-MM-YYYY and YYYY-MM-DD dates. Export a CSV backup regularly and keep it somewhere safe. Exports include the currency stored with each expense.':
        'يمكنك استيراد ملف expenses.csv الذي أنشأه تطبيق Python السابق. يقبل المستورد تنسيقي التاريخ DD-MM-YYYY وYYYY-MM-DD. صدّر نسخة CSV احتياطية بانتظام واحتفظ بها في مكان آمن. تتضمن الملفات المصدّرة العملة المحفوظة مع كل مصروف.',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const {'en', 'ar'}.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationContext on BuildContext {
  String get localeCode => AppLocalizations.of(this).locale.languageCode;

  String localizeNumber(num value) =>
      localizeDigits('$value', locale: localeCode);

  String tr(String source) => AppLocalizations.of(this).translate(source);

  String trCategory(String category) =>
      AppLocalizations.of(this).translateCategory(category);

  bool hasCategoryNameCollision(
    String candidate,
    Iterable<String> existingCategories,
  ) => AppLocalizations.of(
    this,
  ).hasCategoryNameCollision(candidate, existingCategories);

  String trCurrencyCode(String currencyCode) =>
      AppLocalizations.of(this).translateCurrencyCode(currencyCode);

  String trCurrencyName(String currencyCode) =>
      AppLocalizations.of(this).translateCurrencyName(currencyCode);

  String trf(String source, Map<String, Object?> values) =>
      AppLocalizations.of(this).translateFormatted(source, values);
}
