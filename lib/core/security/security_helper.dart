import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class SecurityHelper {
  static String generateSalt([int length = 16]) {
    final rand = Random.secure();
    final codeUnits = List.generate(length, (index) {
      return rand.nextInt(33) + 89; // ASCII chars
    });
    return String.fromCharCodes(codeUnits);
  }

  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
