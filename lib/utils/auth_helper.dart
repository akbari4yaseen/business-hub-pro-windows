import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../database/user_dao.dart';
import '../database/database_helper.dart';

class AuthHelper {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } on PlatformException catch (e) {
      // Handle platform-specific exceptions if needed
      print('Authentication error: ${e.message}');
      return false;
    }
  }

  Future<bool> authenticateWithFallback(
      String reason, String fallbackPassword) async {
    final isBiometricAuthenticated = await authenticate(reason);
    if (isBiometricAuthenticated) {
      return true;
    }

    // Fallback to password validation
    final db = await DatabaseHelper().database;
    final userDao = UserDao(db);
    final isPasswordValid = await userDao.validate(fallbackPassword);
    return isPasswordValid;
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }
}
