import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  static String hashPin(String pin) {
    final bytes = utf8.encode('pocketledger_salt_$pin');
    return sha256.convert(bytes).toString();
  }

  static bool verifyPin(String enteredPin, String storedHash) {
    final hash = hashPin(enteredPin);
    return hash == storedHash;
  }

  static String hashAnswer(String answer) {
    final normalized = answer.trim().toLowerCase();
    final bytes = utf8.encode('pocketledger_salt_$normalized');
    return sha256.convert(bytes).toString();
  }

  static bool verifyAnswer(String enteredAnswer, String storedHash) {
    final hash = hashAnswer(enteredAnswer);
    return hash == storedHash;
  }
}
