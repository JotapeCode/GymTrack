import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/controllers/training_controller.dart';
import 'package:meu_app/database/app_database.dart';
import 'package:meu_app/database/database_seeder.dart';
import 'package:meu_app/models/app_user.dart';
import 'package:meu_app/models/exercise.dart';
import 'package:meu_app/models/muscle_group.dart';
import 'package:meu_app/models/workout.dart';
import 'package:meu_app/repositories/app_exception.dart';
import 'package:meu_app/repositories/exercise_repository.dart';
import 'package:meu_app/repositories/user_repository.dart';
import 'package:meu_app/repositories/workout_repository.dart';
import 'package:meu_app/services/password_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase db;
  late UserRepository users;
  late ExerciseRepository exercises;
  late WorkoutRepository workouts;

  setUp(() {
    final passwords = PasswordService(iterations: 10);
    db = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      passwordService: passwords,
      seedDemoData: false,
    );
    users = UserRepository(db, passwords);
    exercises = ExerciseRepository(db);
    workouts = WorkoutRepository(db);
  });

  tearDown(() => db.close());

  group('UserRepository', () {
    test('autentica o administrador inicial', () async {
      final admin = await users.authenticate(
        SeedCredentials.adminEmail,
        SeedCredentials.adminPassword,
      );
      expect(admin.isAdmin, isTrue);
    });

    test('rejeita senha incorreta', () {
      expect(
        users.authenticate(SeedCredentials.adminEmail, 'errada'),
        throwsA(isA<AppException>()),
      );
    });

    test('não salva a senha em texto puro', () async {
      final raw = await (await db.database).query('users');
      for (final row in raw) {
        expect(row['password_hash'], isNot(SeedCredentials.adminPassword));
        expect(row['password_hash'], isNot(SeedCredentials.userPassword));
      }
    });

    test('impede excluir o último administrador ativo', () async {
      final admin = (await users.getAll()).firstWhere((u) => u.isAdmin);
      expect(() => users.delete(admin.id!), throwsA(isA<AppException>()));
      expect(
        () => users.update(admin.copyWith(role: UserRole.user)),
        throwsA(isA<AppException>()),
      );
    });

    test('bloqueia login de conta inativa e e-mail duplicado', () async {
      final created = await users.create(
        AppUser(
          name: 'Maria Teste',
          email: 'maria@teste.com',
          role: UserRole.user,
          createdAt: DateTime.now(),
        ),
        'senha123',
      );
      await users.update(created.copyWith(isActive: false));
      expect(
        users.authenticate('maria@teste.com', 'senha123'),
        throwsA(isA<AppException>()),
      );
      expect(
        () => users.create(created, 'outra123'),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('Treinos', () {
    test('CRUD de treino, comparação e exclusão em cascata', () async {
      final user = await users.authenticate(
        SeedCredentials.userEmail,
        SeedCredentials.userPassword,
      );
      final controller = TrainingController(exercises, workouts);
      await controller.loadForUser(user.id!);

      final supino = await controller.saveExercise(
        Exercise(
          userId: user.id!,
          name: 'Supino reto',
          muscleGroup: MuscleGroup.peito,
          date: DateTime(2026, 1, 1),
        ),
      );

      Workout session(DateTime date, double top) => Workout(
        userId: user.id!,
        exerciseId: supino.id!,
        date: date,
        sets: [
          const WorkoutSet(setNumber: 1, reps: 12, weight: 20),
          WorkoutSet(setNumber: 2, reps: 8, weight: top),
        ],
      );

      await controller.saveWorkout(session(DateTime(2026, 1, 2), 25));
      await controller.saveWorkout(session(DateTime(2026, 1, 5), 30));

      expect(controller.workouts, hasLength(2));
      final latest = controller.workouts.first;
      expect(latest.sets, hasLength(2));
      final cmp = controller.compare(latest);
      expect(cmp.isPersonalRecord, isTrue);
      expect(cmp.weightDelta(latest), 5);

      await controller.saveWorkout(
        latest.copyWith(
          sets: const [WorkoutSet(setNumber: 1, reps: 10, weight: 32.5)],
        ),
      );
      expect(controller.workouts.first.maxWeight, 32.5);
      expect(controller.workouts.first.sets, hasLength(1));

      await controller.deleteWorkout(controller.workouts.first);
      expect(controller.workouts, hasLength(1));

      await controller.deleteExercise(supino);
      expect(controller.exercises, isEmpty);
      expect(controller.workouts, isEmpty);
      final orphanSets = await (await db.database).query('workout_sets');
      expect(orphanSets, isEmpty);
    });
  });
}
