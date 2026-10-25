enum TransactionType { expense, income, transfer }

enum PaymentMethod { cash, upi, debitCard, creditCard, bankTransfer }

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  static PaymentMethod fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'upi':
        return PaymentMethod.upi;
      case 'debitcard':
      case 'debit_card':
      case 'debit card':
        return PaymentMethod.debitCard;
      case 'creditcard':
      case 'credit_card':
      case 'credit card':
        return PaymentMethod.creditCard;
      case 'banktransfer':
      case 'bank_transfer':
      case 'bank transfer':
        return PaymentMethod.bankTransfer;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }
}

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String categoryId;
  final String categoryName;
  final PaymentMethod paymentMethod;
  final String? notes;
  final String? transferToAccount;
  final DateTime createdAt;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.categoryId,
    required this.categoryName,
    required this.paymentMethod,
    this.notes,
    this.transferToAccount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'date': date.toIso8601String(),
        'categoryId': categoryId,
        'categoryName': categoryName,
        'paymentMethod': paymentMethod.name,
        'notes': notes,
        'transferToAccount': transferToAccount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TransactionType.expense,
        ),
        date: DateTime.parse(json['date'] as String),
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String,
        paymentMethod: PaymentMethodExtension.fromString(
          json['paymentMethod'] as String?,
        ),
        notes: json['notes'] as String?,
        transferToAccount: json['transferToAccount'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );

  TransactionItem copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? categoryId,
    String? categoryName,
    PaymentMethod? paymentMethod,
    String? notes,
    String? transferToAccount,
    DateTime? createdAt,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      transferToAccount: transferToAccount ?? this.transferToAccount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
