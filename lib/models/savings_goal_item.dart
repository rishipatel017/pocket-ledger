class SavingsGoalItem {
  final String id;
  final String title;
  final double targetAmount;
  final double currentSaved;
  final DateTime targetDate;
  final String category;
  final String? notes;

  SavingsGoalItem({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentSaved,
    required this.targetDate,
    this.category = 'General',
    this.notes,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 1.0;
    final ratio = currentSaved / targetAmount;
    return ratio.clamp(0.0, 1.0);
  }

  double get remainingAmount {
    final diff = targetAmount - currentSaved;
    return diff > 0 ? diff : 0.0;
  }

  bool get isCompleted => currentSaved >= targetAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentSaved': currentSaved,
        'targetDate': targetDate.toIso8601String(),
        'category': category,
        'notes': notes,
      };

  factory SavingsGoalItem.fromJson(Map<String, dynamic> json) =>
      SavingsGoalItem(
        id: json['id'] as String,
        title: json['title'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentSaved: (json['currentSaved'] as num).toDouble(),
        targetDate: DateTime.parse(json['targetDate'] as String),
        category: json['category'] as String? ?? 'General',
        notes: json['notes'] as String?,
      );

  SavingsGoalItem copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentSaved,
    DateTime? targetDate,
    String? category,
    String? notes,
  }) {
    return SavingsGoalItem(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentSaved: currentSaved ?? this.currentSaved,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }
}
