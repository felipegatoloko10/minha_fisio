import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static const String _dbName = 'minha_fisio.db';
  static const int _dbVersion = 3; // Incrementing version for salt migration

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onUpgrade: _onUpgrade,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        salt TEXT
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE treatments ADD COLUMN start_date TEXT');
    }
    if (oldVersion < 3) {
      // Adding salt column for security upgrade
      try {
        await db.execute('ALTER TABLE users ADD COLUMN salt TEXT');
      } catch (e) {
        // Column might already exist if tested before, ignore
      }
    }
  }
}
