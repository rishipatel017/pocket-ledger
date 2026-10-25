import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../models/budget_item.dart';
import '../models/reminder_item.dart';
import '../models/financial_record_item.dart';
import '../models/savings_goal_item.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

enum DateFilterPreset { allTime, thisMonth, lastMonth, thisWeek, today, custom }

class AppState extends ChangeNotifier {
  final StorageService _storage;
  final NotificationService? _notificationService;
  final _uuid = const Uuid();

  AppSettings _settings = AppSettings();
  List<TransactionItem> _transactions = [];
  List<CategoryItem> _categories = [];
  List<BudgetItem> _budgets = [];
  List<ReminderItem> _reminders = [];
  List<FinancialRecordItem> _financialRecords = [];
  List<SavingsGoalItem> _savingsGoals = [];

  // Authentication Lock state
  bool _isLocked = false;

  // Transaction Filters
  String _searchQuery = '';
  TransactionType? _filterType;
  String? _filterCategoryId;
  PaymentMethod? _filterPaymentMethod;
  DateFilterPreset _dateFilterPreset = DateFilterPreset.thisMonth;
  DateTimeRange? _customDateRange;

  // Dashboard Period View: 'monthly' or 'weekly'
  String _dashboardPeriodView = 'monthly';

  AppState(this._storage, [this._notificationService]);

  // Getters
  AppSettings get settings => _settings;
  bool get isLocked => _isLocked;
  List<TransactionItem> get allTransactions => List.unmodifiable(_transactions);
  List<CategoryItem> get categories => List.unmodifiable(_categories);
  List<BudgetItem> get budgets => List.unmodifiable(_budgets);
  List<ReminderItem> get reminders => List.unmodifiable(_reminders);
  List<FinancialRecordItem> get financialRecords =>
      List.unmodifiable(_financialRecords);
  List<SavingsGoalItem> get savingsGoals => List.unmodifiable(_savingsGoals);

  String get searchQuery => _searchQuery;
  TransactionType? get filterType => _filterType;
  String? get filterCategoryId => _filterCategoryId;
  PaymentMethod? get filterPaymentMethod => _filterPaymentMethod;
  DateFilterPreset get dateFilterPreset => _dateFilterPreset;
  DateTimeRange? get customDateRange => _customDateRange;
  String get dashboardPeriodView => _dashboardPeriodView;

  String get currency => _settings.currencySymbol;
  bool get hideBalances => _settings.hideBalances;
  bool get isStudentMode => _settings.isStudentMode;

  // Initialize (only seeds on first run)
  Future<void> init() async {
    _settings = _storage.loadSettings();
    _transactions = _storage.loadTransactions();
    _categories = _storage.loadCategories();
    _budgets = _storage.loadBudgets();
    _reminders = _storage.loadReminders();
    _financialRecords = _storage.loadFinancialRecords();
    _savingsGoals = _storage.loadSavingsGoals();

    // Only seed demo data on the very first run, never again
    if (_storage.isFirstRun) {
      _seedDemoData();
      await _persistAll();
      await _storage.markSeeded();
    } else {
      // Carry forward budgets from previous month
      await carryForwardBudgets();
    }

    if (_settings.isPinLockEnabled && _settings.pinHash != null) {
      _isLocked = true;
    }

    notifyListeners();
  }

  // Reload data from storage without re-seeding (safe to call on pull-to-refresh)
  Future<void> refresh() async {
    _settings = _storage.loadSettings();
    _transactions = _storage.loadTransactions();
    _categories = _storage.loadCategories();
    _budgets = _storage.loadBudgets();
    _reminders = _storage.loadReminders();
    _financialRecords = _storage.loadFinancialRecords();
    _savingsGoals = _storage.loadSavingsGoals();
    notifyListeners();
  }

  // Formatting helper
  String formatAmount(double amount, {bool showSign = false, bool isExpense = false}) {
    if (_settings.hideBalances) {
      return '••••••';
    }
    final formatter = NumberFormat('#,##,##0.00', 'en_US');
    final formattedNumber = formatter.format(amount.abs());
    if (showSign) {
      if (isExpense || amount < 0) {
        return '-$currency$formattedNumber';
      } else {
        return '+$currency$formattedNumber';
      }
    }
    return '$currency$formattedNumber';
  }

