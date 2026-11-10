import 'dart:math' as math;

/// Uma série executada dentro de um treino.
class WorkoutSet {
  const WorkoutSet({
    this.id,
    required this.setNumber,
    required this.reps,
    required this.weight,
  });

  final int? id;
  final int setNumber;
  final int reps;

  /// Carga em kg.
  final double weight;

  double get volume => reps * weight;

  /// 1RM estimado pela fórmula de Epley: carga × (1 + reps / 30).
  /// Com 1 repetição, o 1RM é a própria carga.
  double get estimatedOneRepMax =>
      reps <= 1 ? weight : weight * (1 + reps / 30);

  factory WorkoutSet.fromMap(Map<String, Object?> map) => WorkoutSet(
    id: map['id'] as int,
    setNumber: map['set_number'] as int,
    reps: map['reps'] as int,
    weight: (map['weight'] as num).toDouble(),
  );

  Map<String, Object?> toMap(int workoutId) => {
    'workout_id': workoutId,
    'set_number': setNumber,
    'reps': reps,
    'weight': weight,
  };
}

/// Registro de treino de um exercício em uma data, com suas séries.
class Workout {
  const Workout({
    this.id,
    required this.userId,
    required this.exerciseId,
    this.exerciseName = '',
    required this.date,
    this.notes,
    required this.sets,
  });

  final int? id;
  final int userId;
  final int exerciseId;

  /// Preenchido via JOIN ao ler do banco.
  final String exerciseName;
  final DateTime date;
  final String? notes;
  final List<WorkoutSet> sets;

  double get maxWeight =>
      sets.isEmpty ? 0 : sets.map((s) => s.weight).reduce(math.max);

  /// Maior 1RM estimado entre as séries — usado para detectar recordes,
  /// pois considera carga e repetições (80 kg × 12 supera 80 kg × 8).
  double get bestOneRepMax =>
      sets.isEmpty ? 0 : sets.map((s) => s.estimatedOneRepMax).reduce(math.max);

  double get totalVolume => sets.fold(0, (sum, s) => sum + s.volume);

  int get totalReps => sets.fold(0, (sum, s) => sum + s.reps);

  Workout copyWith({int? id, List<WorkoutSet>? sets}) => Workout(
    id: id ?? this.id,
    userId: userId,
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    date: date,
    notes: notes,
    sets: sets ?? this.sets,
  );

  factory Workout.fromMap(Map<String, Object?> map, List<WorkoutSet> sets) =>
      Workout(
        id: map['id'] as int,
        userId: map['user_id'] as int,
        exerciseId: map['exercise_id'] as int,
        exerciseName: (map['exercise_name'] as String?) ?? '',
        date: DateTime.parse(map['date'] as String),
        notes: map['notes'] as String?,
        sets: sets,
      );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'exercise_id': exerciseId,
    'date': date.toIso8601String(),
    'notes': notes,
  };
}
