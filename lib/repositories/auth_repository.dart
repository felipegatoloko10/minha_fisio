import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/security/security_helper.dart';

abstract class IAuthRepository {
  Future<Map<String, dynamic>?> loginUser(String email, String password);
  Future<bool> registerUser(Map<String, String> user);
  Future<Map<String, dynamic>?> getUserByEmail(String email);
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled, String email);
  Future<String?> getLastUserEmail();
}

class AuthRepository implements IAuthRepository {
  final Database _db;
  final SharedPreferences _prefs;
  
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastUserEmailKey = 'last_user_email';

  AuthRepository(this._db, this._prefs);

  @override
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final List<Map<String, dynamic>> results = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (results.isEmpty) return null;

    final user = results.first;
    final storedPassword = user['password'] as String;
    final storedSalt = user['salt'] as String?;

    // Modo Seguro (Com Salt)
    if (storedSalt != null) {
      final inputHash = SecurityHelper.hashPassword(password, storedSalt);
      if (inputHash == storedPassword) {
        return user;
      }
    } 
    // Modo Legado/Migração (Sem Salt)
    else {
      // Tenta hash antigo (apenas senha)
      final oldHash = SecurityHelper.hashPassword(password, ""); // Hash simples SHA256 do StorageService antigo era apenas sha256(utf8.encode(password)) - espera, StorageService usava sha256 puro?
      // Revisando StorageService anterior: sim, sha256.convert(utf8.encode(password)).
      // O SecurityHelper.hashPassword(pass, salt) faz sha256(utf8.encode(pass + salt)).
      // Se eu passar salt vazio "", é sha256(utf8.encode(pass)). Correto.
      
      final simpleHash = SecurityHelper.hashPassword(password, "");
      
      if (storedPassword == simpleHash || storedPassword == password) {
        // Migrar para Saltado
        final newSalt = SecurityHelper.generateSalt();
        final newHash = SecurityHelper.hashPassword(password, newSalt);
        
        await _db.update(
          'users',
          {'password': newHash, 'salt': newSalt},
          where: 'id = ?',
          whereArgs: [user['id']],
        );
        
        // Retorna user atualizado
        return {...user, 'password': newHash, 'salt': newSalt};
      }
    }
    
    return null;
  }

  @override
  Future<bool> registerUser(Map<String, String> user) async {
    try {
      final salt = SecurityHelper.generateSalt();
      final password = user['password']!;
      final hashedPassword = SecurityHelper.hashPassword(password, salt);

      await _db.insert('users', {
        'name': user['name'],
        'email': user['email'],
        'password': hashedPassword, // Agora hash com salt
        'salt': salt,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final List<Map<String, dynamic>> results = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  @override
  Future<bool> isBiometricEnabled() async {
    return _prefs.getBool(_biometricEnabledKey) ?? false;
  }

  @override
  Future<void> setBiometricEnabled(bool enabled, String email) async {
    await _prefs.setBool(_biometricEnabledKey, enabled);
    if (enabled) {
      await _prefs.setString(_lastUserEmailKey, email);
    }
  }

  @override
  Future<String?> getLastUserEmail() async {
    return _prefs.getString(_lastUserEmailKey);
  }
}
