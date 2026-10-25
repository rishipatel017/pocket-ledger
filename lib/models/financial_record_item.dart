enum FinancialRecordType {
  fixedDeposit,
  recurringDeposit,
  insurancePolicy,
  ppfOrPf,
  bondOrGovtScheme,
  other
}

extension FinancialRecordTypeExtension on FinancialRecordType {
  String get displayName {
    switch (this) {
      case FinancialRecordType.fixedDeposit:
        return 'Fixed Deposit (FD)';
      case FinancialRecordType.recurringDeposit:
        return 'Recurring Deposit (RD)';
      case FinancialRecordType.insurancePolicy:
        return 'Insurance Policy';
      case FinancialRecordType.ppfOrPf:
        return 'PPF / EPF';
      case FinancialRecordType.bondOrGovtScheme:
        return 'Bonds / Gov Scheme';
      case FinancialRecordType.other:
        return 'Other Record';
    }
  }
}

class FinancialRecordItem {
  final String id;
  final String title;
  final FinancialRecordType type;
  final String institution;
  final double principalOrPremium;
  final double? interestRate; // e.g. 7.1 (%)
  final double? maturityAmount;
  final DateTime startDate;
  final DateTime maturityOrRenewalDate;
  final String? policyOrAccountNumber;
  final String? notes;
  final bool isArchived;

  FinancialRecordItem({
    required this.id,
    required this.title,
    required this.type,
    required this.institution,
    required this.principalOrPremium,
    this.interestRate,
    this.maturityAmount,
    required this.startDate,
    required this.maturityOrRenewalDate,
    this.policyOrAccountNumber,
    this.notes,
    this.isArchived = false,
  });

  int get daysUntilMaturity {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      maturityOrRenewalDate.year,
      maturityOrRenewalDate.month,
      maturityOrRenewalDate.day,
    );
    return target.difference(today).inDays;
  }

  bool get isMatured => daysUntilMaturity < 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'institution': institution,
        'principalOrPremium': principalOrPremium,
        'interestRate': interestRate,
        'maturityAmount': maturityAmount,
        'startDate': startDate.toIso8601String(),
        'maturityOrRenewalDate': maturityOrRenewalDate.toIso8601String(),
        'policyOrAccountNumber': policyOrAccountNumber,
        'notes': notes,
        'isArchived': isArchived,
      };

  factory FinancialRecordItem.fromJson(Map<String, dynamic> json) =>
      FinancialRecordItem(
        id: json['id'] as String,
        title: json['title'] as String,
        type: FinancialRecordType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => FinancialRecordType.fixedDeposit,
        ),
        institution: json['institution'] as String,
        principalOrPremium: (json['principalOrPremium'] as num).toDouble(),
        interestRate: (json['interestRate'] as num?)?.toDouble(),
        maturityAmount: (json['maturityAmount'] as num?)?.toDouble(),
        startDate: DateTime.parse(json['startDate'] as String),
        maturityOrRenewalDate:
            DateTime.parse(json['maturityOrRenewalDate'] as String),
        policyOrAccountNumber: json['policyOrAccountNumber'] as String?,
        notes: json['notes'] as String?,
        isArchived: json['isArchived'] as bool? ?? false,
      );

  FinancialRecordItem copyWith({
    String? id,
    String? title,
    FinancialRecordType? type,
    String? institution,
    double? principalOrPremium,
    double? interestRate,
    double? maturityAmount,
    DateTime? startDate,
    DateTime? maturityOrRenewalDate,
    String? policyOrAccountNumber,
    String? notes,
    bool? isArchived,
  }) {
    return FinancialRecordItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      institution: institution ?? this.institution,
      principalOrPremium: principalOrPremium ?? this.principalOrPremium,
      interestRate: interestRate ?? this.interestRate,
      maturityAmount: maturityAmount ?? this.maturityAmount,
      startDate: startDate ?? this.startDate,
      maturityOrRenewalDate:
          maturityOrRenewalDate ?? this.maturityOrRenewalDate,
      policyOrAccountNumber:
          policyOrAccountNumber ?? this.policyOrAccountNumber,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
