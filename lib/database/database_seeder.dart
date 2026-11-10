import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';
import '../models/muscle_group.dart';
import '../services/password_service.dart';

/// Credenciais iniciais (também documentadas no README).
abstract final class SeedCredentials {
  static const adminEmail = 'admin@gymtrack.com';
  static const adminPassword = 'admin123';
  static const userEmail = 'usuario@gymtrack.com';
  static const userPassword = 'usuario123';
}

/// Popula o banco na primeira execução com um administrador,
/// um usuário comum e um histórico de demonstração.
class DatabaseSeeder {
  DatabaseSeeder(this._db, this._passwordService);

  final DatabaseExecutor _db;
  final PasswordService _passwordService;

  Future<void> seed({bool includeDemoData = true}) async {
    final adminId = await _insertUser(
      name: 'Administrador',
      email: SeedCredentials.adminEmail,
      password: SeedCredentials.adminPassword,
      role: UserRole.admin,
    );
    final userId = await _insertUser(
      name: 'João Atleta',
      email: SeedCredentials.userEmail,
      password: SeedCredentials.userPassword,
      role: UserRole.user,
    );
    if (!includeDemoData) return;

    await _seedTraining(userId, const [
      _DemoExercise(
        'Supino reto',
        MuscleGroup.peito,
        'Barra livre, pegada média.',
        [20, 22.5, 25, 25, 27.5, 30],
      ),
      _DemoExercise('Rosca direta', MuscleGroup.biceps, 'Barra W.', [
        10,
        10,
        12,
        12,
        14,
        14,
      ]),
      _DemoExercise(
        'Tríceps pulley',
        MuscleGroup.triceps,
        'Corda ou barra reta.',
        [15, 17.5, 17.5, 20, 22.5, 22.5],
      ),
      _DemoExercise(
        'Agachamento livre',
        MuscleGroup.pernas,
        'Amplitude completa.',
        [30, 35, 40, 40, 45, 50],
      ),
      _DemoExercise(
        'Puxada alta',
        MuscleGroup.costas,
        'Pegada aberta, puxar até o peito.',
        [35, 35, 40, 42.5, 45, 45],
      ),
    ]);
    await _seedTraining(adminId, const [
      _DemoExercise(
        'Desenvolvimento',
        MuscleGroup.ombros,
        'Halteres, sentado.',
        [12, 14, 14, 16],
      ),
      _DemoExercise('Supino reto', MuscleGroup.peito, null, [40, 42.5, 45, 50]),
    ]);
  }

  Future<int> _insertUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) {
    final hashed = _passwordService.hash(password);
    return _db.insert('users', {
      'name': name,
      'email': email,
      'password_hash': hashed.hash,
      'password_salt': hashed.salt,
      'role': role.name,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Cria um treino a cada 4 dias, terminando ontem, com carga progressiva.
  Future<void> _seedTraining(int userId, List<_DemoExercise> exercises) async {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    for (final (index, exercise) in exercises.indexed) {
      final sessions = exercise.topWeights.length;
      final firstDay = base.subtract(
        Duration(days: (sessions - 1) * 4 + 1 + index % 2),
      );
      final exerciseId = await _db.insert('exercises', {
        'user_id': userId,
        'name': exercise.name,
        'muscle_group': exercise.group.name,
        'description': exercise.description,
        'date': firstDay.toIso8601String(),
      });
      for (var s = 0; s < sessions; s++) {
        final top = exercise.topWeights[s];
        final date = firstDay.add(Duration(days: s * 4, hours: 18));
        final workoutId = await _db.insert('workouts', {
          'user_id': userId,
          'exercise_id': exerciseId,
          'date': date.toIso8601String(),
          'notes': s == sessions - 1 ? 'Ótima execução, subir carga!' : null,
        });
        final sets = [
          (12, _round(top * 0.7)),
          (10, _round(top * 0.85)),
          (8, top),
        ];
        for (final (i, (reps, weight)) in sets.indexed) {
          await _db.insert('workout_sets', {
            'workout_id': workoutId,
            'set_number': i + 1,
            'reps': reps,
            'weight': weight,
          });
        }
      }
    }
  }

  static double _round(double value) => (value * 2).round() / 2;
}

class _DemoExercise {
  const _DemoExercise(this.name, this.group, this.description, this.topWeights);

  final String name;
  final MuscleGroup group;
  final String? description;
  final List<double> topWeights;
}
