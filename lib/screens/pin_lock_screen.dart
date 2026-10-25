import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class PinLockScreen extends StatefulWidget {
  final AppState appState;
  final Widget child;

  const PinLockScreen({
    super.key,
    required this.appState,
    required this.child,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';
  String? _errorMessage;

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _verifyPin() {
    final success = widget.appState.unlockWithPin(_enteredPin);
    if (!success) {
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
        _enteredPin = '';
      });
    }
  }

  void _showForgotPinDialog() {
    final question = widget.appState.settings.securityQuestion ??
        'What is your favorite color?';
    final answerController = TextEditingController();
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: AppColors.primaryMint),
              SizedBox(width: 10),
              Text('Reset PIN', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Answer your security question to unlock the application:',
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: answerController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter your answer',
                  errorText: dialogError,
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
                backgroundColor: AppColors.primaryMint,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final ok = widget.appState
                    .unlockWithSecurityAnswer(answerController.text);
                if (ok) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('App unlocked successfully! You can change your PIN in Settings.'),
                    ),
                  );
                } else {
                  setDialogState(() {
                    dialogError = 'Incorrect answer.';
                  });
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.appState.isLocked) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryMint.withOpacity(0.2),
                    AppColors.primaryCyan.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: AppColors.primaryMint.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 56,
                color: AppColors.primaryMint,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PocketLedger',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your 4-digit PIN to access records',
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: isFilled ? 18 : 14,
                  height: isFilled ? 18 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? AppColors.primaryMint
                        : Colors.transparent,
                    border: Border.all(
                      color: isFilled
                          ? AppColors.primaryMint
                          : AppColors.darkBorder,
                      width: 2,
                    ),
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: AppColors.primaryMint.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.expenseRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const Spacer(flex: 2),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['reset', '0', 'delete'],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map((key) {
                          if (key == 'reset') {
                            return SizedBox(
                              width: 72,
                              height: 72,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.help_outline,
                                  color: AppColors.darkTextSecondary,
                                  size: 26,
                                ),
                                onPressed: _showForgotPinDialog,
                              ),
                            );
                          }
                          if (key == 'delete') {
                            return SizedBox(
                              width: 72,
                              height: 72,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.backspace_outlined,
                                  color: AppColors.darkTextSecondary,
                                  size: 26,
                                ),
                                onPressed: _onDeletePressed,
                              ),
                            );
                          }
                          return InkWell(
                            onTap: () => _onDigitPressed(key),
                            borderRadius: BorderRadius.circular(36),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.darkElevated,
                                border: Border.all(
                                  color: AppColors.darkBorder.withOpacity(0.5),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                key,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            TextButton(
              onPressed: _showForgotPinDialog,
              child: const Text(
                'Forgot PIN?',
                style: TextStyle(
                  color: AppColors.primaryMint,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
