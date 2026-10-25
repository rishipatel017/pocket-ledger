import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  static const int _maxPinAttempts = 5;
  static const int _lockoutDurationMinutes = 5;
  
  static int _failedAttempts = 0;
  static DateTime? _lockoutUntil;

  static String hashPin(String pin) {
    // Use a more secure salt approach with multiple iterations
    final salt = 'pocketledger_secure_salt_2024';
    final bytes = utf8.encode('$salt$pin');
    final hash = sha256.convert(bytes);
    
    // Add additional iterations for security
    final iterations = 10000;
    var result = hash.toString();
    for (int i = 0; i < iterations; i++) {
      final iterBytes = utf8.encode('$result$i');
      result = sha256.convert(iterBytes).toString();
    }
    
    return result;
  }

  static bool verifyPin(String enteredPin, String storedHash) {
    // Check if locked out
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      return false;
    }
    
    // Reset attempts if lockout period has passed
    if (_lockoutUntil != null && DateTime.now().isAfter(_lockoutUntil!)) {
      _failedAttempts = 0;
      _lockoutUntil = null;
    }
    
    final hash = hashPin(enteredPin);
    final isValid = hash == storedHash;
    
    if (!isValid) {
      _failedAttempts++;
      
      // Lock out after max attempts
      if (_failedAttempts >= _maxPinAttempts) {
        _lockoutUntil = DateTime.now().add(Duration(minutes: _lockoutDurationMinutes));
      }
    } else {
      // Reset on successful attempt
      _failedAttempts = 0;
      _lockoutUntil = null;
    }
    
    return isValid;
  }

  static int get remainingAttempts => _maxPinAttempts - _failedAttempts;
  
  static DateTime? get lockoutUntil => _lockoutUntil;
  
  static bool get isLockedOut => _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  
  static Duration get lockoutRemainingDuration {
    if (_lockoutUntil == null) return Duration.zero;
    final remaining = _lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static String hashAnswer(String answer) {
    final normalized = answer.trim().toLowerCase();
    final salt = 'pocketledger_answer_salt_2024';
    final bytes = utf8.encode('$salt$normalized');
    return sha256.convert(bytes).toString();
  }

  static bool verifyAnswer(String enteredAnswer, String storedHash) {
    final hash = hashAnswer(enteredAnswer);
    return hash == storedHash;
  }
  
  static void resetAttempts() {
    _failedAttempts = 0;
    _lockoutUntil = null;
  }
}
