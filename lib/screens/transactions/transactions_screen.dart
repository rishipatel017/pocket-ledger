import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../state/app_state.dart';
import '../../models/transaction_item.dart';
import '../../theme/app_theme.dart';
import '../../dialogs/add_transaction_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  final AppState appState;

  const TransactionsScreen({super.key, required this.appState});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.appState.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildFilterModalSheet(ctx),
    );
  }

  Widget _buildFilterModalSheet(BuildContext ctx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
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
                  const Text(
                    'Filter Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.appState.clearAllFilters();
                      _searchController.clear();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Transaction Type
              const Text(
                'Transaction Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: widget.appState.filterType == null,
                    onSelected: (val) {
                      if (val) {
                        widget.appState.setFilterType(null);
                        setModalState(() {});
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Expense'),
                    selected:
                        widget.appState.filterType == TransactionType.expense,
                    selectedColor: AppColors.expenseRed.withOpacity(0.3),
                    onSelected: (val) {
                      widget.appState.setFilterType(
                          val ? TransactionType.expense : null);
                      setModalState(() {});
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Income'),
                    selected:
                        widget.appState.filterType == TransactionType.income,
                    selectedColor: AppColors.incomeGreen.withOpacity(0.3),
                    onSelected: (val) {
                      widget.appState.setFilterType(
                          val ? TransactionType.income : null);
                      setModalState(() {});
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Transfer'),
                    selected:
                        widget.appState.filterType == TransactionType.transfer,
                    selectedColor: AppColors.transferBlue.withOpacity(0.3),
                    onSelected: (val) {
                      widget.appState.setFilterType(
                          val ? TransactionType.transfer : null);
                      setModalState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Range Presets
              const Text(
                'Date Range',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _dateChip(DateFilterPreset.thisMonth, 'This Month', setModalState),
                  _dateChip(DateFilterPreset.thisWeek, 'This Week', setModalState),
                  _dateChip(DateFilterPreset.today, 'Today', setModalState),
                  _dateChip(DateFilterPreset.lastMonth, 'Last Month', setModalState),
                  _dateChip(DateFilterPreset.allTime, 'All Time', setModalState),
                ],
              ),
              const SizedBox(height: 16),

              // Payment Method Filter
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Methods'),
                    selected: widget.appState.filterPaymentMethod == null,
                    onSelected: (val) {
                      if (val) {
                        widget.appState.setFilterPaymentMethod(null);
                        setModalState(() {});
                      }
                    },
                  ),
                  ...PaymentMethod.values.map((method) {
                    final isSelected =
                        widget.appState.filterPaymentMethod == method;
                    return ChoiceChip(
                      label: Text(method.displayName),
                      selected: isSelected,
                      onSelected: (val) {
                        widget.appState.setFilterPaymentMethod(
                            val ? method : null);
                        setModalState(() {});
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMint,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateChip(
    DateFilterPreset preset,
    String label,
    void Function(void Function()) setModalState,
  ) {
    final isSelected = widget.appState.dateFilterPreset == preset;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryMint.withOpacity(0.3),
      onSelected: (val) {
        if (val) {
          widget.appState.setDateFilterPreset(preset);
          setModalState(() {});
        }
      },
    );
  }

  void _showTransactionDetails(TransactionItem tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = tx.type == TransactionType.expense;
    final isIncome = tx.type == TransactionType.income;
    final amountColor = isExpense
        ? AppColors.expenseRed
        : (isIncome ? AppColors.incomeGreen : AppColors.transferBlue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),

            // Top Icon & Amount
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpense
                          ? Icons.arrow_upward
                          : (isIncome ? Icons.arrow_downward : Icons.swap_horiz),
                      color: amountColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.appState.formatAmount(tx.amount,
                        showSign: true, isExpense: isExpense),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info rows
            _detailRow('Transaction Type', tx.type.name.toUpperCase()),
            _detailRow('Category', tx.categoryName),
            _detailRow('Payment Method', tx.paymentMethod.displayName),
            _detailRow(
              'Date & Time',
              DateFormat('dd MMMM yyyy, hh:mm a').format(tx.date),
            ),
            if (tx.transferToAccount != null)
              _detailRow('Transferred To', tx.transferToAccount!),
            if (tx.notes != null && tx.notes!.isNotEmpty)
              _detailRow('Notes', tx.notes!),

            const SizedBox(height: 28),

            // Actions: Edit and Delete
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.expenseRed,
                      side: const BorderSide(color: AppColors.expenseRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Delete'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(tx.id, tx.title);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMint,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Edit Entry'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AddTransactionDialog.show(context, widget.appState,
                          existingTransaction: tx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "$title"?'),
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
            onPressed: () {
              widget.appState.deleteTransaction(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Group transactions by date string
  Map<String, List<TransactionItem>> _groupTransactions(
      List<TransactionItem> list) {
    final map = <String, List<TransactionItem>>{};
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    for (final tx in list) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      String label;
      if (key == todayStr) {
        label = 'Today';
      } else if (key == yesterdayStr) {
        label = 'Yesterday';
      } else {
        label = DateFormat('EEEE, dd MMM yyyy').format(tx.date);
      }
      map.putIfAbsent(label, () => []).add(tx);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.appState.filteredTransactions;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grouped = _groupTransactions(filtered);

    final hasActiveFilters = widget.appState.filterType != null ||
        widget.appState.filterCategoryId != null ||
        widget.appState.filterPaymentMethod != null ||
        widget.appState.dateFilterPreset != DateFilterPreset.thisMonth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Filter',
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryMint,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Quick Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search title, category, note...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                widget.appState.setSearchQuery('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onChanged: (val) => widget.appState.setSearchQuery(val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: hasActiveFilters
                        ? AppColors.primaryMint.withOpacity(0.2)
                        : (isDark ? AppColors.darkElevated : Colors.grey.shade200),
                  ),
                  icon: Icon(
                    Icons.tune,
                    color: hasActiveFilters
                        ? AppColors.primaryMint
                        : AppColors.darkTextSecondary,
                  ),
                  onPressed: _showFilterModal,
                ),
              ],
            ),
          ),

          // Active filter banner (if any)
          if (hasActiveFilters)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryMint.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.primaryMint),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Filtered view active',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryMint,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.appState.clearAllFilters();
                      _searchController.clear();
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        color: AppColors.primaryMint,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Transaction Count / Total summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} transactions',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                Text(
                  widget.appState.dateFilterPreset == DateFilterPreset.thisMonth
                      ? 'This Month'
                      : widget.appState.dateFilterPreset.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkTextMuted,
                  ),
                ),
              ],
            ),
          ),

          // Grouped List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: AppColors.darkTextMuted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No transactions match your search/filter.',
                          style: TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, index) {
                      final groupHeader = grouped.keys.elementAt(index);
                      final items = grouped[groupHeader]!;

                      final dayTotalExpense = items
                          .where((t) => t.type == TransactionType.expense)
                          .fold<double>(0.0, (s, t) => s + t.amount);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Group header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  groupHeader,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkTextSecondary,
                                  ),
                                ),
                                if (dayTotalExpense > 0)
                                  Text(
                                    '-${widget.appState.formatAmount(dayTotalExpense)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.expenseRed,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Transaction tiles
                          ...items.map((tx) {
                            final isExpense = tx.type == TransactionType.expense;
                            final isIncome = tx.type == TransactionType.income;
                            final amountColor = isExpense
                                ? AppColors.expenseRed
                                : (isIncome
                                    ? AppColors.incomeGreen
                                    : AppColors.transferBlue);

                            return InkWell(
                              onTap: () => _showTransactionDetails(tx),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCard
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: amountColor.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isExpense
                                            ? Icons.shopping_bag_outlined
                                            : (isIncome
                                                ? Icons
                                                    .account_balance_wallet_outlined
                                                : Icons.swap_horiz),
                                        color: amountColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
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
                                                  color: AppColors
                                                      .darkTextSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? AppColors.darkElevated
                                                      : Colors.grey.shade200,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  tx.paymentMethod.displayName,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        AppColors.darkTextMuted,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          widget.appState.formatAmount(tx.amount,
                                              showSign: true,
                                              isExpense: isExpense),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: amountColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('hh:mm a').format(tx.date),
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
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
