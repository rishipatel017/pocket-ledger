import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../models/budget_item.dart';
import '../models/reminder_item.dart';
import '../models/financial_record_item.dart';
import '../models/savings_goal_item.dart';
import '../models/app_settings.dart';

class StorageService {
  static const String _keyTransactions = 'pl_transactions';
  static const String _keyCategories = 'pl_categories';
  static const String _keyBudgets = 'pl_budgets';
  static const String _keyReminders = 'pl_reminders';
  static const String _keyFinancialRecords = 'pl_financial_records';
  static const String _keySavingsGoals = 'pl_savings_goals';
  static const String _keySettings = 'pl_settings';
  static const String _keyInitialized = 'pl_is_seeded';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool get isFirstRun => !(_prefs.getBool(_keyInitialized) ?? false);

  Future<void> markSeeded() async {
    await _prefs.setBool(_keyInitialized, true);
  }

  // Settings
  AppSettings loadSettings() {
    final raw = _prefs.getString(_keySettings);
    if (raw == null) return AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  // Transactions
  List<TransactionItem> loadTransactions() {
    final raw = _prefs.getString(_keyTransactions);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<TransactionItem> items) async {
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyTransactions, raw);
  }

  // Categories
  List<CategoryItem> loadCategories() {
    final raw = _prefs.getString(_keyCategories);
    if (raw == null) return CategoryItem.defaultCategories;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return CategoryItem.defaultCategories;
    }
  }

  Future<void> saveCategories(List<CategoryItem> categories) async {
    final raw = jsonEncode(categories.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyCategories, raw);
  }

  // Budgets
  List<BudgetItem> loadBudgets() {
    final raw = _prefs.getString(_keyBudgets);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => BudgetItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBudgets(List<BudgetItem> items) async {
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyBudgets, raw);
  }

  // Reminders
  List<ReminderItem> loadReminders() {
    final raw = _prefs.getString(_keyReminders);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReminders(List<ReminderItem> items) async {
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyReminders, raw);
  }

  // Financial Records (FD, RD, Insurance)
  List<FinancialRecordItem> loadFinancialRecords() {
    final raw = _prefs.getString(_keyFinancialRecords);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => FinancialRecordItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFinancialRecords(List<FinancialRecordItem> items) async {
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyFinancialRecords, raw);
  }

  // Savings Goals
  List<SavingsGoalItem> loadSavingsGoals() {
    final raw = _prefs.getString(_keySavingsGoals);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SavingsGoalItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSavingsGoals(List<SavingsGoalItem> items) async {
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_keySavingsGoals, raw);
  }

  // CSV Export
  String generateTransactionsCsv(
    List<TransactionItem> transactions,
    String currencySymbol,
  ) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(
      'ID,Date,Time,Type,Category,Amount ($currencySymbol),Payment Method,Title,Notes,Transfer To Account',
    );

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm:ss');

    for (final tx in transactions) {
      final id = '"${tx.id}"';
      final date = dateFormat.format(tx.date);
      final time = timeFormat.format(tx.date);
      final type = tx.type.name.toUpperCase();
      final cat = '"${tx.categoryName.replaceAll('"', '""')}"';
      final amount = tx.amount.toStringAsFixed(2);
      final payment = tx.paymentMethod.displayName;
      final title = '"${tx.title.replaceAll('"', '""')}"';
      final notes = '"${(tx.notes ?? '').replaceAll('"', '""')}"';
      final transferTo =
          '"${(tx.transferToAccount ?? '').replaceAll('"', '""')}"';

      buffer.writeln(
        '$id,$date,$time,$type,$cat,$amount,$payment,$title,$notes,$transferTo',
      );
    }

    return buffer.toString();
  }

  // Full JSON Backup
  String generateFullBackupJson({
    required AppSettings settings,
    required List<TransactionItem> transactions,
    required List<CategoryItem> categories,
    required List<BudgetItem> budgets,
    required List<ReminderItem> reminders,
    required List<FinancialRecordItem> financialRecords,
    required List<SavingsGoalItem> savingsGoals,
  }) {
    final map = {
      'app': 'PocketLedger',
      'version': '1.0.0',
      'backupDate': DateTime.now().toIso8601String(),
      'settings': settings.toJson(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'budgets': budgets.map((e) => e.toJson()).toList(),
      'reminders': reminders.map((e) => e.toJson()).toList(),
      'financialRecords': financialRecords.map((e) => e.toJson()).toList(),
      'savingsGoals': savingsGoals.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<bool> restoreFromBackupJson(String jsonStr) async {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (map['app'] != 'PocketLedger') {
        return false;
      }

      if (map['settings'] != null) {
        await saveSettings(
          AppSettings.fromJson(map['settings'] as Map<String, dynamic>),
        );
      }
      if (map['transactions'] != null) {
        final list = (map['transactions'] as List<dynamic>)
            .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveTransactions(list);
      }
      if (map['categories'] != null) {
        final list = (map['categories'] as List<dynamic>)
            .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveCategories(list);
      }
      if (map['budgets'] != null) {
        final list = (map['budgets'] as List<dynamic>)
            .map((e) => BudgetItem.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveBudgets(list);
      }
      if (map['reminders'] != null) {
        final list = (map['reminders'] as List<dynamic>)
            .map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveReminders(list);
      }
      if (map['financialRecords'] != null) {
        final list = (map['financialRecords'] as List<dynamic>)
            .map((e) => FinancialRecordItem.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveFinancialRecords(list);
      }
      if (map['savingsGoals'] != null) {
        final list = (map['savingsGoals'] as List<dynamic>)
            .map((e) => SavingsGoalItem.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveSavingsGoals(list);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearAllData() async {
  // Remove only app data keys (not everything)
  await _prefs.remove(_keyTransactions);
  await _prefs.remove(_keyCategories);
  await _prefs.remove(_keyBudgets);
  await _prefs.remove(_keyReminders);
  await _prefs.remove(_keyFinancialRecords);
  await _prefs.remove(_keySavingsGoals);
  await _prefs.remove(_keySettings);

  // Keep the seeded flag so demo data never comes back
  await _prefs.setBool(_keyInitialized, true);
  }
}
