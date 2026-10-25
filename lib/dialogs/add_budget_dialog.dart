import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/budget_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AddBudgetDialog extends StatefulWidget {
  final AppState appState;
  final BudgetItem? existingBudget;

  const AddBudgetDialog({
    super.key,
    required this.appState,
    this.existingBudget,
  });

  static Future<void> show(
    BuildContext context,
    AppState appState, {
    BudgetItem? existingBudget,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddBudgetDialog(
        appState: appState,
        existingBudget: existingBudget,
      ),
    );
  }

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  late TextEditingController _amountController;
  late String _selectedCategoryId;
  late double _warningThreshold;

  @override
  void initState() {
    super.initState();
    final b = widget.existingBudget;
    _amountController = TextEditingController(
      text: b != null
          ? b.limitAmount.toStringAsFixed(b.limitAmount.truncateToDouble() == b.limitAmount ? 0 : 2)
          : '',
    );
    _selectedCategoryId = b?.categoryId ?? 'overall';
    _warningThreshold = b?.warningThreshold ?? 0.8;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget limit')),
      );
      return;
    }

    String categoryName = 'Overall Monthly Budget';
    if (_selectedCategoryId != 'overall') {
      final cat = widget.appState.categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => widget.appState.categories.first,
      );
      categoryName = cat.name;
    }

    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());

    widget.appState.setBudget(
      categoryId: _selectedCategoryId,
      categoryName: categoryName,
      limitAmount: amount,
      monthKey: monthKey,
      warningThreshold: _warningThreshold,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = widget.appState.currency;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                Text(
                  widget.existingBudget != null
                      ? 'Edit Budget Limit'
                      : 'Set Monthly Budget',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Selection
            const Text(
              'Select Scope or Category',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              dropdownColor: isDark ? AppColors.darkCard : Colors.white,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.track_changes),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'overall',
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, color: AppColors.primaryMint),
                      SizedBox(width: 10),
                      Text('Overall Monthly Budget (All Expenses)'),
                    ],
                  ),
                ),
                ...widget.appState.categories
                    .where((c) => c.isExpense)
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(c.iconData, size: 18, color: c.color),
                              const SizedBox(width: 10),
                              Text(c.name),
                            ],
                          ),
                        )),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategoryId = val);
              },
            ),
            const SizedBox(height: 16),

            // Limit Amount
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: widget.existingBudget == null,
              decoration: InputDecoration(
                labelText: 'Monthly Spending Limit ($currency)',
                prefixText: '$currency ',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Warning Threshold Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alert Threshold',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(_warningThreshold * 100).toInt()}% of budget',
                  style: const TextStyle(
                    color: AppColors.primaryMint,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _warningThreshold,
              min: 0.5,
              max: 1.0,
              divisions: 10,
              activeColor: AppColors.primaryMint,
              label: '${(_warningThreshold * 100).toInt()}%',
              onChanged: (val) => setState(() => _warningThreshold = val),
            ),
            const Text(
              'PocketLedger will alert you when your expenses reach this percentage of your limit.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMint,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _submit,
              child: Text(
                widget.existingBudget != null ? 'Update Budget' : 'Save Budget',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
