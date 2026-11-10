import 'muscle_group.dart';

class Exercise {
  const Exercise({
    this.id,
    required this.userId,
    required this.name,
    required this.muscleGroup,
    this.description,
    required this.date,
  });

  final int? id;
  final int userId;
  final String name;
  final MuscleGroup muscleGroup;
  final String? description;

  /// Data de cadastro / início do exercício no plano de treino.
  final DateTime date;

  Exercise copyWith({
    int? id,
    String? name,
    MuscleGroup? muscleGroup,
    String? description,
    DateTime? date,
  }) => Exercise(
    id: id ?? this.id,
    userId: userId,
    name: name ?? this.name,
    muscleGroup: muscleGroup ?? this.muscleGroup,
    description: description ?? this.description,
    date: date ?? this.date,
  );

  factory Exercise.fromMap(Map<String, Object?> map) => Exercise(
    id: map['id'] as int,
    userId: map['user_id'] as int,
    name: map['name'] as String,
    muscleGroup: MuscleGroup.fromName(map['muscle_group'] as String),
    description: map['description'] as String?,
    date: DateTime.parse(map['date'] as String),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'name': name,
    'muscle_group': muscleGroup.name,
    'description': description,
    'date': date.toIso8601String(),
  };
}
