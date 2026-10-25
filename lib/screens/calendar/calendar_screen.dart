import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../state/app_state.dart';
import '../../models/reminder_item.dart';
import '../../models/financial_record_item.dart';
import '../../models/transaction_item.dart';
import '../../theme/app_theme.dart';
import '../../dialogs/add_reminder_dialog.dart';

class CalendarScreen extends StatefulWidget {
  final AppState appState;

  const CalendarScreen({super.key, required this.appState});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<ReminderItem> _getRemindersForDay(DateTime day) {
    return widget.appState.reminders.where((r) {
      return _isSameDay(r.dueDate, day);
    }).toList();
  }

  List<FinancialRecordItem> _getRecordsForDay(DateTime day) {
    return widget.appState.financialRecords.where((r) {
      return _isSameDay(r.maturityOrRenewalDate, day);
    }).toList();
  }

  List<TransactionItem> _getTransactionsForDay(DateTime day) {
    return widget.appState.allTransactions.where((t) {
      return _isSameDay(t.date, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedReminders = _getRemindersForDay(_selectedDay);
    final selectedRecords = _getRecordsForDay(_selectedDay);
    final selectedTransactions = _getTransactionsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Calendar'),
        actions: [
          IconButton(
            tooltip: 'Add Bill Reminder',
            icon: const Icon(Icons.add_alert_outlined),
            onPressed: () => AddReminderDialog.show(context, widget.appState),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Month navigation & Header
            _buildMonthHeader(),
            const SizedBox(height: 12),

            // Calendar Grid Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  _buildDaysOfWeekHeader(),
                  const SizedBox(height: 10),
                  _buildCalendarGrid(),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Legend
            _buildLegend(),
            const SizedBox(height: 18),

            // Selected Day Obligations & Details
            _buildDayEventsSection(
              selectedReminders,
              selectedRecords,
              selectedTransactions,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _previousMonth,
        ),
        Text(
          DateFormat('MMMM yyyy').format(_focusedMonth),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _nextMonth,
        ),
      ],
    );
  }

  Widget _buildDaysOfWeekHeader() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => SizedBox(
                width: 38,
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // DateTime weekday: 1 = Mon, 7 = Sun
    final startingOffset = firstDayOfMonth.weekday - 1;

    final totalCells = ((startingOffset + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        if (index < startingOffset || index >= startingOffset + daysInMonth) {
          return const SizedBox();
        }

        final dayNum = index - startingOffset + 1;
        final cellDate = DateTime(year, month, dayNum);
        final isSelected = _isSameDay(cellDate, _selectedDay);
        final isToday = _isSameDay(cellDate, DateTime.now());

        final hasBill = _getRemindersForDay(cellDate).isNotEmpty;
        final hasRecord = _getRecordsForDay(cellDate).isNotEmpty;
        final hasTransaction = _getTransactionsForDay(cellDate).isNotEmpty;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedDay = cellDate);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryMint
                  : (isToday ? AppColors.darkElevated : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryMint
                    : (isToday
                        ? AppColors.primaryMint.withOpacity(0.5)
                        : Colors.transparent),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNum',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected || isToday
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.black : null,
                  ),
                ),
                const SizedBox(height: 4),

                // Indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasBill)
                      _dot(isSelected ? Colors.black : AppColors.warningAmber),
                    if (hasRecord)
                      _dot(isSelected ? Colors.black : AppColors.primaryCyan),
                    if (hasTransaction)
                      _dot(isSelected ? Colors.black : AppColors.primaryMint),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dot(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(AppColors.warningAmber, 'Bill / Reminder'),
        const SizedBox(width: 14),
        _legendItem(AppColors.primaryCyan, 'FD / Maturity'),
        const SizedBox(width: 14),
        _legendItem(AppColors.primaryMint, 'Transaction'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.darkTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDayEventsSection(
    List<ReminderItem> reminders,
    List<FinancialRecordItem> records,
    List<TransactionItem> transactions,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayLabel = DateFormat('EEEE, dd MMMM yyyy').format(_selectedDay);

    final hasNoEvents =
        reminders.isEmpty && records.isEmpty && transactions.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dayLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (reminders.isNotEmpty || records.isNotEmpty || transactions.isNotEmpty)
              Text(
                '${reminders.length + records.length + transactions.length} events',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (hasNoEvents)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
              ),
            ),
            child: const Center(
              child: Text(
                'No payments or transactions scheduled for this date.',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else ...[
          // FD & Financial Records Section (Priority)
          if (records.isNotEmpty) ...[
            _buildSectionHeader('FD & Financial Maturities', AppColors.primaryCyan),
            const SizedBox(height: 8),
            ...records.map((rec) => _buildRecordCard(rec)),
            const SizedBox(height: 12),
          ],

          // Bills & Reminders
          if (reminders.isNotEmpty) ...[
            _buildSectionHeader('Bill Reminders', AppColors.warningAmber),
            const SizedBox(height: 8),
            ...reminders.map((r) => _buildReminderCard(r)),
            const SizedBox(height: 12),
          ],

          // Transactions on this date
          if (transactions.isNotEmpty) ...[
            _buildSectionHeader('Transactions', AppColors.primaryMint),
            const SizedBox(height: 8),
            ...transactions.map((tx) => _buildTransactionCard(tx)),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(ReminderItem reminder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reminder.isPaid
              ? AppColors.primaryMint.withOpacity(0.4)
              : AppColors.warningAmber.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (reminder.isPaid
                      ? AppColors.primaryMint
                      : AppColors.warningAmber)
                  .withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              reminder.isPaid ? Icons.check_circle : Icons.alarm,
              color: reminder.isPaid
                  ? AppColors.primaryMint
                  : AppColors.warningAmber,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${reminder.recurrence.displayName} Bill • ${reminder.status.name.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.appState.formatAmount(reminder.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (!reminder.isPaid)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMint,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      widget.appState.markReminderPaid(
                        id: reminder.id,
                        createLinkedExpense: true,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Marked "${reminder.title}" as paid & logged expense.'),
                        ),
                      );
                    },
                    child: const Text('Pay', style: TextStyle(fontSize: 11)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(FinancialRecordItem rec) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryCyan.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance,
              color: AppColors.primaryCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${rec.institution} • Maturity Date',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            widget.appState.formatAmount(rec.principalOrPremium),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.primaryCyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionItem tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = tx.type == TransactionType.expense;
    final color = isExpense ? AppColors.expenseRed : AppColors.incomeGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpense ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tx.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            widget.appState.formatAmount(tx.amount,
                showSign: true, isExpense: isExpense),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
