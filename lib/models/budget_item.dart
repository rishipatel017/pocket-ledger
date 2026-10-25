class BudgetItem {
  final String id;
  final String categoryId; // 'overall' or specific category id
  final String categoryName;
  final double limitAmount;
  final String monthKey; // e.g. "2026-10"
  final double warningThreshold; // e.g. 0.8 (80%)
  final bool isEnabled;

  BudgetItem({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.limitAmount,
    required this.monthKey,
    this.warningThreshold = 0.8,
    this.isEnabled = true,
  });

  bool get isOverall => categoryId == 'overall';

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'limitAmount': limitAmount,
        'monthKey': monthKey,
        'warningThreshold': warningThreshold,
        'isEnabled': isEnabled,
      };

  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String,
        limitAmount: (json['limitAmount'] as num).toDouble(),
        monthKey: json['monthKey'] as String,
        warningThreshold: (json['warningThreshold'] as num?)?.toDouble() ?? 0.8,
        isEnabled: json['isEnabled'] as bool? ?? true,
      );

  BudgetItem copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    double? limitAmount,
    String? monthKey,
    double? warningThreshold,
    bool? isEnabled,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      limitAmount: limitAmount ?? this.limitAmount,
      monthKey: monthKey ?? this.monthKey,
      warningThreshold: warningThreshold ?? this.warningThreshold,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
