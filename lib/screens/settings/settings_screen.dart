import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/app_state.dart';
import '../../models/financial_record_item.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../dialogs/add_budget_dialog.dart';
import '../../dialogs/add_financial_record_dialog.dart';
import '../../dialogs/add_goal_dialog.dart';

class SettingsScreen extends StatelessWidget {
  final AppState appState;
  final NotificationService notificationService;

  const SettingsScreen({
    super.key,
    required this.appState,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Student Mode Section
          _buildSectionHeader('STUDENT MODE & ALLOWANCE'),
          _buildStudentModeCard(context),
          const SizedBox(height: 20),

          // 2. Security & Application Lock (FR-08)
          _buildSectionHeader('SECURITY & APP LOCK'),
          _buildSecurityCard(context),
          const SizedBox(height: 20),

          // 3. Notifications
          _buildSectionHeader('NOTIFICATIONS & ALERTS'),
          _buildNotificationsCard(context),
          const SizedBox(height: 20),

          // 4. Budgets & Goals
          _buildSectionHeader('BUDGETS & SAVINGS GOALS'),
          _buildBudgetsAndGoalsCard(context),
          const SizedBox(height: 20),

          // 5. Financial Records (FD, RD, Insurance) (FR-07)
          _buildSectionHeader('FINANCIAL RECORDS & MATURITIES'),
          _buildFinancialRecordsCard(context),
          const SizedBox(height: 20),

          // 6. Currency & Categories (FR-09)
          _buildSectionHeader('PREFERENCES & CATEGORIES'),
          _buildPreferencesCard(context),
          const SizedBox(height: 20),

          // 7. Data Management, Export & Backup (FR-09)
          _buildSectionHeader('DATA MANAGEMENT & BACKUP'),
          _buildDataManagementCard(context),
          const SizedBox(height: 20),

          // 8. Privacy & About
          _buildAboutCard(context),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // --- Notifications Card ---
  Widget _buildNotificationsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentIndigo.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_outlined,
                    color: AppColors.accentIndigo),
              ),
              title: const Text('Enable Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text(
                'Get alerts for bill due dates, budget limits, and FD maturity reminders.',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentIndigo,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final granted =
                      await notificationService.requestPermission();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(granted
                            ? 'Notifications enabled! You will receive alerts for bills and budgets.'
                            : 'Permission denied. Enable from device Settings > Apps > PocketLedger.'),
                        backgroundColor: granted
                            ? AppColors.incomeGreen
                            : AppColors.expenseRed,
                      ),
                    );
                  }
                },
                child: const Text('Allow', style: TextStyle(fontSize: 13)),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.alarm_outlined,
                    color: AppColors.warningAmber),
              ),
              title: const Text('Check & Send Reminders Now',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text(
                'Fire immediate alerts for all bills due within 3 days and FDs maturing within 30 days.',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await notificationService.checkAndFireReminders(appState.reminders);
                await notificationService.checkAndFireFDAlerts(
                    appState.financialRecords);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reminder alerts sent! Check your notification panel.'),
                      backgroundColor: AppColors.accentIndigo,
                    ),
                  );
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryMint.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today_outlined,
                    color: AppColors.primaryMint),
              ),
              title: const Text('Monthly Budget Reminder',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text(
                'Send a reminder to set your monthly budget for the current month.',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              trailing: const Icon(Icons.send_outlined,
                  color: AppColors.primaryMint, size: 20),
              onTap: () async {
                final now = DateTime.now();
                final monthNames = [
                  '', 'January', 'February', 'March', 'April', 'May', 'June',
                  'July', 'August', 'September', 'October', 'November', 'December'
                ];
                final budget = appState.overallBudget;
                await notificationService.showMonthlyBudgetReminder(
                  monthName: monthNames[now.month],
                  lastMonthLimit: budget?.limitAmount,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Monthly budget reminder sent!'),
                      backgroundColor: AppColors.primaryMint,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Student Mode Card ---
  Widget _buildStudentModeCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            SwitchListTile(
              value: appState.isStudentMode,
              activeColor: AppColors.primaryMint,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryMint.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, color: AppColors.primaryMint),
              ),
              title: const Text('Student Mode',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text(
                'Enables student categories (Mess, Canteen, Books, Pocket Money) & daily runway forecast.',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              onChanged: (val) => appState.toggleStudentMode(val),
            ),
            if (appState.isStudentMode) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.payments_outlined,
                    color: AppColors.primaryMint),
                title: const Text('Monthly Allowance Target'),
                subtitle: Text(
                  appState.formatAmount(
                      appState.settings.studentMonthlyAllowance),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.primaryMint),
                ),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () => _editStudentAllowance(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _editStudentAllowance(BuildContext context) {
    final controller = TextEditingController(
      text: appState.settings.studentMonthlyAllowance.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Set Monthly Allowance'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Allowance Amount (${appState.currency})',
            prefixText: '${appState.currency} ',
          ),
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
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                appState.setStudentAllowance(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // --- Security Card (FR-08) ---
  Widget _buildSecurityCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPinEnabled = appState.settings.isPinLockEnabled;

    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            SwitchListTile(
              value: isPinEnabled,
              activeColor: AppColors.primaryMint,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isPinEnabled
                          ? AppColors.primaryMint
                          : Colors.grey)
                      .withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: isPinEnabled ? AppColors.primaryMint : Colors.grey,
                ),
              ),
              title: const Text('PIN Protection',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                isPinEnabled
                    ? 'Application is locked with a secure 4-digit PIN.'
                    : 'Protect access to your personal finance records with a PIN.',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              onChanged: (val) {
                if (val) {
                  _showSetupPinDialog(context);
                } else {
                  _showDisablePinConfirmation(context);
                }
              },
            ),
            if (isPinEnabled) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.key, color: AppColors.primaryMint),
                title: const Text('Change PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSetupPinDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_clock_outlined,
                    color: AppColors.primaryMint),
                title: const Text('Lock App Now'),
                onTap: () => appState.lockApp(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSetupPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    final questionController = TextEditingController(
      text: 'What was the name of your first school?',
    );
    final answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Set 4-Digit Security PIN'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '4-Digit PIN',
                  hintText: 'e.g. 1234',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Security Question (for recovery)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: 'Security Answer',
                ),
              ),
            ],
          ),
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
              if (pinController.text.length == 4 &&
                  answerController.text.trim().isNotEmpty) {
                appState.setupPin(
                  pin: pinController.text,
                  securityQuestion: questionController.text.trim(),
                  securityAnswer: answerController.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN lock enabled successfully!'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN must be 4 digits and answer filled.'),
                  ),
                );
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  void _showDisablePinConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Disable PIN Lock'),
        content: const Text(
            'Are you sure you want to disable PIN lock? Anyone with your device will be able to access the application.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep PIN'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              appState.disablePin();
              Navigator.pop(ctx);
            },
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  // --- Budgets and Goals Card ---
  Widget _buildBudgetsAndGoalsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.pie_chart_outline,
                  color: AppColors.primaryMint),
              title: const Text('Manage Budgets',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${appState.budgets.length} active monthly & category budgets',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showBudgetsManagerModal(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.stars_outlined,
                  color: AppColors.accentIndigo),
              title: const Text('Savings Goals',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${appState.savingsGoals.length} goals (Laptop, Trip, Emergency fund)',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSavingsGoalsModal(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetsManagerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monthly Budgets',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMint,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Budget'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AddBudgetDialog.show(context, appState);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: appState.budgets.isEmpty
                    ? const Center(child: Text('No budgets created yet.'))
                    : ListView.builder(
                        itemCount: appState.budgets.length,
                        itemBuilder: (context, i) {
                          final b = appState.budgets[i];
                          final spent = b.isOverall
                              ? appState.currentMonthExpense
                              : appState.getCategoryBudgetSpent(
                                  b.categoryId, b.monthKey);
                          final progress = b.limitAmount > 0
                              ? (spent / b.limitAmount).clamp(0.0, 1.0)
                              : 0.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      b.categoryName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              size: 18, color: Colors.grey),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            AddBudgetDialog.show(
                                              context,
                                              appState,
                                              existingBudget: b,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              size: 18,
                                              color: AppColors.expenseRed),
                                          onPressed: () =>
                                              appState.deleteBudget(b.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Spent: ${appState.formatAmount(spent)}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.darkTextSecondary),
                                    ),
                                    Text(
                                      'Limit: ${appState.formatAmount(b.limitAmount)}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: isDark
                                        ? AppColors.darkElevated
                                        : Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progress >= 1.0
                                          ? AppColors.expenseRed
                                          : (progress >= b.warningThreshold
                                              ? AppColors.warningAmber
                                              : AppColors.primaryMint),
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSavingsGoalsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Savings Goals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentIndigo,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Goal'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AddGoalDialog.show(context, appState);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: appState.savingsGoals.isEmpty
                    ? const Center(child: Text('No savings goals created yet.'))
                    : ListView.builder(
                        itemCount: appState.savingsGoals.length,
                        itemBuilder: (context, i) {
                          final g = appState.savingsGoals[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      g.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18,
                                          color: AppColors.expenseRed),
                                      onPressed: () =>
                                          appState.deleteSavingsGoal(g.id),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Saved: ${appState.formatAmount(g.currentSaved)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryMint),
                                    ),
                                    Text(
                                      'Target: ${appState.formatAmount(g.targetAmount)}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.darkTextSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: g.progressPercentage,
                                    backgroundColor: isDark
                                        ? AppColors.darkElevated
                                        : Colors.grey.shade200,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            AppColors.accentIndigo),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${(g.progressPercentage * 100).toInt()}% achieved',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.accentIndigo,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextButton(
                                      onPressed: () => _addMoneyToGoal(
                                          context, g.id, g.title),
                                      child: const Text('+ Add Money',
                                          style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addMoneyToGoal(BuildContext context, String goalId, String title) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: Text('Contribute to $title'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Contribution Amount (${appState.currency})',
            prefixText: '${appState.currency} ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentIndigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                appState.addGoalContribution(goalId, val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Added ${appState.formatAmount(val)} to goal!')),
                );
              }
            },
            child: const Text('Add Money'),
          ),
        ],
      ),
    );
  }

  // --- Financial Records Card (FR-07) ---
  Widget _buildFinancialRecordsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
        child: ListTile(
          leading: const Icon(Icons.account_balance, color: AppColors.primaryCyan),
          title: const Text('Fixed Deposits & Insurance Policies',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${appState.activeFinancialRecords.length} active records with maturity tracking',
            style: const TextStyle(
                fontSize: 12, color: AppColors.darkTextSecondary),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showFinancialRecordsModal(context),
        ),
      ),
    );
  }

  void _showFinancialRecordsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Financial Records & FDs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Record'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AddFinancialRecordDialog.show(context, appState);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: appState.financialRecords.isEmpty
                    ? const Center(
                        child: Text('No FD or insurance records stored.'))
                    : ListView.builder(
                        itemCount: appState.financialRecords.length,
                        itemBuilder: (context, i) {
                          final r = appState.financialRecords[i];
                          final days = r.daysUntilMaturity;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      r.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    Text(
                                      appState.formatAmount(
                                          r.principalOrPremium),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryCyan),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${r.institution} • ${r.type.displayName}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.darkTextSecondary),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      days > 0
                                          ? 'Matures in $days days'
                                          : 'Matured',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: days > 0
                                            ? AppColors.primaryMint
                                            : AppColors.warningAmber,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18,
                                          color: AppColors.expenseRed),
                                      onPressed: () =>
                                          appState.deleteFinancialRecord(r.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Preferences & Categories Card ---
  Widget _buildPreferencesCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.currency_exchange,
                  color: AppColors.primaryMint),
              title: const Text('Currency Symbol'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appState.currency,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              onTap: () => _showCurrencyPicker(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.category_outlined, color: AppColors.primaryMint),
              title: const Text('Category Manager'),
              subtitle: Text(
                '${appState.categories.length} total categories',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showCategoryManagerModal(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    const currencies = [
      {'symbol': '₹', 'name': 'INR - Indian Rupee'},
      {'symbol': '\$', 'name': 'USD - US Dollar'},
      {'symbol': '€', 'name': 'EUR - Euro'},
      {'symbol': '£', 'name': 'GBP - British Pound'},
      {'symbol': '¥', 'name': 'JPY - Japanese Yen'},
      {'symbol': 'C\$', 'name': 'CAD - Canadian Dollar'},
      {'symbol': 'A\$', 'name': 'AUD - Australian Dollar'},
      {'symbol': '₩', 'name': 'KRW - South Korean Won'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Currency',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...currencies.map((c) {
                final isSelected = appState.currency == c['symbol'];
                return ListTile(
                  leading: Text(
                    c['symbol']!,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  title: Text(c['name']!),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primaryMint)
                      : null,
                  onTap: () {
                    appState.setCurrency(c['symbol']!);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryManagerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('All Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: appState.categories.length,
                  itemBuilder: (context, i) {
                    final cat = appState.categories[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cat.color.withOpacity(0.2),
                        child: Icon(cat.iconData, color: cat.color, size: 20),
                      ),
                      title: Text(cat.name),
                      subtitle: Text(
                        cat.isExpense
                            ? 'Expense ${cat.isStudentOnly ? '• Student' : ''}'
                            : 'Income ${cat.isStudentOnly ? '• Student' : ''}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: cat.isCustom
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.expenseRed),
                              onPressed: () =>
                                  appState.deleteCategory(cat.id),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Data Management Card (FR-09) ---
  Widget _buildDataManagementCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.table_view_outlined,
                  color: AppColors.primaryMint),
              title: const Text('Export Transactions to CSV'),
              subtitle: const Text(
                'Generate downloadable CSV file of all transaction history.',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              trailing: const Icon(Icons.download),
              onTap: () => _exportCsvFlow(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.backup_outlined,
                  color: AppColors.primaryMint),
              title: const Text('Full JSON Backup'),
              subtitle: const Text(
                'Export all application state, settings, reminders, and records.',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              trailing: const Icon(Icons.copy),
              onTap: () => _exportBackupJsonFlow(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.restore, color: AppColors.primaryCyan),
              title: const Text('Restore from Backup'),
              subtitle: const Text(
                'Restore application data from a JSON backup snippet.',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              onTap: () => _restoreBackupFlow(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_forever,
                  color: AppColors.expenseRed),
              title: const Text(
                'Reset / Clear All Data',
                style: TextStyle(color: AppColors.expenseRed),
              ),
              subtitle: const Text(
                'Permanently wipe local records and restore fresh demo setup.',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              onTap: () => _confirmResetAllData(context),
            ),
          ],
        ),
      ),
    );
  }

  void _exportCsvFlow(BuildContext context) {
    final csvContent = appState.exportCsv();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('CSV Export Ready'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your transaction history has been converted to CSV format:',
              style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.darkElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csvContent,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMint,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvContent));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV copied to clipboard!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _exportBackupJsonFlow(BuildContext context) {
    final jsonContent = appState.exportBackupJson();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Full Backup JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete encrypted/structured backup of your PocketLedger vault:',
              style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              height: 140,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.darkElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  jsonContent,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMint,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Backup JSON'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonContent));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup JSON copied to clipboard!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _restoreBackupFlow(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Restore from Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste your backup JSON snippet below:',
              style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 6,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: 'Paste JSON here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok = await appState.restoreBackup(controller.text.trim());
              Navigator.pop(ctx);
              if (ok) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Backup restored successfully!')),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to restore. Invalid backup JSON format.'),
                  ),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmResetAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Wipe All Data?'),
        content: const Text(
          'This will permanently delete all recorded transactions, categories, budgets, reminders, and PIN security credentials.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await appState.resetAllData();
              Navigator.pop(ctx);
              messenger.showSnackBar(
                const SnackBar(content: Text('All data has been reset.')),
              );
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  // --- About Card ---
  Widget _buildAboutCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined,
                  color: AppColors.primaryMint, size: 22),
              SizedBox(width: 10),
              Text(
                '100% Offline & Private',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'PocketLedger stores all transactions, budgets, bills, and PIN passwords exclusively on your local device storage. No remote servers, bank screen scraping, or external trackers are ever used.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.darkTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'PocketLedger v1.0.0 • Academic & Professional Release',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.darkTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
