enum ReminderRecurrence { oneTime, monthly, quarterly, yearly }

enum ReminderStatus { pending, paid, postponed }

extension RecurrenceExtension on ReminderRecurrence {
  String get displayName {
    switch (this) {
      case ReminderRecurrence.oneTime:
        return 'One-time';
      case ReminderRecurrence.monthly:
        return 'Monthly';
      case ReminderRecurrence.quarterly:
        return 'Quarterly';
      case ReminderRecurrence.yearly:
        return 'Yearly';
    }
  }
}

class ReminderItem {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final ReminderRecurrence recurrence;
  final String categoryId;
  final ReminderStatus status;
  final DateTime? paidDate;
  final String? notes;
  final String? linkedExpenseId;

  ReminderItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.recurrence = ReminderRecurrence.monthly,
    this.categoryId = 'utilities',
    this.status = ReminderStatus.pending,
    this.paidDate,
    this.notes,
    this.linkedExpenseId,
  });

  bool get isPaid => status == ReminderStatus.paid;
  bool get isPending => status == ReminderStatus.pending;
  bool get isPostponed => status == ReminderStatus.postponed;

  bool get isOverdue {
    if (isPaid) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  bool get isDueToday {
    if (isPaid) return false;
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'recurrence': recurrence.name,
        'categoryId': categoryId,
        'status': status.name,
        'paidDate': paidDate?.toIso8601String(),
        'notes': notes,
        'linkedExpenseId': linkedExpenseId,
      };

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        dueDate: DateTime.parse(json['dueDate'] as String),
        recurrence: ReminderRecurrence.values.firstWhere(
          (e) => e.name == json['recurrence'],
          orElse: () => ReminderRecurrence.monthly,
        ),
        categoryId: json['categoryId'] as String? ?? 'utilities',
        status: ReminderStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ReminderStatus.pending,
        ),
        paidDate: json['paidDate'] != null
            ? DateTime.parse(json['paidDate'] as String)
            : null,
        notes: json['notes'] as String?,
        linkedExpenseId: json['linkedExpenseId'] as String?,
      );

  ReminderItem copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    ReminderRecurrence? recurrence,
    String? categoryId,
    ReminderStatus? status,
    DateTime? paidDate,
    String? notes,
    String? linkedExpenseId,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      recurrence: recurrence ?? this.recurrence,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
      notes: notes ?? this.notes,
      linkedExpenseId: linkedExpenseId ?? this.linkedExpenseId,
    );
  }
}
