import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/financial_record_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AddFinancialRecordDialog extends StatefulWidget {
  final AppState appState;
  final FinancialRecordItem? existingRecord;

  const AddFinancialRecordDialog({
    super.key,
    required this.appState,
    this.existingRecord,
  });

  static Future<void> show(
    BuildContext context,
    AppState appState, {
    FinancialRecordItem? existingRecord,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddFinancialRecordDialog(
        appState: appState,
        existingRecord: existingRecord,
      ),
    );
  }

  @override
  State<AddFinancialRecordDialog> createState() =>
      _AddFinancialRecordDialogState();
}

class _AddFinancialRecordDialogState extends State<AddFinancialRecordDialog> {
  late TextEditingController _titleController;
  late TextEditingController _institutionController;
  late TextEditingController _principalController;
  late TextEditingController _interestRateController;
  late TextEditingController _maturityAmountController;
  late TextEditingController _accountNumberController;
  late TextEditingController _notesController;

  late FinancialRecordType _selectedType;
  late DateTime _startDate;
  late DateTime _maturityDate;

  @override
  void initState() {
    super.initState();
    final r = widget.existingRecord;
    _titleController = TextEditingController(text: r?.title ?? '');
    _institutionController = TextEditingController(text: r?.institution ?? '');
    _principalController = TextEditingController(
      text: r != null
          ? r.principalOrPremium.toStringAsFixed(
              r.principalOrPremium.truncateToDouble() == r.principalOrPremium ? 0 : 2)
          : '',
    );
    _interestRateController = TextEditingController(
      text: r?.interestRate != null ? r!.interestRate.toString() : '',
    );
    _maturityAmountController = TextEditingController(
      text: r?.maturityAmount != null
          ? r!.maturityAmount!.toStringAsFixed(
              r.maturityAmount!.truncateToDouble() == r.maturityAmount ? 0 : 2)
          : '',
    );
    _accountNumberController =
        TextEditingController(text: r?.policyOrAccountNumber ?? '');
    _notesController = TextEditingController(text: r?.notes ?? '');

    _selectedType = r?.type ?? FinancialRecordType.fixedDeposit;
    _startDate = r?.startDate ?? DateTime.now();
    _maturityDate =
        r?.maturityOrRenewalDate ?? DateTime.now().add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _institutionController.dispose();
    _principalController.dispose();
    _interestRateController.dispose();
    _maturityAmountController.dispose();
    _accountNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _maturityDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
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
        if (isStart) {
          _startDate = picked;
        } else {
          _maturityDate = picked;
        }
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final institution = _institutionController.text.trim();
    final principal = double.tryParse(_principalController.text.trim());
    final interestRate = double.tryParse(_interestRateController.text.trim());
    final maturityAmount =
        double.tryParse(_maturityAmountController.text.trim());

    // Validation
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a record title')),
      );
      return;
    }

    if (title.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title must be at least 3 characters')),
      );
      return;
    }

    if (institution.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an institution name')),
      );
      return;
    }

    if (principal == null || principal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid principal or premium greater than 0')),
      );
      return;
    }

    if (principal > 100000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Principal amount seems too large. Please verify.')),
      );
      return;
    }

    if (interestRate != null && (interestRate < 0 || interestRate > 100)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interest rate must be between 0 and 100%')),
      );
      return;
    }

    if (_maturityDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maturity date must be after start date')),
      );
      return;
    }

    if (widget.existingRecord != null) {
      final updated = widget.existingRecord!.copyWith(
        title: title,
        type: _selectedType,
        institution: institution,
        principalOrPremium: principal,
        interestRate: interestRate,
        maturityAmount: maturityAmount,
        startDate: _startDate,
        maturityOrRenewalDate: _maturityDate,
        policyOrAccountNumber: _accountNumberController.text.trim().isNotEmpty
            ? _accountNumberController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      widget.appState.updateFinancialRecord(updated);
    } else {
      widget.appState.addFinancialRecord(
        title: title,
        type: _selectedType,
        institution: institution,
        principalOrPremium: principal,
        interestRate: interestRate,
        maturityAmount: maturityAmount,
        startDate: _startDate,
        maturityOrRenewalDate: _maturityDate,
        policyOrAccountNumber: _accountNumberController.text.trim().isNotEmpty
            ? _accountNumberController.text.trim()
            : null,
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
                  widget.existingRecord != null
                      ? 'Edit Financial Record'
                      : 'Add Financial Record',
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

            // Record Type Dropdown
            DropdownButtonFormField<FinancialRecordType>(
              value: _selectedType,
              dropdownColor: isDark ? AppColors.darkCard : Colors.white,
              decoration: const InputDecoration(
                labelText: 'Record Category',
                prefixIcon: Icon(Icons.account_balance),
              ),
              items: FinancialRecordType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.displayName),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title / Scheme Name',
                hintText: 'e.g. SBI 1-Year FD, LIC Term Insurance',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Institution
            TextField(
              controller: _institutionController,
              decoration: const InputDecoration(
                labelText: 'Bank / Financial Institution',
                hintText: 'e.g. HDFC Bank, Post Office, Max Life',
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Principal / Premium
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _principalController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _selectedType == FinancialRecordType.insurancePolicy
                          ? 'Annual Premium'
                          : 'Principal Amount',
                      prefixText: '$currency ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _interestRateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Interest Rate',
                      suffixText: '%',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Maturity Amount & Account Number
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _maturityAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Expected Maturity ($currency)',
                      prefixText: '$currency ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _accountNumberController,
                    decoration: const InputDecoration(
                      labelText: 'FD/Policy Number',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dates (Start Date and Maturity Date)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isStart: true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkElevated
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkTextSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(_startDate),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isStart: false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkElevated
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Maturity Date',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkTextSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(_maturityDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryMint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                widget.existingRecord != null ? 'Update Record' : 'Save Record',
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
