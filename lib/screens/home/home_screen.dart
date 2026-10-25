import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../state/app_state.dart';
import '../../models/transaction_item.dart';
import '../../models/reminder_item.dart';
import '../../theme/app_theme.dart';
import '../../dialogs/add_transaction_dialog.dart';
import '../../dialogs/add_reminder_dialog.dart';
import '../../dialogs/add_budget_dialog.dart';

class HomeScreen extends StatelessWidget {
  final AppState appState;
  final VoidCallback onNavigateToTransactions;
  final VoidCallback onNavigateToCalendar;
  final VoidCallback onNavigateToSettings;

  const HomeScreen({
    super.key,
    required this.appState,
    required this.onNavigateToTransactions,
    required this.onNavigateToCalendar,
    required this.onNavigateToSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isMonthly = appState.dashboardPeriodView == 'monthly';

    final income = isMonthly ? appState.currentMonthIncome : appState.currentWeekIncome;
    final expense = isMonthly ? appState.currentMonthExpense : appState.currentWeekExpense;
    final netCashFlow = income - expense;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => appState.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top App Bar / Header
                _buildHeader(context),
                const SizedBox(height: 16),

                // Hero Cash Flow & Balance Card
                _buildHeroCard(context, income, expense, netCashFlow),
                const SizedBox(height: 16),

                // Student Mode Runway Card (if enabled)
                if (appState.isStudentMode) ...[
                  _buildStudentRunwayCard(context),
                  const SizedBox(height: 16),
                ],

                // Quick Action Buttons
                _buildQuickActions(context),
                const SizedBox(height: 18),

                // Monthly Budget Status Card
                _buildBudgetStatusCard(context),
                const SizedBox(height: 18),

                // Upcoming Reminders & Bills Card
                _buildUpcomingBillsSection(context),
                const SizedBox(height: 18),

                // Recent Transactions Section
                _buildRecentTransactionsSection(context),
                const SizedBox(height: 80), // padding for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryMint.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.account_balance_wallet, color: Colors.black, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PocketLedger',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                if (appState.isStudentMode)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMint.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primaryMint.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'STUDENT MODE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryMint,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),

        // Eye toggle for discreet/hide balances
        IconButton(
          tooltip: appState.hideBalances ? 'Show Balances' : 'Hide Balances',
          icon: Icon(
            appState.hideBalances ? Icons.visibility_off : Icons.visibility,
            color: appState.hideBalances ? AppColors.warningAmber : AppColors.darkTextSecondary,
          ),
          onPressed: () => appState.toggleHideBalances(),
        ),

        // Lock button (if PIN enabled)
        if (appState.settings.isPinLockEnabled)
          IconButton(
            tooltip: 'Lock Application',
            icon: const Icon(Icons.lock_outline, color: AppColors.darkTextSecondary),
            onPressed: () => appState.lockApp(),
          ),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    double income,
    double expense,
    double netCashFlow,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMonthly = appState.dashboardPeriodView == 'monthly';

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.cardDarkGradient : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toggle Period Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMonthly ? 'THIS MONTH\'S CASH FLOW' : 'THIS WEEK\'S CASH FLOW',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _periodTab('Weekly', !isMonthly, () {
                      appState.setDashboardPeriodView('weekly');
                    }),
                    _periodTab('Monthly', isMonthly, () {
                      appState.setDashboardPeriodView('monthly');
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Net Cash Flow Value
          Text(
            appState.formatAmount(netCashFlow, showSign: true),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: netCashFlow >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                netCashFlow >= 0 ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: netCashFlow >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
              ),
              const SizedBox(width: 4),
              Text(
                netCashFlow >= 0 ? 'Net Surplus' : 'Net Deficit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: netCashFlow >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                ),
              ),
              const Spacer(),
              Text(
                'Total Balance: ${appState.formatAmount(appState.allTimeBalance)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 16),

          // Income vs Expense Breakdown Row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.incomeGreen.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: AppColors.incomeGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                        Text(
                          appState.formatAmount(income),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.incomeGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.expenseRed.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: AppColors.expenseRed,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expenses',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                          Text(
                            appState.formatAmount(expense),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.expenseRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodTab(String title, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryMint : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? Colors.black : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentRunwayCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingAllowance = appState.studentAllowanceRemaining;
    final burnRate = appState.studentDailyBurnRate;
    final runwayDays = appState.studentDaysOfRunway;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeftInMonth = (daysInMonth - now.day).clamp(1, 31);
    final isSafe = runwayDays >= daysLeftInMonth;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSafe
              ? AppColors.primaryMint.withOpacity(0.4)
              : AppColors.warningAmber.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_outlined,
                color: isSafe ? AppColors.primaryMint : AppColors.warningAmber,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Student Budget Runway',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isSafe ? AppColors.primaryMint : AppColors.warningAmber)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSafe ? 'On Track' : 'Tight Budget',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSafe ? AppColors.primaryMint : AppColors.warningAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Allowance Left',
                    style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                  ),
                  Text(
                    appState.formatAmount(remainingAllowance),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: remainingAllowance >= 0 ? Colors.white : AppColors.expenseRed,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Daily Burn Rate',
                    style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                  ),
                  Text(
                    '${appState.formatAmount(burnRate)}/day',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Est. Runway',
                    style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                  ),
                  Text(
                    '~${runwayDays.toStringAsFixed(1)} days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSafe ? AppColors.primaryMint : AppColors.warningAmber,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: appState.settings.studentMonthlyAllowance > 0
                  ? (appState.currentMonthExpense / appState.settings.studentMonthlyAllowance).clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor: isDark ? AppColors.darkElevated : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isSafe ? AppColors.primaryMint : AppColors.warningAmber,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickActionButton(
            context: context,
            label: 'Add Expense',
            icon: Icons.remove_circle_outline,
            color: AppColors.expenseRed,
            onTap: () {
              AddTransactionDialog.show(context, appState);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickActionButton(
            context: context,
            label: 'Add Income',
            icon: Icons.add_circle_outline,
            color: AppColors.incomeGreen,
            onTap: () {
              AddTransactionDialog.show(context, appState);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickActionButton(
            context: context,
            label: 'Add Bill',
            icon: Icons.receipt_long,
            color: AppColors.warningAmber,
            onTap: () {
              AddReminderDialog.show(context, appState);
            },
          ),
        ),
      ],
    );
  }

  Widget _quickActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetStatusCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budget = appState.overallBudget;
    final spent = appState.overallBudgetSpent;
    final remaining = appState.overallBudgetRemaining;
    final progress = appState.overallBudgetProgress;

    final isOverBudget = remaining < 0;
    final isNearLimit = progress >= (budget?.warningThreshold ?? 0.8);

    Color statusColor = AppColors.primaryMint;
    if (isOverBudget) {
      statusColor = AppColors.expenseRed;
    } else if (isNearLimit) {
      statusColor = AppColors.warningAmber;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Overall Monthly Budget',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureCardButton(
                label: 'Manage',
                onTap: () => AddBudgetDialog.show(context, appState, existingBudget: budget),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Spent vs Limit Numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spent',
                    style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                  ),
                  Text(
                    appState.formatAmount(spent),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isOverBudget ? 'Exceeded by' : 'Remaining',
                    style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                  ),
                  Text(
                    appState.formatAmount(remaining.abs()),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOverBudget ? AppColors.expenseRed : AppColors.primaryMint,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? AppColors.darkElevated : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% utilized',
                style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
              ),
              Text(
                'Limit: ${appState.formatAmount(budget?.limitAmount ?? 0)}',
                style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBillsSection(BuildContext context) {
    final reminders = appState.upcomingReminders;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined, color: AppColors.warningAmber, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Upcoming Reminders & Bills',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (reminders.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warningAmber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${reminders.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            GestureCardButton(
              label: 'Calendar',
              onTap: onNavigateToCalendar,
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (reminders.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
              ),
            ),
            child: const Center(
              child: Text(
                'No pending bill payments. You\'re all caught up! 🎉',
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
              ),
            ),
          )
        else
          Column(
            children: reminders.take(3).map((reminder) {
              return _buildReminderTile(context, reminder);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildReminderTile(BuildContext context, ReminderItem reminder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDueSoon = reminder.dueDate.difference(DateTime.now()).inDays <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reminder.isOverdue
              ? AppColors.expenseRed.withOpacity(0.5)
              : (isDueSoon
                  ? AppColors.warningAmber.withOpacity(0.4)
                  : (isDark ? AppColors.darkBorder : Colors.grey.shade200)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: reminder.isOverdue
                  ? AppColors.expenseRed.withOpacity(0.15)
                  : AppColors.warningAmber.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              reminder.isOverdue ? Icons.warning_rounded : Icons.receipt_long,
              color: reminder.isOverdue ? AppColors.expenseRed : AppColors.warningAmber,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.isOverdue
                      ? 'Overdue (${DateFormat('dd MMM').format(reminder.dueDate)})'
                      : 'Due on ${DateFormat('EEE, dd MMM').format(reminder.dueDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: reminder.isOverdue
                        ? AppColors.expenseRed
                        : AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                appState.formatAmount(reminder.amount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _showPayConfirmationDialog(context, reminder),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Mark Paid',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPayConfirmationDialog(BuildContext context, ReminderItem reminder) {
    bool createLinkedExpense = true;
    PaymentMethod method = PaymentMethod.upi;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Pay ${reminder.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ${appState.formatAmount(reminder.amount)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              CheckboxListTile(
                value: createLinkedExpense,
                activeColor: AppColors.primaryMint,
                contentPadding: EdgeInsets.zero,
                title: const Text('Record as expense transaction'),
                subtitle: const Text(
                  'Prevents duplicate manual entry by automatically creating an expense entry.',
                  style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                ),
                onChanged: (val) {
                  setDialogState(() => createLinkedExpense = val ?? true);
                },
              ),
              if (createLinkedExpense) ...[
                const SizedBox(height: 8),
                const Text('Payment Method:', style: TextStyle(fontSize: 12)),
                DropdownButton<PaymentMethod>(
                  value: method,
                  isExpanded: true,
                  dropdownColor: AppColors.darkCard,
                  items: PaymentMethod.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.displayName),
                          ))
                      .toList(),
                  onChanged: (m) {
                    if (m != null) setDialogState(() => method = m);
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMint,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                appState.markReminderPaid(
                  id: reminder.id,
                  createLinkedExpense: createLinkedExpense,
                  paymentMethod: method,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Marked "${reminder.title}" as paid${createLinkedExpense ? ' and recorded expense' : ''}.',
                    ),
                  ),
                );
              },
              child: const Text('Confirm Paid'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context) {
    final transactions = appState.allTransactions.take(5).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            GestureCardButton(
              label: 'View All',
              onTap: onNavigateToTransactions,
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'No transactions recorded yet. Tap + to add one!',
                style: TextStyle(color: AppColors.darkTextSecondary),
              ),
            ),
          )
        else
          Column(
            children: transactions.map((tx) {
              return _buildTransactionTile(context, tx);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionItem tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = tx.type == TransactionType.expense;
    final isIncome = tx.type == TransactionType.income;

    Color amountColor = isExpense
        ? AppColors.expenseRed
        : (isIncome ? AppColors.incomeGreen : AppColors.transferBlue);

    return InkWell(
      onTap: () => AddTransactionDialog.show(context, appState, existingTransaction: tx),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isExpense
                    ? Icons.shopping_bag_outlined
                    : (isIncome ? Icons.account_balance_wallet_outlined : Icons.swap_horiz),
                color: amountColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        tx.categoryName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkElevated : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tx.paymentMethod.displayName,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.darkTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  appState.formatAmount(tx.amount, showSign: true, isExpense: isExpense),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM').format(tx.date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.darkTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GestureCardButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const GestureCardButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryMint,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.primaryMint),
          ],
        ),
      ),
    );
  }
}
