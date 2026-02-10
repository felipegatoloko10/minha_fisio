import 'package:sqflite/sqflite.dart';
import '../models/treatment_model.dart';
import '../services/storage_service.dart'; // Mantendo por enquanto para acesso ao DB

abstract class ITreatmentRepository {
  Future<List<TreatmentModel>> getTreatments();
  Future<void> addTreatment(TreatmentModel treatment);
  Future<void> updateTreatment(TreatmentModel treatment);
  Future<void> deleteTreatment(int id);
}

class TreatmentRepository implements ITreatmentRepository {
  final Database _db;

  TreatmentRepository(this._db);

  @override
  Future<List<TreatmentModel>> getTreatments() async {
    final List<Map<String, dynamic>> maps = await _db.query('treatments');

    if (maps.isEmpty) return [];

    return List.generate(maps.length, (i) {
      return TreatmentModel.fromMap(maps[i]);
    });
  }

  @override
  Future<void> addTreatment(TreatmentModel treatment) async {
    await _db.insert(
      'treatments',
      treatment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateTreatment(TreatmentModel treatment) async {
    await _db.update(
      'treatments',
      treatment.toMap(),
      where: 'id = ?',
      whereArgs: [treatment.id],
    );
  }

  @override
  Future<void> deleteTreatment(int id) async {
    await _db.delete(
      'treatments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
