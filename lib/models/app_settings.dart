class AppSettings {
  final String currencySymbol;
  final bool isStudentMode;
  final double studentMonthlyAllowance;
  final bool isPinLockEnabled;
  final String? pinHash;
  final String? securityQuestion;
  final String? securityAnswerHash;
  final int autoLockTimeoutSeconds; // 0: immediately on pause, 60: 1 min, 300: 5 min
  final bool hideBalances;
  final bool notificationsEnabled;
  final String themeMode; // 'system', 'light', 'dark'

  AppSettings({
    this.currencySymbol = '₹',
    this.isStudentMode = true,
    this.studentMonthlyAllowance = 8000.0,
    this.isPinLockEnabled = false,
    this.pinHash,
    this.securityQuestion,
    this.securityAnswerHash,
    this.autoLockTimeoutSeconds = 60,
    this.hideBalances = false,
    this.notificationsEnabled = true,
    this.themeMode = 'dark',
  });

  Map<String, dynamic> toJson() => {
        'currencySymbol': currencySymbol,
        'isStudentMode': isStudentMode,
        'studentMonthlyAllowance': studentMonthlyAllowance,
        'isPinLockEnabled': isPinLockEnabled,
        'pinHash': pinHash,
        'securityQuestion': securityQuestion,
        'securityAnswerHash': securityAnswerHash,
        'autoLockTimeoutSeconds': autoLockTimeoutSeconds,
        'hideBalances': hideBalances,
        'notificationsEnabled': notificationsEnabled,
        'themeMode': themeMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        currencySymbol: json['currencySymbol'] as String? ?? '₹',
        isStudentMode: json['isStudentMode'] as bool? ?? true,
        studentMonthlyAllowance:
            (json['studentMonthlyAllowance'] as num?)?.toDouble() ?? 8000.0,
        isPinLockEnabled: json['isPinLockEnabled'] as bool? ?? false,
        pinHash: json['pinHash'] as String?,
        securityQuestion: json['securityQuestion'] as String?,
        securityAnswerHash: json['securityAnswerHash'] as String?,
        autoLockTimeoutSeconds:
            json['autoLockTimeoutSeconds'] as int? ?? 60,
        hideBalances: json['hideBalances'] as bool? ?? false,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        themeMode: json['themeMode'] as String? ?? 'dark',
      );

  AppSettings copyWith({
    String? currencySymbol,
    bool? isStudentMode,
    double? studentMonthlyAllowance,
    bool? isPinLockEnabled,
    String? pinHash,
    String? securityQuestion,
    String? securityAnswerHash,
    int? autoLockTimeoutSeconds,
    bool? hideBalances,
    bool? notificationsEnabled,
    String? themeMode,
  }) {
    return AppSettings(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isStudentMode: isStudentMode ?? this.isStudentMode,
      studentMonthlyAllowance:
          studentMonthlyAllowance ?? this.studentMonthlyAllowance,
      isPinLockEnabled: isPinLockEnabled ?? this.isPinLockEnabled,
      pinHash: pinHash ?? this.pinHash,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
      autoLockTimeoutSeconds:
          autoLockTimeoutSeconds ?? this.autoLockTimeoutSeconds,
      hideBalances: hideBalances ?? this.hideBalances,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
