import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/workout.dart';

class WorkoutRepository {
  WorkoutRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  /// Todos os treinos do usuário, do mais recente para o mais antigo.
  Future<List<Workout>> getByUser(int userId) async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      '''
      SELECT w.*, e.name AS exercise_name
      FROM workouts w
      JOIN exercises e ON e.id = w.exercise_id
      WHERE w.user_id = ?
      ORDER BY w.date DESC, w.id DESC
    ''',
      [userId],
    );

    final setRows = await db.rawQuery(
      '''
      SELECT s.* FROM workout_sets s
      JOIN workouts w ON w.id = s.workout_id
      WHERE w.user_id = ?
      ORDER BY s.workout_id, s.set_number
    ''',
      [userId],
    );

    final setsByWorkout = <int, List<WorkoutSet>>{};
    for (final row in setRows) {
      setsByWorkout
          .putIfAbsent(row['workout_id'] as int, () => [])
          .add(WorkoutSet.fromMap(row));
    }
    return rows
        .map((r) => Workout.fromMap(r, setsByWorkout[r['id']] ?? const []))
        .toList();
  }

  Future<int> insert(Workout workout) async {
    final db = await _appDatabase.database;
    return db.transaction((txn) async {
      final id = await txn.insert('workouts', workout.toMap());
      await _insertSets(txn, id, workout.sets);
      return id;
    });
  }

  Future<void> update(Workout workout) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await txn.update(
        'workouts',
        workout.toMap(),
        where: 'id = ? AND user_id = ?',
        whereArgs: [workout.id, workout.userId],
      );
      await txn.delete(
        'workout_sets',
        where: 'workout_id = ?',
        whereArgs: [workout.id],
      );
      await _insertSets(txn, workout.id!, workout.sets);
    });
  }

  Future<void> delete(int id, {required int userId}) async {
    final db = await _appDatabase.database;
    await db.delete(
      'workouts',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> _insertSets(
    Transaction txn,
    int workoutId,
    List<WorkoutSet> sets,
  ) async {
    final batch = txn.batch();
    for (final (index, set) in sets.indexed) {
      batch.insert('workout_sets', {
        ...set.toMap(workoutId),
        'set_number': index + 1,
      });
    }
    await batch.commit(noResult: true);
  }
}
