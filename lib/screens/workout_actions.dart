import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/training_controller.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../widgets/common.dart';
import 'exercise_detail_screen.dart';
import 'exercise_form_screen.dart';
import 'workout_form_screen.dart';

/// Ações de navegação reutilizadas por várias telas.
abstract final class WorkoutActions {
  static Future<void> openNewWorkout(BuildContext context, {int? exerciseId}) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkoutFormScreen(initialExerciseId: exerciseId),
        ),
      );

  static Future<void> openEditWorkout(BuildContext context, Workout workout) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WorkoutFormScreen(workout: workout)),
      );

  static Future<void> openExercise(BuildContext context, Exercise exercise) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExerciseDetailScreen(exerciseId: exercise.id!),
        ),
      );

  static Future<void> openExerciseForm(
    BuildContext context, {
    Exercise? exercise,
  }) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ExerciseFormScreen(exercise: exercise)),
  );

  static Future<void> deleteWorkout(
    BuildContext context,
    Workout workout,
  ) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Excluir registro?',
      message:
          'O treino de ${workout.exerciseName} será removido '
          'permanentemente.',
    );
    if (!confirmed || !context.mounted) return;
    await context.read<TrainingController>().deleteWorkout(workout);
    if (context.mounted) showAppSnackBar(context, 'Registro excluído.');
  }
}
