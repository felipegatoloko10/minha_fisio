import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final IAuthRepository _repository;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _isLoading = false;
  String? _error;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;

  AuthController(this._repository) {
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      bool canCheck = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();
      _isBiometricAvailable = canCheck && isDeviceSupported;
      _isBiometricEnabled = await _repository.isBiometricEnabled();
      notifyListeners();
    } catch (e) {
      print("Erro ao verificar biometria: $e");
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final user = await _repository.loginUser(email, password);
      if (user == null) {
        _error = "E-mail ou senha incorretos";
      }
      return user;
    } catch (e) {
      _error = "Erro ao realizar login: $e";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> loginWithBiometrics() async {
    if (!_isBiometricAvailable || !_isBiometricEnabled) return null;

    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Toque no sensor para entrar',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );

      if (authenticated) {
        String? lastEmail = await _repository.getLastUserEmail();
        if (lastEmail != null) {
          _isLoading = true;
          notifyListeners();
          final user = await _repository.getUserByEmail(lastEmail);
          _isLoading = false;
          notifyListeners();
          return user;
        }
      }
    } catch (e) {
      _error = "Erro na autenticação biométrica: $e";
      notifyListeners();
    }
    return null;
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool success = await _repository.registerUser({
        'name': name,
        'email': email,
        'password': password
      });
      if (!success) {
        _error = "Erro ao cadastrar usuário. Tente outro e-mail.";
      }
      return success;
    } catch (e) {
      _error = "Erro no cadastro: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleBiometrics(bool enabled, String email) async {
    await _repository.setBiometricEnabled(enabled, email);
    _isBiometricEnabled = enabled;
    notifyListeners();
  }
}
