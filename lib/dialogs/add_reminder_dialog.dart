import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reminder_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AddReminderDialog extends StatefulWidget {
  final AppState appState;
  final ReminderItem? existingReminder;

  const AddReminderDialog({
    super.key,
    required this.appState,
    this.existingReminder,
  });

  static Future<void> show(
    BuildContext context,
    AppState appState, {
    ReminderItem? existingReminder,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddReminderDialog(
        appState: appState,
        existingReminder: existingReminder,
      ),
    );
  }

  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _selectedDueDate;
  late ReminderRecurrence _selectedRecurrence;
  late String _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final r = widget.existingReminder;
    _titleController = TextEditingController(text: r?.title ?? '');
    _amountController = TextEditingController(
      text: r != null
          ? r.amount.toStringAsFixed(r.amount.truncateToDouble() == r.amount ? 0 : 2)
          : '',
    );
    _notesController = TextEditingController(text: r?.notes ?? '');
    _selectedDueDate =
        r?.dueDate ?? DateTime.now().add(const Duration(days: 3));
    _selectedRecurrence = r?.recurrence ?? ReminderRecurrence.monthly;
    _selectedCategoryId = r?.categoryId ?? 'utilities';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
      setState(() => _selectedDueDate = picked);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    // Validation
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bill or reminder title')),
      );
      return;
    }

    if (title.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title must be at least 3 characters')),
      );
      return;
    }

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    if (amount > 100000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount seems too large. Please verify.')),
      );
      return;
    }

    if (widget.existingReminder != null) {
      final updated = widget.existingReminder!.copyWith(
        title: title,
        amount: amount,
        dueDate: _selectedDueDate,
        recurrence: _selectedRecurrence,
        categoryId: _selectedCategoryId,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      widget.appState.updateReminder(updated);
    } else {
      widget.appState.addReminder(
        title: title,
        amount: amount,
        dueDate: _selectedDueDate,
        recurrence: _selectedRecurrence,
        categoryId: _selectedCategoryId,
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
                  widget.existingReminder != null
                      ? 'Edit Reminder'
                      : 'New Bill / Payment Reminder',
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
              autofocus: widget.existingReminder == null,
              decoration: const InputDecoration(
                labelText: 'Bill or Payment Title',
                hintText: 'e.g. Electricity, Rent, Mobile Recharge',
                prefixIcon: Icon(Icons.receipt_long),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount ($currency)',
                prefixText: '$currency ',
                prefixIcon: const Icon(Icons.monetization_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Due Date Picker
            InkWell(
              onTap: _pickDueDate,
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
                    const Icon(Icons.event,
                        size: 20, color: AppColors.warningAmber),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Due Date',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, dd MMM yyyy')
                              .format(_selectedDueDate),
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

            // Recurrence Chips
            const Text(
              'Recurrence Frequency',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: ReminderRecurrence.values.map((rec) {
                final isSelected = _selectedRecurrence == rec;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text(rec.displayName),
                    selectedColor: AppColors.primaryMint,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : (isDark ? Colors.white : Colors.black),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedRecurrence = rec);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Category
            const Text(
              'Category',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              dropdownColor: isDark ? AppColors.darkCard : Colors.white,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: widget.appState.categories
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
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategoryId = val);
              },
            ),
            const SizedBox(height: 16),

            // Notes
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
                backgroundColor: AppColors.warningAmber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _submit,
              child: Text(
                widget.existingReminder != null
                    ? 'Save Changes'
                    : 'Create Reminder',
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
