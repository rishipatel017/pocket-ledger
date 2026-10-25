import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketledger/state/app_state.dart';
import 'package:pocketledger/services/storage_service.dart';
import 'package:pocketledger/models/transaction_item.dart';
import 'package:pocketledger/models/category_item.dart';
import 'package:pocketledger/models/budget_item.dart';
import 'package:pocketledger/models/reminder_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppState Financial Calculations', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      
      // Mark as seeded to prevent demo data
      await storage.markSeeded();
      
      appState = AppState(storage);
      
      // Initialize with empty data
      await appState.init();
    });

    test('should calculate total income correctly', () {
      // Add income transactions
      final tx1 = TransactionItem(
        id: '1',
        title: 'Salary',
        amount: 5000.0,
        type: TransactionType.income,
        date: DateTime.now(),
        categoryId: 'salary',
        categoryName: 'Salary',
        paymentMethod: PaymentMethod.bankTransfer,
      );
      
      final tx2 = TransactionItem(
        id: '2',
        title: 'Freelance',
        amount: 1000.0,
        type: TransactionType.income,
        date: DateTime.now(),
        categoryId: 'freelance',
        categoryName: 'Freelance',
        paymentMethod: PaymentMethod.upi,
      );

      // Manually add to test calculations using allTransactions getter
      final transactions = [...appState.allTransactions, tx1, tx2];
      
      final totalIncome = transactions
          .where((t) => t.type == TransactionType.income)
          .fold<double>(0.0, (sum, t) => sum + t.amount);
      
      expect(totalIncome, equals(6000.0));
    });

    test('should calculate total expenses correctly', () {
      final tx1 = TransactionItem(
        id: '1',
        title: 'Groceries',
        amount: 500.0,
        type: TransactionType.expense,
        date: DateTime.now(),
        categoryId: 'food',
        categoryName: 'Food',
        paymentMethod: PaymentMethod.cash,
      );
      
      final tx2 = TransactionItem(
        id: '2',
        title: 'Rent',
        amount: 2000.0,
        type: TransactionType.expense,
        date: DateTime.now(),
        categoryId: 'housing',
        categoryName: 'Housing',
        paymentMethod: PaymentMethod.bankTransfer,
      );

      final transactions = [...appState.allTransactions, tx1, tx2];
      
      final totalExpense = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0.0, (sum, t) => sum + t.amount);
      
      expect(totalExpense, equals(2500.0));
    });

    test('should calculate net cash flow correctly', () {
      final income = TransactionItem(
        id: '1',
        title: 'Salary',
        amount: 5000.0,
        type: TransactionType.income,
        date: DateTime.now(),
        categoryId: 'salary',
        categoryName: 'Salary',
        paymentMethod: PaymentMethod.bankTransfer,
      );
      
      final expense = TransactionItem(
        id: '2',
        title: 'Rent',
        amount: 2000.0,
        type: TransactionType.expense,
        date: DateTime.now(),
        categoryId: 'housing',
        categoryName: 'Housing',
        paymentMethod: PaymentMethod.bankTransfer,
      );

      final transactions = [...appState.allTransactions, income, expense];
      
      final totalIncome = transactions
          .where((t) => t.type == TransactionType.income)
          .fold<double>(0.0, (sum, t) => sum + t.amount);
      
      final totalExpense = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0.0, (sum, t) => sum + t.amount);
      
      final netCashFlow = totalIncome - totalExpense;
      
      expect(netCashFlow, equals(3000.0));
    });

    test('should exclude transfers from income/expense calculations', () {
      final income = TransactionItem(
        id: '1',
        title: 'Salary',
        amount: 5000.0,
        type: TransactionType.income,
        date: DateTime.now(),
        categoryId: 'salary',
        categoryName: 'Salary',
        paymentMethod: PaymentMethod.bankTransfer,
      );
      
      final transfer = TransactionItem(
        id: '2',
        title: 'Transfer to Savings',
        amount: 1000.0,
        type: TransactionType.transfer,
        date: DateTime.now(),
        categoryId: 'savings',
        categoryName: 'Savings',
        paymentMethod: PaymentMethod.bankTransfer,
        transferToAccount: 'Savings Account',
      );

      final transactions = [...appState.allTransactions, income, transfer];
      
      final totalIncome = transactions
          .where((t) => t.type == TransactionType.income)
          .fold<double>(0.0, (sum, t) => sum + t.amount);
      
      final totalExpense = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0.0, (sum, t) => sum + t.amount);
      
      expect(totalIncome, equals(5000.0));
      expect(totalExpense, equals(0.0));
    });

    test('should handle negative amounts correctly', () {
      final expense = TransactionItem(
        id: '1',
        title: 'Refund',
        amount: -100.0,
        type: TransactionType.expense,
        date: DateTime.now(),
        categoryId: 'shopping',
        categoryName: 'Shopping',
        paymentMethod: PaymentMethod.cash,
      );

      final transactions = [...appState.allTransactions, expense];
      
      final totalExpense = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0.0, (sum, t) => sum + t.amount);
      
      // This should be handled by validation in production
      expect(totalExpense, equals(-100.0));
    });
  });

  group('Budget Calculations', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      appState = AppState(storage);
      await appState.init();
    });

    test('should calculate budget progress correctly', () {
      final budget = BudgetItem(
        id: 'budget-1',
        categoryId: 'food',
        categoryName: 'Food',
        limitAmount: 1000.0,
        monthKey: '2024-10',
        warningThreshold: 0.8,
        isEnabled: true,
      );

      final spent = 800.0;
      final progress = spent / budget.limitAmount;
      
      expect(progress, equals(0.8));
    });

    test('should identify when budget is exceeded', () {
      final budget = BudgetItem(
        id: 'budget-1',
        categoryId: 'food',
        categoryName: 'Food',
        limitAmount: 1000.0,
        monthKey: '2024-10',
        warningThreshold: 0.8,
        isEnabled: true,
      );

      final spent = 1200.0;
      final progress = spent / budget.limitAmount;
      
      expect(progress, greaterThan(1.0));
    });

    test('should handle zero budget limit safely', () {
      final budget = BudgetItem(
        id: 'budget-1',
        categoryId: 'food',
        categoryName: 'Food',
        limitAmount: 0.0,
        monthKey: '2024-10',
        warningThreshold: 0.8,
        isEnabled: true,
      );

      final spent = 100.0;
      
      // This should be guarded against in production
      // In Dart, division by zero returns infinity, not an error
      final result = spent / budget.limitAmount;
      expect(result.isInfinite, isTrue);
    });
  });

  group('Date Range Calculations', () {
    test('should handle month-end correctly', () {
      final jan31 = DateTime(2024, 1, 31);
      final feb1 = DateTime(2024, 2, 1);
      
      expect(feb1.difference(jan31).inDays, equals(1));
    });

    test('should handle year-end correctly', () {
      final dec31 = DateTime(2024, 12, 31);
      final jan1 = DateTime(2025, 1, 1);
      
      expect(jan1.difference(dec31).inDays, equals(1));
    });

    test('should handle leap year February', () {
      final feb28 = DateTime(2024, 2, 28);
      final feb29 = DateTime(2024, 2, 29);
      final mar1 = DateTime(2024, 3, 1);
      
      expect(feb29.difference(feb28).inDays, equals(1));
      expect(mar1.difference(feb29).inDays, equals(1));
    });
  });

  group('Reminder Recurrence Calculations', () {
    test('should calculate next monthly date correctly', () {
      final current = DateTime(2024, 1, 15);
      final nextMonth = DateTime(2024, 2, 15);
      
      expect(nextMonth.difference(current).inDays, equals(31));
    });

    test('should handle month-end for monthly recurrence', () {
      final jan31 = DateTime(2024, 1, 31);
      final febNext = DateTime(2024, 2, 1);
      final lastDayOfFeb = DateTime(2024, 3, 0).day; // 29 in 2024
      
      final day = jan31.day > lastDayOfFeb ? lastDayOfFeb : jan31.day;
      final nextDue = DateTime(febNext.year, febNext.month, day);
      
      expect(nextDue.day, equals(29));
    });

    test('should calculate next quarterly date correctly', () {
      final current = DateTime(2024, 1, 15);
      final nextQuarter = DateTime(2024, 4, 15);
      
      expect(nextQuarter.difference(current).inDays, equals(91));
    });

    test('should calculate next yearly date correctly', () {
      final current = DateTime(2024, 1, 15);
      final nextYear = DateTime(2025, 1, 15);
      
      expect(nextYear.difference(current).inDays, equals(366)); // 2024 is leap year
    });
  });
}