  // --- Filtered Transactions ---
  List<TransactionItem> get filteredTransactions {
    final now = DateTime.now();
    return _transactions.where((tx) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = tx.title.toLowerCase().contains(q);
        final matchCat = tx.categoryName.toLowerCase().contains(q);
        final matchNotes = (tx.notes ?? '').toLowerCase().contains(q);
        final matchAmount = tx.amount.toString().contains(q);
        if (!matchTitle && !matchCat && !matchNotes && !matchAmount) {
          return false;
        }
      }

      // 2. Transaction Type
      if (_filterType != null && tx.type != _filterType) {
        return false;
      }

      // 3. Category
      if (_filterCategoryId != null && tx.categoryId != _filterCategoryId) {
        return false;
      }

      // 4. Payment Method
      if (_filterPaymentMethod != null &&
          tx.paymentMethod != _filterPaymentMethod) {
        return false;
      }

      // 5. Date Filter
      switch (_dateFilterPreset) {
        case DateFilterPreset.today:
          if (tx.date.year != now.year ||
              tx.date.month != now.month ||
              tx.date.day != now.day) {
            return false;
          }
          break;
        case DateFilterPreset.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final cleanStart =
              DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          final cleanEnd =
              DateTime(now.year, now.month, now.day, 23, 59, 59);
          if (tx.date.isBefore(cleanStart) || tx.date.isAfter(cleanEnd)) {
            return false;
          }
          break;
        case DateFilterPreset.thisMonth:
          if (tx.date.year != now.year || tx.date.month != now.month) {
            return false;
          }
          break;
        case DateFilterPreset.lastMonth:
          final prevMonth = DateTime(now.year, now.month - 1, 1);
          if (tx.date.year != prevMonth.year ||
              tx.date.month != prevMonth.month) {
            return false;
          }
          break;
        case DateFilterPreset.custom:
          if (_customDateRange != null) {
            final start = DateTime(
              _customDateRange!.start.year,
              _customDateRange!.start.month,
              _customDateRange!.start.day,
            );
            final end = DateTime(
              _customDateRange!.end.year,
              _customDateRange!.end.month,
              _customDateRange!.end.day,
              23,
              59,
              59,
            );
            if (tx.date.isBefore(start) || tx.date.isAfter(end)) {
              return false;
            }
          }
          break;
        case DateFilterPreset.allTime:
          break;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // --- Summary Calculations ---
  double get currentMonthIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get currentMonthExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get currentWeekExpense {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final cleanStart =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            !t.date.isBefore(cleanStart) &&
            !t.date.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59)))
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get currentWeekIncome {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final cleanStart =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            !t.date.isBefore(cleanStart) &&
            !t.date.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59)))
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get netCashFlow => currentMonthIncome - currentMonthExpense;

  double get allTimeBalance {
    final income = _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    return income - expense;
  }

  // Student Mode runway calculation
  double get studentAllowanceRemaining {
    return _settings.studentMonthlyAllowance - currentMonthExpense;
  }

  double get studentDailyBurnRate {
    final now = DateTime.now();
    final daysPassed = now.day > 0 ? now.day : 1;
    return currentMonthExpense / daysPassed;
  }

  double get studentDaysOfRunway {
    final remaining = studentAllowanceRemaining;
    final burn = studentDailyBurnRate;
    if (burn <= 0) return 30.0;
    if (remaining <= 0) return 0.0;
    return remaining / burn;
  }

  // --- Overall & Category Budgets ---
  BudgetItem? get overallBudget {
    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
    final currentBudget = _budgets.firstWhere(
      (b) => b.isOverall && b.monthKey == monthKey && b.isEnabled,
      orElse: () => BudgetItem(
        id: 'default_overall',
        categoryId: 'overall',
        categoryName: 'Monthly Budget',
        limitAmount: _settings.isStudentMode
            ? _settings.studentMonthlyAllowance
            : 20000.0,
        monthKey: monthKey,
        isEnabled: true,
      ),
    );

    // If no budget set for current month, try to carry forward from previous month
    if (currentBudget.id == 'default_overall') {
      final prevMonthKey = DateFormat('yyyy-MM').format(
        DateTime(DateTime.now().year, DateTime.now().month - 1, 1),
      );
      final prevBudget = _budgets.firstWhere(
        (b) => b.isOverall && b.monthKey == prevMonthKey && b.isEnabled,
        orElse: () => BudgetItem(
          id: 'default_overall',
          categoryId: 'overall',
          categoryName: 'Monthly Budget',
          limitAmount: _settings.isStudentMode
              ? _settings.studentMonthlyAllowance
              : 20000.0,
          monthKey: monthKey,
          isEnabled: true,
        ),
      );

      // If previous month had a custom budget, carry it forward
      if (prevBudget.id != 'default_overall') {
        return prevBudget.copyWith(
          id: 'default_overall',
          monthKey: monthKey,
        );
      }
    }

    return currentBudget;
  }

  double get overallBudgetSpent => currentMonthExpense;

  double get overallBudgetRemaining {
    final limit = overallBudget?.limitAmount ?? 0.0;
    return limit - overallBudgetSpent;
  }

  double get overallBudgetProgress {
    final limit = overallBudget?.limitAmount ?? 0.0;
    if (limit <= 0) return 0.0;
    return (overallBudgetSpent / limit).clamp(0.0, 1.0);
  }

  // Category specific budget spend
  double getCategoryBudgetSpent(String categoryId, String monthKey) {
    return _transactions
        .where((tx) =>
            tx.type == TransactionType.expense &&
            tx.categoryId == categoryId &&
            DateFormat('yyyy-MM').format(tx.date) == monthKey)
        .fold(0.0, (s, tx) => s + tx.amount);
  }

  // Reminders upcoming
  List<ReminderItem> get upcomingReminders {
    final list = _reminders.where((r) => r.isPending || r.isPostponed).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  // Financial Records upcoming maturities
  List<FinancialRecordItem> get activeFinancialRecords {
    final list = _financialRecords.where((r) => !r.isArchived).toList()
      ..sort((a, b) =>
          a.maturityOrRenewalDate.compareTo(b.maturityOrRenewalDate));
    return list;
  }

  // --- Actions: Filter Controls ---
  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setFilterType(TransactionType? type) {
    _filterType = type;
    notifyListeners();
  }

  void setFilterCategory(String? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  void setFilterPaymentMethod(PaymentMethod? method) {
    _filterPaymentMethod = method;
    notifyListeners();
  }

  void setDateFilterPreset(DateFilterPreset preset, [DateTimeRange? custom]) {
    _dateFilterPreset = preset;
    _customDateRange = custom;
    notifyListeners();
  }

  void setDashboardPeriodView(String view) {
    _dashboardPeriodView = view;
    notifyListeners();
  }

  void clearAllFilters() {
    _searchQuery = '';
    _filterType = null;
    _filterCategoryId = null;
    _filterPaymentMethod = null;
    _dateFilterPreset = DateFilterPreset.thisMonth;
    _customDateRange = null;
    notifyListeners();
  }

  // --- Actions: Transactions (FR-01) ---
  Future<void> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required DateTime date,
    required String categoryId,
    required String categoryName,
    required PaymentMethod paymentMethod,
    String? notes,
    String? transferToAccount,
  }) async {
    final item = TransactionItem(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      type: type,
      date: date,
      categoryId: categoryId,
      categoryName: categoryName,
      paymentMethod: paymentMethod,
      notes: notes,
      transferToAccount: transferToAccount,
    );
    _transactions.insert(0, item);
    await _storage.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionItem updated) async {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _transactions[index] = updated;
      await _storage.saveTransactions(_transactions);
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _storage.saveTransactions(_transactions);
    notifyListeners();
  }

  // --- Actions: Categories (FR-02) ---
  Future<void> addCategory({
    required String name,
    required int iconCodePoint,
    required int colorValue,
    required bool isExpense,
  }) async {
    final item = CategoryItem(
      id: 'custom_${_uuid.v4().substring(0, 8)}',
      name: name,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      isExpense: isExpense,
      isCustom: true,
    );
    _categories.add(item);
    await _storage.saveCategories(_categories);
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id && c.isCustom);
    await _storage.saveCategories(_categories);
    notifyListeners();
  }

  // --- Actions: Budgets (FR-05) ---
  Future<void> setBudget({
    required String categoryId,
    required String categoryName,
    required double limitAmount,
    required String monthKey,
    double warningThreshold = 0.8,
  }) async {
    final index = _budgets.indexWhere(
        (b) => b.categoryId == categoryId && b.monthKey == monthKey);
    if (index != -1) {
      _budgets[index] = _budgets[index].copyWith(
        limitAmount: limitAmount,
        warningThreshold: warningThreshold,
        isEnabled: true,
      );
    } else {
      _budgets.add(BudgetItem(
        id: _uuid.v4(),
        categoryId: categoryId,
        categoryName: categoryName,
        limitAmount: limitAmount,
        monthKey: monthKey,
        warningThreshold: warningThreshold,
      ));
    }
    await _storage.saveBudgets(_budgets);
    notifyListeners();
  }

  // Auto-carry forward budgets from previous month to current month
  Future<void> carryForwardBudgets() async {
    final currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());
    final prevMonthKey = DateFormat('yyyy-MM').format(
      DateTime(DateTime.now().year, DateTime.now().month - 1, 1),
    );

    // Get budgets from previous month
    final prevBudgets = _budgets.where((b) => b.monthKey == prevMonthKey).toList();

    // For each previous budget, if current month doesn't have one, carry it forward
    for (final prevBudget in prevBudgets) {
      final existsInCurrent = _budgets.any(
        (b) => b.categoryId == prevBudget.categoryId && b.monthKey == currentMonthKey,
      );

      if (!existsInCurrent) {
        _budgets.add(prevBudget.copyWith(
          id: _uuid.v4(),
          monthKey: currentMonthKey,
        ));
      }
    }

    await _storage.saveBudgets(_budgets);
    notifyListeners();
  }

  Future<void> toggleBudget(String id, bool enabled) async {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index != -1) {
      _budgets[index] = _budgets[index].copyWith(isEnabled: enabled);
      await _storage.saveBudgets(_budgets);
      notifyListeners();
    }
  }

  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((b) => b.id == id);
    await _storage.saveBudgets(_budgets);
    notifyListeners();
  }

  // --- Actions: Reminders & Bills (FR-06) ---
  Future<void> addReminder({
    required String title,
    required double amount,
    required DateTime dueDate,
    ReminderRecurrence recurrence = ReminderRecurrence.monthly,
    String categoryId = 'utilities',
    String? notes,
  }) async {
    final item = ReminderItem(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      dueDate: dueDate,
      recurrence: recurrence,
      categoryId: categoryId,
      notes: notes,
    );
    _reminders.add(item);
    await _storage.saveReminders(_reminders);
    
    // Schedule notification
    if (_notificationService != null && _notificationService!.isPermissionGranted) {
      await _notificationService!.scheduleReminder(item);
    }
    
    notifyListeners();
  }

  Future<void> updateReminder(ReminderItem updated) async {
    final index = _reminders.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _reminders[index] = updated;
      await _storage.saveReminders(_reminders);
      
      // Reschedule notification
      if (_notificationService != null && _notificationService!.isPermissionGranted) {
        await _notificationService!.scheduleReminder(updated);
      }
      
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String id) async {
    // Cancel notification before deleting
    if (_notificationService != null) {
      await _notificationService!.cancelNotification(id.hashCode.abs() % 10000);
    }
    
    _reminders.removeWhere((r) => r.id == id);
    await _storage.saveReminders(_reminders);
    notifyListeners();
  }

  Future<void> markReminderPaid({
    required String id,
    bool createLinkedExpense = true,
    PaymentMethod paymentMethod = PaymentMethod.upi,
  }) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final reminder = _reminders[index];
    String? linkedTxId;

    if (createLinkedExpense) {
      // Find category name
      final cat = _categories.firstWhere(
        (c) => c.id == reminder.categoryId,
        orElse: () => CategoryItem(
          id: reminder.categoryId,
          name: 'Bills & Utilities',
          iconCodePoint: Icons.bolt.codePoint,
          colorValue: Colors.amber.value,
          isExpense: true,
        ),
      );

      final tx = TransactionItem(
        id: _uuid.v4(),
        title: 'Bill Paid: ${reminder.title}',
        amount: reminder.amount,
        type: TransactionType.expense,
        date: DateTime.now(),
        categoryId: reminder.categoryId,
        categoryName: cat.name,
        paymentMethod: paymentMethod,
        notes: 'Paid via PocketLedger reminder [${reminder.title}]',
      );
      _transactions.insert(0, tx);
      await _storage.saveTransactions(_transactions);
      linkedTxId = tx.id;
    }

    _reminders[index] = reminder.copyWith(
      status: ReminderStatus.paid,
      paidDate: DateTime.now(),
      linkedExpenseId: linkedTxId,
    );

    // Cancel notification for paid reminder
    if (_notificationService != null) {
      await _notificationService!.cancelNotification(reminder.id.hashCode.abs() % 10000);
    }

    // If recurring, auto-schedule next occurrence
    if (reminder.recurrence != ReminderRecurrence.oneTime) {
      DateTime nextDue = reminder.dueDate;
      if (reminder.recurrence == ReminderRecurrence.monthly) {
        // Handle month-end correctly (e.g., Jan 31 -> Feb 28/29)
        final nextMonth = DateTime(reminder.dueDate.year, reminder.dueDate.month + 1, 1);
        final lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final day = reminder.dueDate.day > lastDayOfNextMonth ? lastDayOfNextMonth : reminder.dueDate.day;
        nextDue = DateTime(
          nextMonth.year,
          nextMonth.month,
          day,
        );
      } else if (reminder.recurrence == ReminderRecurrence.quarterly) {
        // Handle month-end for quarterly
        final nextQuarter = DateTime(reminder.dueDate.year, reminder.dueDate.month + 3, 1);
        final lastDayOfNextQuarter = DateTime(nextQuarter.year, nextQuarter.month + 1, 0).day;
        final day = reminder.dueDate.day > lastDayOfNextQuarter ? lastDayOfNextQuarter : reminder.dueDate.day;
        nextDue = DateTime(
          nextQuarter.year,
          nextQuarter.month,
          day,
        );
      } else if (reminder.recurrence == ReminderRecurrence.yearly) {
        // Handle leap years for yearly
        final nextYear = reminder.dueDate.year + 1;
        final isLeapYear = (nextYear % 4 == 0 && nextYear % 100 != 0) || (nextYear % 400 == 0);
        final maxDayFeb = isLeapYear ? 29 : 28;
        if (reminder.dueDate.month == 2 && reminder.dueDate.day == 29 && !isLeapYear) {
          nextDue = DateTime(nextYear, 2, 28);
        } else {
          nextDue = DateTime(
            nextYear,
            reminder.dueDate.month,
            reminder.dueDate.day,
          );
        }
      }

      final nextReminder = ReminderItem(
        id: _uuid.v4(),
        title: reminder.title,
        amount: reminder.amount,
        dueDate: nextDue,
        recurrence: reminder.recurrence,
        categoryId: reminder.categoryId,
        notes: reminder.notes,
        status: ReminderStatus.pending,
      );
      
      _reminders.add(nextReminder);
      
      // Schedule notification for next occurrence
      if (_notificationService != null && _notificationService!.isPermissionGranted) {
        await _notificationService!.scheduleReminder(nextReminder);
      }
    }

    await _storage.saveReminders(_reminders);
    notifyListeners();
  }

  Future<void> postponeReminder(String id, int daysToAdd) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final current = _reminders[index];
      _reminders[index] = current.copyWith(
        dueDate: current.dueDate.add(Duration(days: daysToAdd)),
        status: ReminderStatus.postponed,
      );
      await _storage.saveReminders(_reminders);
      
      // Reschedule notification
      if (_notificationService != null && _notificationService!.isPermissionGranted) {
        await _notificationService!.scheduleReminder(_reminders[index]);
      }
      
      notifyListeners();
    }
  }

  // --- Actions: Financial Records (FD, RD, Insurance) (FR-07) ---
  Future<void> addFinancialRecord({
    required String title,
    required FinancialRecordType type,
    required String institution,
    required double principalOrPremium,
    double? interestRate,
    double? maturityAmount,
    required DateTime startDate,
    required DateTime maturityOrRenewalDate,
    String? policyOrAccountNumber,
    String? notes,
  }) async {
    final item = FinancialRecordItem(
      id: _uuid.v4(),
      title: title,
      type: type,
      institution: institution,
      principalOrPremium: principalOrPremium,
      interestRate: interestRate,
      maturityAmount: maturityAmount,
      startDate: startDate,
      maturityOrRenewalDate: maturityOrRenewalDate,
      policyOrAccountNumber: policyOrAccountNumber,
      notes: notes,
    );
    _financialRecords.add(item);
    await _storage.saveFinancialRecords(_financialRecords);
    notifyListeners();
  }

  Future<void> updateFinancialRecord(FinancialRecordItem updated) async {
    final index = _financialRecords.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _financialRecords[index] = updated;
      await _storage.saveFinancialRecords(_financialRecords);
      notifyListeners();
    }
  }

  Future<void> toggleArchiveFinancialRecord(String id) async {
    final index = _financialRecords.indexWhere((r) => r.id == id);
    if (index != -1) {
      _financialRecords[index] = _financialRecords[index].copyWith(
        isArchived: !_financialRecords[index].isArchived,
      );
      await _storage.saveFinancialRecords(_financialRecords);
      notifyListeners();
    }
  }

  Future<void> deleteFinancialRecord(String id) async {
    _financialRecords.removeWhere((r) => r.id == id);
    await _storage.saveFinancialRecords(_financialRecords);
    notifyListeners();
  }

  // --- Actions: Savings Goals ---
  Future<void> addSavingsGoal({
    required String title,
    required double targetAmount,
    required double currentSaved,
    required DateTime targetDate,
    String category = 'General',
    String? notes,
  }) async {
    final item = SavingsGoalItem(
      id: _uuid.v4(),
      title: title,
      targetAmount: targetAmount,
      currentSaved: currentSaved,
      targetDate: targetDate,
      category: category,
      notes: notes,
    );
    _savingsGoals.add(item);
    await _storage.saveSavingsGoals(_savingsGoals);
    notifyListeners();
  }

  Future<void> addGoalContribution(String id, double amount) async {
    final index = _savingsGoals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final current = _savingsGoals[index];
      _savingsGoals[index] = current.copyWith(
        currentSaved: current.currentSaved + amount,
      );
      await _storage.saveSavingsGoals(_savingsGoals);
      notifyListeners();
    }
  }

  Future<void> deleteSavingsGoal(String id) async {
    _savingsGoals.removeWhere((g) => g.id == id);
    await _storage.saveSavingsGoals(_savingsGoals);
    notifyListeners();
  }

  // --- Actions: Security & PIN (FR-08) ---
  void lockApp() {
    if (_settings.isPinLockEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }

  bool unlockWithPin(String pin) {
    if (!_settings.isPinLockEnabled || _settings.pinHash == null) {
      _isLocked = false;
      notifyListeners();
      return true;
    }

    final valid = AuthService.verifyPin(pin, _settings.pinHash!);
    if (valid) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool unlockWithSecurityAnswer(String answer) {
    if (_settings.securityAnswerHash == null) return false;
    final valid =
        AuthService.verifyAnswer(answer, _settings.securityAnswerHash!);
    if (valid) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> setupPin({
    required String pin,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    _settings = _settings.copyWith(
      isPinLockEnabled: true,
      pinHash: AuthService.hashPin(pin),
      securityQuestion: securityQuestion,
      securityAnswerHash: AuthService.hashAnswer(securityAnswer),
    );
    await _storage.saveSettings(_settings);
    _isLocked = false;
    notifyListeners();
  }

  Future<void> disablePin() async {
    _settings = _settings.copyWith(
      isPinLockEnabled: false,
      pinHash: null,
      securityQuestion: null,
      securityAnswerHash: null,
    );
    await _storage.saveSettings(_settings);
    _isLocked = false;
    notifyListeners();
  }

  // --- Actions: Settings Updates (FR-09) ---
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleStudentMode(bool enabled) async {
    _settings = _settings.copyWith(isStudentMode: enabled);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setStudentAllowance(double allowance) async {
    _settings = _settings.copyWith(studentMonthlyAllowance: allowance);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleHideBalances() async {
    _settings = _settings.copyWith(hideBalances: !_settings.hideBalances);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setCurrency(String symbol) async {
    _settings = _settings.copyWith(currencySymbol: symbol);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setThemeMode(String theme) async {
    _settings = _settings.copyWith(themeMode: theme);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  // Export & Backup
  String exportCsv() {
    return _storage.generateTransactionsCsv(_transactions, currency);
  }

  String exportBackupJson() {
    return _storage.generateFullBackupJson(
      settings: _settings,
      transactions: _transactions,
      categories: _categories,
      budgets: _budgets,
      reminders: _reminders,
      financialRecords: _financialRecords,
      savingsGoals: _savingsGoals,
    );
  }

  Future<bool> restoreBackup(String jsonStr) async {
    final success = await _storage.restoreFromBackupJson(jsonStr);
    if (success) {
      await init();
    }
    return success;
  }

  Future<void> resetAllData() async {
    await _storage.clearAllData();
    // Reload fresh state without seeding demo data
    _settings = _storage.loadSettings();
    _transactions = _storage.loadTransactions();
    _categories = _storage.loadCategories();
    _budgets = _storage.loadBudgets();
    _reminders = _storage.loadReminders();
    _financialRecords = _storage.loadFinancialRecords();
    _savingsGoals = _storage.loadSavingsGoals();
    _isLocked = false;
    notifyListeners();
  }

  Future<void> _persistAll() async {
    await _storage.saveSettings(_settings);
    await _storage.saveTransactions(_transactions);
    await _storage.saveCategories(_categories);
    await _storage.saveBudgets(_budgets);
    await _storage.saveReminders(_reminders);
    await _storage.saveFinancialRecords(_financialRecords);
    await _storage.saveSavingsGoals(_savingsGoals);
  }

  // --- Seed Realistic Demo Data for Instant Exploration ---
  void _seedDemoData() {
    final now = DateTime.now();
    _categories = CategoryItem.defaultCategories;

    // More realistic and varied transactions
    _transactions = [
      // Income this month
      TransactionItem(
        id: _uuid.v4(),
        title: 'Monthly Pocket Allowance',
        amount: 8500.0,
        type: TransactionType.income,
        date: DateTime(now.year, now.month, 1, 9, 30),
        categoryId: 'pocket_money',
        categoryName: 'Pocket Money / Allowance',
        paymentMethod: PaymentMethod.upi,
        notes: 'Monthly allowance from parents',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Freelance Mobile App UI',
        amount: 4500.0,
        type: TransactionType.income,
        date: DateTime(now.year, now.month, 7, 14, 30),
        categoryId: 'freelance',
        categoryName: 'Freelance & Side Hustle',
        paymentMethod: PaymentMethod.bankTransfer,
        notes: 'Flutter app screens design project',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Scholarship Stipend',
        amount: 3000.0,
        type: TransactionType.income,
        date: DateTime(now.year, now.month, 10, 11, 00),
        categoryId: 'scholarship',
        categoryName: 'Scholarship / Grant',
        paymentMethod: PaymentMethod.bankTransfer,
        notes: 'Merit scholarship semester 5',
      ),

      // Expenses - varied dates and categories
      TransactionItem(
        id: _uuid.v4(),
        title: 'Hostel Monthly Rent',
        amount: 3500.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 2, 10, 00),
        categoryId: 'hostel_mess',
        categoryName: 'Hostel & Mess',
        paymentMethod: PaymentMethod.upi,
        notes: 'October hostel room + mess',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Groceries - Weekly',
        amount: 890.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 5, 16, 45),
        categoryId: 'groceries',
        categoryName: 'Groceries',
        paymentMethod: PaymentMethod.upi,
        notes: 'Vegetables, fruits, dairy',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Algorithm Textbook',
        amount: 750.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 3, 15, 20),
        categoryId: 'books',
        categoryName: 'Books & Stationery',
        paymentMethod: PaymentMethod.debitCard,
        notes: 'CLRS 4th edition',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Canteen Lunch',
        amount: 85.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, now.day > 1 ? now.day - 1 : 1, 13, 30),
        categoryId: 'canteen',
        categoryName: 'Campus Canteen & Hangouts',
        paymentMethod: PaymentMethod.upi,
        notes: 'Thali + water bottle',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Metro Monthly Pass',
        amount: 550.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 1, 9, 00),
        categoryId: 'transport',
        categoryName: 'Transport',
        paymentMethod: PaymentMethod.upi,
        notes: 'Student monthly pass',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Spotify Premium',
        amount: 59.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 4, 8, 00),
        categoryId: 'subscriptions',
        categoryName: 'Subscriptions',
        paymentMethod: PaymentMethod.creditCard,
        notes: 'Student plan monthly',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Netflix Sharing',
        amount: 199.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 8, 10, 15),
        categoryId: 'subscriptions',
        categoryName: 'Subscriptions',
        paymentMethod: PaymentMethod.upi,
        notes: 'Split with 3 friends',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Movie Night',
        amount: 450.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, now.day > 3 ? now.day - 3 : 1, 19, 00),
        categoryId: 'entertainment',
        categoryName: 'Entertainment',
        paymentMethod: PaymentMethod.upi,
        notes: 'IMAX with friends',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Medical Checkup',
        amount: 320.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 6, 11, 30),
        categoryId: 'healthcare',
        categoryName: 'Healthcare',
        paymentMethod: PaymentMethod.upi,
        notes: 'General physician consultation',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Online Course - React',
        amount: 1200.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 9, 15, 45),
        categoryId: 'education',
        categoryName: 'Education',
        paymentMethod: PaymentMethod.creditCard,
        notes: 'Udemy advanced React course',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'New T-Shirt',
        amount: 450.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, now.day > 5 ? now.day - 5 : 1, 17, 20),
        categoryId: 'shopping',
        categoryName: 'Shopping',
        paymentMethod: PaymentMethod.upi,
        notes: 'Myntra sale',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Electricity Bill',
        amount: 420.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 2, 14, 00),
        categoryId: 'utilities',
        categoryName: 'Bills & Utilities',
        paymentMethod: PaymentMethod.upi,
        notes: 'September electricity',
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Dinner with Roommates',
        amount: 680.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, now.day > 2 ? now.day - 2 : 1, 21, 00),
        categoryId: 'food',
        categoryName: 'Food & Dining',
        paymentMethod: PaymentMethod.upi,
        notes: 'Split 4 ways',
      ),

      // Previous month for comparison
      TransactionItem(
        id: _uuid.v4(),
        title: 'September Allowance',
        amount: 8000.0,
        type: TransactionType.income,
        date: DateTime(now.year, now.month - 1, 1),
        categoryId: 'pocket_money',
        categoryName: 'Pocket Money / Allowance',
        paymentMethod: PaymentMethod.upi,
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Freelance Logo Design',
        amount: 2500.0,
        type: TransactionType.income,
        date: DateTime(now.year, now.month - 1, 15),
        categoryId: 'freelance',
        categoryName: 'Freelance & Side Hustle',
        paymentMethod: PaymentMethod.upi,
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'September Total Expenses',
        amount: 6800.0,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month - 1, 28),
        categoryId: 'food',
        categoryName: 'Food & Dining',
        paymentMethod: PaymentMethod.upi,
      ),
    ];

    // Budgets - realistic amounts
    final monthKey = DateFormat('yyyy-MM').format(now);
    _budgets = [
      BudgetItem(
        id: _uuid.v4(),
        categoryId: 'overall',
        categoryName: 'Overall Monthly Budget',
        limitAmount: 12000.0,
        monthKey: monthKey,
        warningThreshold: 0.8,
      ),
      BudgetItem(
        id: _uuid.v4(),
        categoryId: 'food',
        categoryName: 'Food & Dining',
        limitAmount: 3000.0,
        monthKey: monthKey,
        warningThreshold: 0.75,
      ),
      BudgetItem(
        id: _uuid.v4(),
        categoryId: 'canteen',
        categoryName: 'Campus Canteen',
        limitAmount: 1500.0,
        monthKey: monthKey,
        warningThreshold: 0.8,
      ),
      BudgetItem(
        id: _uuid.v4(),
        categoryId: 'transport',
        categoryName: 'Transport',
        limitAmount: 800.0,
        monthKey: monthKey,
        warningThreshold: 0.8,
      ),
      BudgetItem(
        id: _uuid.v4(),
        categoryId: 'groceries',
        categoryName: 'Groceries',
        limitAmount: 2000.0,
        monthKey: monthKey,
        warningThreshold: 0.8,
      ),
    ];

    // Reminders - realistic bills
    _reminders = [
      ReminderItem(
        id: _uuid.v4(),
        title: 'Jio 5G Data Recharge',
        amount: 299.0,
        dueDate: now.add(const Duration(days: 5)),
        recurrence: ReminderRecurrence.monthly,
        categoryId: 'utilities',
        notes: '84 days prepaid plan renewal',
        status: ReminderStatus.pending,
      ),
      ReminderItem(
        id: _uuid.v4(),
        title: 'Netflix Subscription',
        amount: 199.0,
        dueDate: now.add(const Duration(days: 12)),
        recurrence: ReminderRecurrence.monthly,
        categoryId: 'subscriptions',
        notes: 'Standard plan with friends',
        status: ReminderStatus.pending,
      ),
      ReminderItem(
        id: _uuid.v4(),
        title: 'Electricity Bill',
        amount: 450.0,
        dueDate: now.add(const Duration(days: 20)),
        recurrence: ReminderRecurrence.monthly,
        categoryId: 'utilities',
        notes: 'Monthly electricity charges',
        status: ReminderStatus.pending,
      ),
      ReminderItem(
        id: _uuid.v4(),
        title: 'Hostel Room Rent',
        amount: 3500.0,
        dueDate: now.add(const Duration(days: 25)),
        recurrence: ReminderRecurrence.monthly,
        categoryId: 'rent',
        notes: 'Monthly hostel charges',
        status: ReminderStatus.pending,
      ),
    ];

    // Financial Records - realistic FDs and insurance
    _financialRecords = [
      FinancialRecordItem(
        id: _uuid.v4(),
        title: 'Emergency Fund FD',
        type: FinancialRecordType.fixedDeposit,
        institution: 'HDFC Bank',
        principalOrPremium: 50000.0,
        interestRate: 7.25,
        maturityAmount: 53625.0,
        startDate: DateTime(now.year - 1, 5, 15),
        maturityOrRenewalDate: DateTime(now.year + 1, 5, 15),
        policyOrAccountNumber: 'HDFC-FD-782341',
        notes: '2-year FD for emergency fund. Auto-renewal enabled.',
      ),
      FinancialRecordItem(
        id: _uuid.v4(),
        title: 'Student Health Insurance',
        type: FinancialRecordType.insurancePolicy,
        institution: 'ICICI Lombard',
        principalOrPremium: 4500.0,
        startDate: DateTime(now.year, 3, 1),
        maturityOrRenewalDate: DateTime(now.year + 1, 3, 1),
        policyOrAccountNumber: 'ICICI-POL-99238',
        notes: 'Annual health insurance with 5L coverage. Cashless hospitalization.',
      ),
      FinancialRecordItem(
        id: _uuid.v4(),
        title: 'RD for Trip Fund',
        type: FinancialRecordType.recurringDeposit,
        institution: 'Axis Bank',
        principalOrPremium: 2000.0,
        interestRate: 6.8,
        maturityAmount: 24800.0,
        startDate: DateTime(now.year, 1, 1),
        maturityOrRenewalDate: DateTime(now.year + 1, 1, 1),
        policyOrAccountNumber: 'AXIS-RD-44521',
        notes: 'Monthly RD of ₹2000 for Goa trip',
      ),
    ];

    // Savings Goals - realistic targets
    _savingsGoals = [
      SavingsGoalItem(
        id: _uuid.v4(),
        title: 'MacBook Pro M3',
        targetAmount: 145000.0,
        currentSaved: 65000.0,
        targetDate: now.add(const Duration(days: 180)),
        category: 'Gadgets',
        notes: 'For coding and freelance work. Already saved 45%.',
      ),
      SavingsGoalItem(
        id: _uuid.v4(),
        title: 'Summer Vacation Trip',
        targetAmount: 25000.0,
        currentSaved: 12000.0,
        targetDate: now.add(const Duration(days: 90)),
        category: 'Travel',
        notes: 'Goa trip with college friends after exams.',
      ),
      SavingsGoalItem(
        id: _uuid.v4(),
        title: 'Emergency Fund',
        targetAmount: 100000.0,
        currentSaved: 75000.0,
        targetDate: now.add(const Duration(days: 365)),
        category: 'Savings',
        notes: '6 months expenses as emergency fund',
      ),
    ];
  }
}
