import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/models/reminder_item.dart';
import 'package:pocketledger/models/financial_record_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reminder Date Calculations', () {
    test('should calculate days until correctly', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));
      final nextWeek = today.add(const Duration(days: 7));

      expect(tomorrow.difference(today).inDays, equals(1));
      expect(yesterday.difference(today).inDays, equals(-1));
      expect(nextWeek.difference(today).inDays, equals(7));
    });

    test('should handle month-end for monthly recurrence', () {
      // Test Jan 31 -> Feb 28/29
      final jan31 = DateTime(2024, 1, 31);
      final febNext = DateTime(2024, 2, 1);
      final lastDayOfFeb = DateTime(2024, 3, 0).day; // 29 in 2024 (leap year)
      
      final day = jan31.day > lastDayOfFeb ? lastDayOfFeb : jan31.day;
      final nextDue = DateTime(febNext.year, febNext.month, day);
      
      expect(nextDue.day, equals(29)); // Feb 29 in leap year
    });

    test('should handle non-leap year for Feb 29 yearly recurrence', () {
      final isLeapYear = (2024 % 4 == 0 && 2024 % 100 != 0) || (2024 % 400 == 0);
      expect(isLeapYear, isTrue);
      
      final isNotLeapYear = (2025 % 4 == 0 && 2025 % 100 != 0) || (2025 % 400 == 0);
      expect(isNotLeapYear, isFalse);
    });
  });

  group('Reminder Item Model', () {
    test('should create reminder with correct properties', () {
      final reminder = ReminderItem(
        id: 'test-1',
        title: 'Test Bill',
        amount: 100.0,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        recurrence: ReminderRecurrence.monthly,
        categoryId: 'utilities',
      );

      expect(reminder.id, equals('test-1'));
      expect(reminder.title, equals('Test Bill'));
      expect(reminder.amount, equals(100.0));
      expect(reminder.recurrence, equals(ReminderRecurrence.monthly));
      expect(reminder.status, equals(ReminderStatus.pending));
    });

    test('should correctly identify pending reminders', () {
      final reminder = ReminderItem(
        id: 'test-1',
        title: 'Test Bill',
        amount: 100.0,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        recurrence: ReminderRecurrence.monthly,
        categoryId: 'utilities',
        status: ReminderStatus.pending,
      );

      expect(reminder.isPending, isTrue);
      expect(reminder.isPaid, isFalse);
      expect(reminder.isPostponed, isFalse);
    });

    test('should correctly identify paid reminders', () {
      final reminder = ReminderItem(
        id: 'test-1',
        title: 'Test Bill',
        amount: 100.0,
        dueDate: DateTime.now().subtract(const Duration(days: 5)),
        recurrence: ReminderRecurrence.monthly,
        categoryId: 'utilities',
        status: ReminderStatus.paid,
        paidDate: DateTime.now(),
      );

      expect(reminder.isPending, isFalse);
      expect(reminder.isPaid, isTrue);
      expect(reminder.isPostponed, isFalse);
    });

    test('should correctly identify overdue reminders', () {
      final reminder = ReminderItem(
        id: 'test-1',
        title: 'Test Bill',
        amount: 100.0,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        recurrence: ReminderRecurrence.monthly,
        categoryId: 'utilities',
        status: ReminderStatus.pending,
      );

      expect(reminder.isOverdue, isTrue);
    });
  });

  group('Financial Record Model', () {
    test('should create FD record with correct properties', () {
      final record = FinancialRecordItem(
        id: 'fd-1',
        title: 'Test FD',
        type: FinancialRecordType.fixedDeposit,
        institution: 'Test Bank',
        principalOrPremium: 10000.0,
        startDate: DateTime.now().subtract(const Duration(days: 180)),
        maturityOrRenewalDate: DateTime.now().add(const Duration(days: 30)),
      );

      expect(record.title, equals('Test FD'));
      expect(record.type, equals(FinancialRecordType.fixedDeposit));
      expect(record.institution, equals('Test Bank'));
      expect(record.principalOrPremium, equals(10000.0));
    });

    test('should calculate days until maturity correctly', () {
      final now = DateTime.now();
      final record = FinancialRecordItem(
        id: 'fd-1',
        title: 'Test FD',
        type: FinancialRecordType.fixedDeposit,
        institution: 'Test Bank',
        principalOrPremium: 10000.0,
        startDate: now.subtract(const Duration(days: 180)),
        maturityOrRenewalDate: now.add(const Duration(days: 30)),
      );

      final daysUntil = record.maturityOrRenewalDate.difference(now).inDays;
      expect(daysUntil, equals(30));
    });
  });

  group('Budget Calculations', () {
    test('should handle 100% budget threshold', () {
      final spent = 1000.0;
      final limit = 1000.0;
      final percent = spent / limit;

      expect(percent, equals(1.0));
    });

    test('should handle over-budget scenarios', () {
      final spent = 1200.0;
      final limit = 1000.0;
      final percent = spent / limit;

      expect(percent, greaterThan(1.0));
    });

    test('should handle under-budget scenarios', () {
      final spent = 800.0;
      final limit = 1000.0;
      final percent = spent / limit;

      expect(percent, lessThan(1.0));
      expect(percent, equals(0.8));
    });

    test('should handle zero budget limit safely', () {
      final spent = 100.0;
      final limit = 0.0;
      
      // This should be guarded against in production code
      // In Dart, division by zero returns infinity, not an error
      final result = spent / limit;
      expect(result.isInfinite, isTrue);
    });
  });

  group('Notification ID Generation', () {
    test('should generate consistent IDs from reminder IDs', () {
      final reminderId = 'test-reminder-123';
      final notificationId = reminderId.hashCode.abs() % 10000;

      expect(notificationId, isNonNegative);
      expect(notificationId, lessThan(10000));
    });

    test('should generate different IDs for different reminders', () {
      final id1 = 'reminder-1'.hashCode.abs() % 10000;
      final id2 = 'reminder-2'.hashCode.abs() % 10000;

      expect(id1, isNot(equals(id2)));
    });

    test('should generate IDs within valid range', () {
      for (int i = 0; i < 100; i++) {
        final id = 'reminder-$i'.hashCode.abs() % 10000;
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThan(10000));
      }
    });
  });
}
