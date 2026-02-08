import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/treatment_model.dart';

class StorageService {
  static Database? _db;
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastUserEmailKey = 'last_user_email';

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'minha_fisio.db');
    return await openDatabase(
      path,
      version: 2, // Aumentei a versão para o upgrade
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE treatments ADD COLUMN start_date TEXT');
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE treatments(
            id INTEGER PRIMARY KEY,
            nome TEXT,
            profissional TEXT,
            total INTEGER,
            start_date TEXT,
            days_indices TEXT,
            sessions TEXT
          )
        ''');
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  static Future<bool> saveUser(Map<String, String> user) async {
    final db = await database;
    try {
      await db.insert('users', user);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setBiometricEnabled(bool enabled, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
    if (enabled) await prefs.setString(_lastUserEmailKey, email);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  static Future<String?> getLastUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastUserEmailKey);
  }

  static Future<void> addTreatment(TreatmentModel treatment) async {
    final db = await database;
    await db.insert('treatments', {
      'id': treatment.id,
      'nome': treatment.nome,
      'profissional': treatment.profissional,
      'total': treatment.total,
      'start_date': treatment.startDate.toIso8601String().split('T')[0],
      'days_indices': json.encode(treatment.daysIndices),
      'sessions': json.encode(treatment.sessions.map((s) => s.toMap()).toList()),
    });
  }

  static Future<List<TreatmentModel>> getTreatments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('treatments');
    return maps.map((m) => TreatmentModel.fromMap(m)).toList();
  }

  static Future<void> updateTreatment(TreatmentModel treatment) async {
    final db = await database;
    await db.update(
      'treatments',
      {
        'nome': treatment.nome,
        'profissional': treatment.profissional,
        'total': treatment.total,
        'start_date': treatment.startDate.toIso8601String().split('T')[0],
        'days_indices': json.encode(treatment.daysIndices),
        'sessions': json.encode(treatment.sessions.map((s) => s.toMap()).toList()),
      },
      where: 'id = ?',
      whereArgs: [treatment.id],
    );
  }

  static Future<void> deleteTreatment(int id) async {
    final db = await database;
    await db.delete('treatments', where: 'id = ?', whereArgs: [id]);
  }
}
