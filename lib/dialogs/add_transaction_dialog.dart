import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AddTransactionDialog extends StatefulWidget {
  final AppState appState;
  final TransactionItem? existingTransaction;

  const AddTransactionDialog({
    super.key,
    required this.appState,
    this.existingTransaction,
  });

  static Future<void> show(
    BuildContext context,
    AppState appState, {
    TransactionItem? existingTransaction,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTransactionDialog(
        appState: appState,
        existingTransaction: existingTransaction,
      ),
    );
  }

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late TextEditingController _transferToController;

  late TransactionType _selectedType;
  late DateTime _selectedDate;
  late PaymentMethod _selectedPaymentMethod;
  CategoryItem? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTransaction;
    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(
      text: tx != null ? tx.amount.toStringAsFixed(tx.amount.truncateToDouble() == tx.amount ? 0 : 2) : '',
    );
    _notesController = TextEditingController(text: tx?.notes ?? '');
    _transferToController =
        TextEditingController(text: tx?.transferToAccount ?? 'Savings Account');

    _selectedType = tx?.type ?? TransactionType.expense;
    _selectedDate = tx?.date ?? DateTime.now();
    _selectedPaymentMethod = tx?.paymentMethod ?? PaymentMethod.upi;

    // Pick matching category
    final availableCategories = _getAvailableCategories();
    if (tx != null) {
      _selectedCategory = availableCategories.firstWhere(
        (c) => c.id == tx.categoryId,
        orElse: () => availableCategories.first,
      );
    } else {
      _selectedCategory = availableCategories.isNotEmpty
          ? availableCategories.first
          : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _transferToController.dispose();
    super.dispose();
  }

  List<CategoryItem> _getAvailableCategories() {
    final isExpense = _selectedType == TransactionType.expense;
    final isIncome = _selectedType == TransactionType.income;
    final isStudentMode = widget.appState.isStudentMode;

    return widget.appState.categories.where((c) {
      if (isExpense && !c.isExpense) return false;
      if (isIncome && c.isExpense) return false;
      if (!isStudentMode && c.isStudentOnly) return false;
      return true;
    }).toList();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _selectedType = type;
      final available = _getAvailableCategories();
      if (available.isNotEmpty) {
        _selectedCategory = available.first;
      } else {
        _selectedCategory = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    // Validation
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

    if (_selectedType == TransactionType.transfer) {
      final transferTo = _transferToController.text.trim();
      if (transferTo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please specify transfer destination')),
        );
        return;
      }
    }

    final cat = _selectedCategory ??
        CategoryItem(
          id: 'general',
          name: _selectedType == TransactionType.transfer
              ? 'Transfer'
              : 'General',
          iconCodePoint: Icons.account_balance_wallet.codePoint,
          colorValue: Colors.blueGrey.value,
          isExpense: _selectedType == TransactionType.expense,
        );

    final finalTitle = title.isEmpty ? cat.name : title;

    if (widget.existingTransaction != null) {
      final updated = widget.existingTransaction!.copyWith(
        title: finalTitle,
        amount: amount,
        type: _selectedType,
        date: _selectedDate,
        categoryId: cat.id,
        categoryName: cat.name,
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim(),
        transferToAccount: _selectedType == TransactionType.transfer
            ? _transferToController.text.trim()
            : null,
      );
      widget.appState.updateTransaction(updated);
    } else {
      widget.appState.addTransaction(
        title: finalTitle,
        amount: amount,
        type: _selectedType,
        date: _selectedDate,
        categoryId: cat.id,
        categoryName: cat.name,
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        transferToAccount: _selectedType == TransactionType.transfer
            ? _transferToController.text.trim()
            : null,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = _getAvailableCategories();
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
            // Header handle
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

            // Title & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingTransaction != null
                      ? 'Edit Transaction'
                      : 'Record Transaction',
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
            const SizedBox(height: 14),

            // Type Segmented Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _typeButton(
                    type: TransactionType.expense,
                    label: 'Expense',
                    activeColor: AppColors.expenseRed,
                  ),
                  _typeButton(
                    type: TransactionType.income,
                    label: 'Income',
                    activeColor: AppColors.incomeGreen,
                  ),
                  _typeButton(
                    type: TransactionType.transfer,
                    label: 'Transfer',
                    activeColor: AppColors.transferBlue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Amount Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _selectedType == TransactionType.expense
                      ? AppColors.expenseRed.withOpacity(0.3)
                      : (_selectedType == TransactionType.income
                          ? AppColors.incomeGreen.withOpacity(0.3)
                          : AppColors.transferBlue.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    currency,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _selectedType == TransactionType.expense
                          ? AppColors.expenseRed
                          : (_selectedType == TransactionType.income
                              ? AppColors.incomeGreen
                              : AppColors.transferBlue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      autofocus: widget.existingTransaction == null,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Title / Description
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title / Description (optional)',
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 16),

            // Category Picker (if not transfer)
            if (_selectedType != TransactionType.transfer) ...[
              const Text(
                'Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = availableCategories[index];
                    final isSelected = _selectedCategory?.id == cat.id;
                    return ChoiceChip(
                      selected: isSelected,
                      avatar: CircleAvatar(
                        backgroundColor: cat.color.withOpacity(0.2),
                        child: Icon(cat.iconData, size: 16, color: cat.color),
                      ),
                      label: Text(cat.name),
                      selectedColor: isDark
                          ? cat.color.withOpacity(0.3)
                          : cat.color.withOpacity(0.2),
                      side: BorderSide(
                        color: isSelected ? cat.color : Colors.transparent,
                        width: 1.5,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Transfer Destination Field
              TextField(
                controller: _transferToController,
                decoration: const InputDecoration(
                  labelText: 'Transfer To Account / Wallet',
                  prefixIcon: Icon(Icons.swap_horiz),
                  hintText: 'e.g. Bank Savings or Petty Cash',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Payment Method Selector
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PaymentMethod.values.map((method) {
                  final isSelected = _selectedPaymentMethod == method;
                  IconData icon;
                  switch (method) {
                    case PaymentMethod.cash:
                      icon = Icons.payments_outlined;
                      break;
                    case PaymentMethod.upi:
                      icon = Icons.qr_code_2;
                      break;
                    case PaymentMethod.debitCard:
                      icon = Icons.credit_card;
                      break;
                    case PaymentMethod.creditCard:
                      icon = Icons.credit_score;
                      break;
                    case PaymentMethod.bankTransfer:
                      icon = Icons.account_balance;
                      break;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      avatar: Icon(
                        icon,
                        size: 16,
                        color: isSelected
                            ? Colors.black
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      label: Text(method.displayName),
                      selectedColor: AppColors.primaryMint,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : (isDark ? Colors.white : Colors.black),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        setState(() => _selectedPaymentMethod = method);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Date Picker Row
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
                    const Icon(Icons.calendar_today,
                        size: 18, color: AppColors.primaryMint),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Optional Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 24),

            // Save / Update Button
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
                widget.existingTransaction != null
                    ? 'Save Changes'
                    : 'Add ${_selectedType.name.toUpperCase()}',
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

  Widget _typeButton({
    required TransactionType type,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
