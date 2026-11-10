import 'package:flutter/foundation.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/workout_repository.dart';

/// Comparação de um treino com o registro anterior do mesmo exercício.
class WorkoutComparison {
  const WorkoutComparison({this.previous, required this.isPersonalRecord});

  final Workout? previous;
  final bool isPersonalRecord;

  bool get hasPrevious => previous != null;
}

extension WorkoutComparisonX on WorkoutComparison {
  double weightDelta(Workout current) =>
      previous == null ? 0 : current.maxWeight - previous!.maxWeight;
}

/// Evolução de um exercício entre o primeiro e o último treino.
class ExerciseEvolution {
  const ExerciseEvolution({
    required this.exercise,
    required this.firstWeight,
    required this.lastWeight,
    required this.bestWeight,
    required this.sessions,
  });

  final Exercise exercise;
  final double firstWeight;
  final double lastWeight;
  final double bestWeight;
  final int sessions;

  double get delta => lastWeight - firstWeight;
  double get percent => firstWeight == 0 ? 0 : delta / firstWeight * 100;
}

/// Estado dos exercícios e treinos do usuário logado.
class TrainingController extends ChangeNotifier {
  TrainingController(this._exerciseRepo, this._workoutRepo);

  final ExerciseRepository _exerciseRepo;
  final WorkoutRepository _workoutRepo;

  int? _userId;
  List<Exercise> _exercises = const [];
  List<Workout> _workouts = const [];
  bool _isLoading = false;

  List<Exercise> get exercises => _exercises;

  /// Ordenados do mais recente para o mais antigo.
  List<Workout> get workouts => _workouts;
  bool get isLoading => _isLoading;
  int? get userId => _userId;

  Future<void> loadForUser(int userId) async {
    _userId = userId;
    _isLoading = true;
    notifyListeners();
    try {
      await _reload();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _userId = null;
    _exercises = const [];
    _workouts = const [];
    notifyListeners();
  }

  Future<void> _reload() async {
    final id = _userId;
    if (id == null) return;
    final results = await Future.wait([
      _exerciseRepo.getByUser(id),
      _workoutRepo.getByUser(id),
    ]);
    _exercises = results[0] as List<Exercise>;
    _workouts = results[1] as List<Workout>;
  }

  Future<void> _mutate(Future<void> Function() action) async {
    await action();
    await _reload();
    notifyListeners();
  }

  // ---------- Exercícios ----------

  Future<Exercise> saveExercise(Exercise exercise) async {
    late Exercise saved;
    await _mutate(() async {
      if (exercise.id == null) {
        saved = await _exerciseRepo.insert(exercise);
      } else {
        await _exerciseRepo.update(exercise);
        saved = exercise;
      }
    });
    return saved;
  }

  Future<void> deleteExercise(Exercise exercise) => _mutate(
    () => _exerciseRepo.delete(exercise.id!, userId: exercise.userId),
  );

  Exercise? exerciseById(int id) {
    for (final e in _exercises) {
      if (e.id == id) return e;
    }
    return null;
  }

  // ---------- Treinos ----------

  Future<void> saveWorkout(Workout workout) => _mutate(() async {
    if (workout.id == null) {
      await _workoutRepo.insert(workout);
    } else {
      await _workoutRepo.update(workout);
    }
  });

  Future<void> deleteWorkout(Workout workout) =>
      _mutate(() => _workoutRepo.delete(workout.id!, userId: workout.userId));

  /// Treinos de um exercício em ordem cronológica (antigo → recente).
  List<Workout> workoutsFor(int exerciseId) => _workouts
      .where((w) => w.exerciseId == exerciseId)
      .toList()
      .reversed
      .toList();

  int workoutCountFor(int exerciseId) =>
      _workouts.where((w) => w.exerciseId == exerciseId).length;

  Workout? lastWorkoutFor(int exerciseId) {
    for (final w in _workouts) {
      if (w.exerciseId == exerciseId) return w;
    }
    return null;
  }

  Workout? get lastWorkout => _workouts.isEmpty ? null : _workouts.first;

  /// Compara com o treino imediatamente anterior do mesmo exercício.
  WorkoutComparison compare(Workout workout) {
    final history = workoutsFor(workout.exerciseId);
    final index = history.indexWhere((w) => w.id == workout.id);
    if (index <= 0) {
      return const WorkoutComparison(isPersonalRecord: false);
    }
    final earlier = history.sublist(0, index);
    return WorkoutComparison(
      previous: earlier.last,
      isPersonalRecord: isRecordOver(workout, earlier),
    );
  }

  /// Recorde pessoal: 1RM estimado maior que o de todos os treinos anteriores.
  /// Uma pequena tolerância evita falsos recordes por arredondamento.
  static bool isRecordOver(Workout workout, Iterable<Workout> earlier) {
    if (earlier.isEmpty) return false;
    final bestBefore = earlier
        .map((w) => w.bestOneRepMax)
        .reduce((a, b) => a > b ? a : b);
    return workout.bestOneRepMax > bestBefore + 0.01;
  }

  /// Maior 1RM estimado já registrado para o exercício.
  double bestOneRepMaxFor(int exerciseId) => _workouts
      .where((w) => w.exerciseId == exerciseId)
      .fold(0, (best, w) => w.bestOneRepMax > best ? w.bestOneRepMax : best);

  /// Quantidade de dias distintos com treino.
  int get trainingDays => _workouts
      .map((w) => DateTime(w.date.year, w.date.month, w.date.day))
      .toSet()
      .length;

  int get workoutsThisWeek {
    final limit = DateTime.now().subtract(const Duration(days: 7));
    return _workouts.where((w) => w.date.isAfter(limit)).length;
  }

  /// Exercícios ordenados pelo treino mais recente.
  List<Exercise> get recentExercises {
    final seen = <int>{};
    final result = <Exercise>[];
    for (final w in _workouts) {
      if (seen.add(w.exerciseId)) {
        final e = exerciseById(w.exerciseId);
        if (e != null) result.add(e);
      }
    }
    for (final e in _exercises) {
      if (!seen.contains(e.id)) result.add(e);
    }
    return result;
  }

  List<ExerciseEvolution> get evolutions {
    final list = <ExerciseEvolution>[];
    for (final e in _exercises) {
      final history = workoutsFor(e.id!);
      if (history.isEmpty) continue;
      list.add(
        ExerciseEvolution(
          exercise: e,
          firstWeight: history.first.maxWeight,
          lastWeight: history.last.maxWeight,
          bestWeight: history
              .map((w) => w.maxWeight)
              .reduce((a, b) => a > b ? a : b),
          sessions: history.length,
        ),
      );
    }
    list.sort((a, b) => b.percent.compareTo(a.percent));
    return list;
  }
}
