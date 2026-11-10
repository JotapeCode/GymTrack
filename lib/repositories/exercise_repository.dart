import '../database/app_database.dart';
import '../models/exercise.dart';

class ExerciseRepository {
  ExerciseRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<Exercise>> getByUser(int userId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'exercises',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Exercise.fromMap).toList();
  }

  Future<Exercise> insert(Exercise exercise) async {
    final db = await _appDatabase.database;
    final id = await db.insert('exercises', exercise.toMap());
    return exercise.copyWith(id: id);
  }

  Future<void> update(Exercise exercise) async {
    final db = await _appDatabase.database;
    await db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [exercise.id, exercise.userId],
    );
  }

  /// Remove o exercício e, em cascata, seus treinos e séries.
  Future<void> delete(int id, {required int userId}) async {
    final db = await _appDatabase.database;
    await db.delete(
      'exercises',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
}
