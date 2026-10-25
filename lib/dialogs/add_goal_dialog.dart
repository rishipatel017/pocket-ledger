import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/savings_goal_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AddGoalDialog extends StatefulWidget {
  final AppState appState;
  final SavingsGoalItem? existingGoal;

  const AddGoalDialog({
    super.key,
    required this.appState,
    this.existingGoal,
  });

  static Future<void> show(
    BuildContext context,
    AppState appState, {
    SavingsGoalItem? existingGoal,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddGoalDialog(
        appState: appState,
        existingGoal: existingGoal,
      ),
    );
  }

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  late TextEditingController _titleController;
  late TextEditingController _targetAmountController;
  late TextEditingController _savedAmountController;
  late TextEditingController _categoryController;
  late TextEditingController _notesController;
  late DateTime _targetDate;

  @override
  void initState() {
    super.initState();
    final g = widget.existingGoal;
    _titleController = TextEditingController(text: g?.title ?? '');
    _targetAmountController = TextEditingController(
      text: g != null
          ? g.targetAmount.toStringAsFixed(
              g.targetAmount.truncateToDouble() == g.targetAmount ? 0 : 2)
          : '',
    );
    _savedAmountController = TextEditingController(
      text: g != null
          ? g.currentSaved.toStringAsFixed(
              g.currentSaved.truncateToDouble() == g.currentSaved ? 0 : 2)
          : '0',
    );
    _categoryController =
        TextEditingController(text: g?.category ?? 'Education & Tech');
    _notesController = TextEditingController(text: g?.notes ?? '');
    _targetDate =
        g?.targetDate ?? DateTime.now().add(const Duration(days: 90));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _savedAmountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primaryMint,
                onPrimary: Colors.black,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final target = double.tryParse(_targetAmountController.text.trim());
    final saved = double.tryParse(_savedAmountController.text.trim()) ?? 0.0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a goal name')),
      );
      return;
    }

    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target amount')),
      );
      return;
    }

    if (widget.existingGoal != null) {
      final updated = widget.existingGoal!.copyWith(
        title: title,
        targetAmount: target,
        currentSaved: saved,
        targetDate: _targetDate,
        category: _categoryController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      // Replace existing
      widget.appState.deleteSavingsGoal(widget.existingGoal!.id);
      widget.appState.addSavingsGoal(
        title: updated.title,
        targetAmount: updated.targetAmount,
        currentSaved: updated.currentSaved,
        targetDate: updated.targetDate,
        category: updated.category,
        notes: updated.notes,
      );
    } else {
      widget.appState.addSavingsGoal(
        title: title,
        targetAmount: target,
        currentSaved: saved,
        targetDate: _targetDate,
        category: _categoryController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
    }

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
                  widget.existingGoal != null
                      ? 'Edit Savings Goal'
                      : 'Create Savings Goal',
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

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Goal Title',
                hintText: 'e.g. MacBook Pro, Goa Trip, Emergency Fund',
                prefixIcon: Icon(Icons.stars),
              ),
            ),
            const SizedBox(height: 16),

            // Target Amount & Initial Saved
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Target ($currency)',
                      prefixText: '$currency ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _savedAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Saved So Far ($currency)',
                      prefixText: '$currency ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Target Deadline Date
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined,
                        size: 20, color: AppColors.accentIndigo),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Target Deadline',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, dd MMM yyyy').format(_targetDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category & Notes
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category / Tag',
                hintText: 'e.g. Tech, Travel, Emergency',
                prefixIcon: Icon(Icons.local_offer_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentIndigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _submit,
              child: Text(
                widget.existingGoal != null ? 'Update Goal' : 'Save Goal',
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
