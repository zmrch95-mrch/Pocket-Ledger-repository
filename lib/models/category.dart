class CategorySummary {
  const CategorySummary({required this.name, required this.expenseCount});

  final String name;
  final int expenseCount;

  factory CategorySummary.fromMap(Map<String, Object?> map) {
    return CategorySummary(
      name: map['name'] as String,
      expenseCount: (map['expense_count'] as int?) ?? 0,
    );
  }
}
