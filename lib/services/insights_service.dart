import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_item.dart';
import '../models/budget_item.dart';
import '../models/app_settings.dart';

class SpendingInsight {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String type; // 'warning', 'tip', 'success', 'info'

  SpendingInsight({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class CategorySpend {
  final String categoryId;
  final String categoryName;
  final double amount;
  final double percentage;
  final int count;

  CategorySpend({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.count,
  });
}

class DailySpend {
  final DateTime date;
  final String label; // "Mon", "Tue" etc or "12 Oct"
  final double expense;
  final double income;

  DailySpend({
    required this.date,
    required this.label,
    required this.expense,
    required this.income,
  });
}

class MonthComparison {
  final double currentMonthExpense;
  final double currentMonthIncome;
  final double previousMonthExpense;
  final double previousMonthIncome;
  final double expenseChangePercent;
  final double incomeChangePercent;

  MonthComparison({
    required this.currentMonthExpense,
    required this.currentMonthIncome,
    required this.previousMonthExpense,
    required this.previousMonthIncome,
    required this.expenseChangePercent,
    required this.incomeChangePercent,
  });
}

class InsightsService {
  static List<SpendingInsight> generateInsights({
    required List<TransactionItem> transactions,
    required List<BudgetItem> budgets,
    required AppSettings settings,
    required DateTime targetDate,
  }) {
    final insights = <SpendingInsight>[];
    final currency = settings.currencySymbol;

    // Filter transactions for target month
    final currentMonthTxs = transactions.where((tx) =>
        tx.date.year == targetDate.year && tx.date.month == targetDate.month);

    final currentExpenses = currentMonthTxs
        .where((tx) => tx.type == TransactionType.expense)
        .toList();
    final currentIncome = currentMonthTxs
        .where((tx) => tx.type == TransactionType.income)
        .toList();

    final totalCurrentExpense =
        currentExpenses.fold<double>(0.0, (sum, tx) => sum + tx.amount);
    final totalCurrentIncome =
        currentIncome.fold<double>(0.0, (sum, tx) => sum + tx.amount);

    // 1. Previous Month comparison
    final prevMonthDate =
        DateTime(targetDate.year, targetDate.month - 1, 1);
    final prevMonthTxs = transactions.where((tx) =>
        tx.date.year == prevMonthDate.year &&
        tx.date.month == prevMonthDate.month &&
        tx.type == TransactionType.expense);
    final totalPrevExpense =
        prevMonthTxs.fold<double>(0.0, (sum, tx) => sum + tx.amount);

    if (totalPrevExpense > 0 && totalCurrentExpense > 0) {
      final changePct =
          ((totalCurrentExpense - totalPrevExpense) / totalPrevExpense) * 100;
      if (changePct > 10) {
        insights.add(SpendingInsight(
          title: 'Spending Acceleration',
          message:
              'Your total spending is ${changePct.toStringAsFixed(1)}% higher than last month ($currency${totalPrevExpense.toStringAsFixed(0)} → $currency${totalCurrentExpense.toStringAsFixed(0)}).',
          icon: Icons.trending_up,
          color: Colors.orangeAccent,
          type: 'warning',
        ));
      } else if (changePct < -10) {
        insights.add(SpendingInsight(
          title: 'Smart Frugality',
          message:
              'You have reduced your spending by ${(-changePct).toStringAsFixed(1)}% compared to last month! Keep it up.',
          icon: Icons.trending_down,
          color: Colors.greenAccent,
          type: 'success',
        ));
      }
    }

    // 2. Student Runway & Allowance Insight
    if (settings.isStudentMode) {
      final allowance = settings.studentMonthlyAllowance;
      final remainingAllowance = allowance - totalCurrentExpense;
      final daysInMonth =
          DateTime(targetDate.year, targetDate.month + 1, 0).day;
      final daysPassed = targetDate.day;
      final daysLeft = (daysInMonth - daysPassed).clamp(1, 31);
      final dailyBurnRate =
          daysPassed > 0 ? (totalCurrentExpense / daysPassed) : 0.0;

      if (remainingAllowance > 0 && dailyBurnRate > 0) {
        final daysRunway = remainingAllowance / dailyBurnRate;
        insights.add(SpendingInsight(
          title: 'Student Budget Runway',
          message:
              'At your current pace of $currency${dailyBurnRate.toStringAsFixed(0)}/day, your remaining $currency${remainingAllowance.toStringAsFixed(0)} will last ~${daysRunway.toStringAsFixed(1)} days ($daysLeft days remain this month).',
          icon: Icons.account_balance,
          color: daysRunway >= daysLeft ? Colors.lightBlueAccent : Colors.amber,
          type: daysRunway >= daysLeft ? 'info' : 'warning',
        ));
      } else if (remainingAllowance <= 0 && allowance > 0) {
        insights.add(SpendingInsight(
          title: 'Allowance Exhausted',
          message:
              'You have exceeded your student allowance ($currency${allowance.toStringAsFixed(0)}) by $currency${(-remainingAllowance).toStringAsFixed(0)}.',
          icon: Icons.warning_amber_rounded,
          color: Colors.redAccent,
          type: 'warning',
        ));
      }
    }

    // 3. Top Category Dominance
    if (totalCurrentExpense > 0) {
      final categorySums = <String, double>{};
      final categoryNames = <String, String>{};
      for (final tx in currentExpenses) {
        categorySums[tx.categoryId] =
            (categorySums[tx.categoryId] ?? 0) + tx.amount;
        categoryNames[tx.categoryId] = tx.categoryName;
      }

      String? topCatId;
      double topCatAmount = 0;
      categorySums.forEach((catId, amount) {
        if (amount > topCatAmount) {
          topCatAmount = amount;
          topCatId = catId;
        }
      });

      if (topCatId != null) {
        final share = (topCatAmount / totalCurrentExpense) * 100;
        if (share >= 25) {
          final catName = categoryNames[topCatId] ?? 'Category';
          insights.add(SpendingInsight(
            title: '$catName Dominance',
            message:
                '$catName accounts for ${share.toStringAsFixed(0)}% ($currency${topCatAmount.toStringAsFixed(0)}) of your spending this month.',
            icon: Icons.pie_chart_outline,
            color: Colors.tealAccent,
            type: 'info',
          ));
        }
      }
    }

    // 4. Budget Threshold Warning
    final currentMonthKey = DateFormat('yyyy-MM').format(targetDate);
    for (final budget in budgets.where(
        (b) => b.isEnabled && b.monthKey == currentMonthKey)) {
      double spent = 0;
      if (budget.isOverall) {
        spent = totalCurrentExpense;
      } else {
        spent = currentExpenses
            .where((tx) => tx.categoryId == budget.categoryId)
            .fold<double>(0.0, (s, tx) => s + tx.amount);
      }

      if (budget.limitAmount > 0) {
        final ratio = spent / budget.limitAmount;
        if (ratio >= 1.0) {
          insights.add(SpendingInsight(
            title: 'Budget Breached: ${budget.categoryName}',
            message:
                'You spent $currency${spent.toStringAsFixed(0)}, exceeding your budget of $currency${budget.limitAmount.toStringAsFixed(0)} by $currency${(spent - budget.limitAmount).toStringAsFixed(0)}!',
            icon: Icons.error_outline,
            color: Colors.redAccent,
            type: 'warning',
          ));
        } else if (ratio >= budget.warningThreshold) {
          insights.add(SpendingInsight(
            title: 'Budget Alert: ${budget.categoryName}',
            message:
                'You have utilized ${(ratio * 100).toStringAsFixed(0)}% of your $currency${budget.limitAmount.toStringAsFixed(0)} budget. Only $currency${(budget.limitAmount - spent).toStringAsFixed(0)} remaining.',
            icon: Icons.notifications_active,
            color: Colors.orangeAccent,
            type: 'warning',
          ));
        }
      }
    }

    // 5. Savings Rate
    if (totalCurrentIncome > 0) {
      final savings = totalCurrentIncome - totalCurrentExpense;
      final savingsRate = (savings / totalCurrentIncome) * 100;
      if (savingsRate > 20) {
        insights.add(SpendingInsight(
          title: 'Strong Savings Habit',
          message:
              'You have retained ${savingsRate.toStringAsFixed(0)}% ($currency${savings.toStringAsFixed(0)}) of your income as net savings this month.',
          icon: Icons.savings_outlined,
          color: Colors.greenAccent,
          type: 'success',
        ));
      }
    }

    // Fallback info if few transactions
    if (insights.isEmpty) {
      insights.add(SpendingInsight(
        title: 'Building Financial Awareness',
        message:
            'Keep recording your daily expenses and income to reveal spending habits, runway forecasts, and category patterns.',
        icon: Icons.auto_awesome,
        color: Colors.lightBlueAccent,
        type: 'info',
      ));
    }

    return insights;
  }

  static List<CategorySpend> calculateCategorySpans({
    required List<TransactionItem> transactions,
    required DateTime targetDate,
  }) {
    final expenses = transactions.where((tx) =>
        tx.type == TransactionType.expense &&
        tx.date.year == targetDate.year &&
        tx.date.month == targetDate.month);

    final total = expenses.fold<double>(0.0, (s, tx) => s + tx.amount);
    if (total == 0) return [];

    final map = <String, List<TransactionItem>>{};
    for (final tx in expenses) {
      map.putIfAbsent(tx.categoryId, () => []).add(tx);
    }

    final result = <CategorySpend>[];
    map.forEach((catId, items) {
      final sum = items.fold<double>(0.0, (s, tx) => s + tx.amount);
      result.add(CategorySpend(
        categoryId: catId,
        categoryName: items.first.categoryName,
        amount: sum,
        percentage: (sum / total) * 100,
        count: items.length,
      ));
    });

    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  static List<DailySpend> calculateDailyTrend({
    required List<TransactionItem> transactions,
    required DateTime targetDate,
    int days = 7,
  }) {
    final list = <DailySpend>[];
    final endDay = DateTime(targetDate.year, targetDate.month, targetDate.day);

    for (int i = days - 1; i >= 0; i--) {
      final date = endDay.subtract(Duration(days: i));
      final dayTxs = transactions.where((tx) =>
          tx.date.year == date.year &&
          tx.date.month == date.month &&
          tx.date.day == date.day);

      final exp = dayTxs
          .where((tx) => tx.type == TransactionType.expense)
          .fold<double>(0.0, (s, tx) => s + tx.amount);
      final inc = dayTxs
          .where((tx) => tx.type == TransactionType.income)
          .fold<double>(0.0, (s, tx) => s + tx.amount);

      final label = DateFormat('E d').format(date);
      list.add(DailySpend(date: date, label: label, expense: exp, income: inc));
    }
    return list;
  }

  static MonthComparison compareMonths({
    required List<TransactionItem> transactions,
    required DateTime targetDate,
  }) {
    final curTxs = transactions.where((tx) =>
        tx.date.year == targetDate.year && tx.date.month == targetDate.month);

    final prevDate = DateTime(targetDate.year, targetDate.month - 1, 1);
    final prevTxs = transactions.where((tx) =>
        tx.date.year == prevDate.year && tx.date.month == prevDate.month);

    final curExp = curTxs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0.0, (s, t) => s + t.amount);
    final curInc = curTxs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0.0, (s, t) => s + t.amount);

    final prevExp = prevTxs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0.0, (s, t) => s + t.amount);
    final prevInc = prevTxs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0.0, (s, t) => s + t.amount);

    final expChange = prevExp > 0 ? ((curExp - prevExp) / prevExp) * 100 : 0.0;
    final incChange = prevInc > 0 ? ((curInc - prevInc) / prevInc) * 100 : 0.0;

    return MonthComparison(
      currentMonthExpense: curExp,
      currentMonthIncome: curInc,
      previousMonthExpense: prevExp,
      previousMonthIncome: prevInc,
      expenseChangePercent: expChange,
      incomeChangePercent: incChange,
    );
  }
}
