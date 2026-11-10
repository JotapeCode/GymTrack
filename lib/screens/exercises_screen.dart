import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/training_controller.dart';
import '../models/muscle_group.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'workout_actions.dart';

/// Aba "Treinos": exercícios cadastrados pelo usuário.
class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  MuscleGroup? _filter;

  @override
  Widget build(BuildContext context) {
    final training = context.watch<TrainingController>();
    final groups = training.exercises.map((e) => e.muscleGroup).toSet();
    final exercises = training.exercises
        .where((e) => _filter == null || e.muscleGroup == _filter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treinos'),
        actions: [
          IconButton(
            tooltip: 'Registrar treino',
            icon: const Icon(Icons.playlist_add),
            onPressed: training.exercises.isEmpty
                ? null
                : () => WorkoutActions.openNewWorkout(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('exercises_add'),
        onPressed: () => WorkoutActions.openExerciseForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo exercício'),
      ),
      body: training.exercises.isEmpty
          ? EmptyState(
              icon: Icons.fitness_center,
              title: 'Nenhum exercício cadastrado',
              message:
                  'Cadastre exercícios como Supino reto ou '
                  'Agachamento para começar a registrar suas cargas.',
              action: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                onPressed: () => WorkoutActions.openExerciseForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar exercício'),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    children: [
                      _chip('Todos', _filter == null, () {
                        setState(() => _filter = null);
                      }),
                      for (final g in MuscleGroup.values)
                        if (groups.contains(g))
                          _chip(g.label, _filter == g, () {
                            setState(() => _filter = g);
                          }),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      96,
                    ),
                    itemCount: exercises.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final e = exercises[i];
                      final last = training.lastWorkoutFor(e.id!);
                      final count = training.workoutCountFor(e.id!);
                      return AppCard(
                        onTap: () => WorkoutActions.openExercise(context, e),
                        child: Row(
                          children: [
                            MuscleGroupBadge(group: e.muscleGroup),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${e.muscleGroup.label} · '
                                    '$count ${count == 1 ? 'registro' : 'registros'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  last == null
                                      ? '—'
                                      : Formatters.weight(last.maxWeight),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  last == null
                                      ? 'sem registros'
                                      : Formatters.relativeDay(last.date),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              color: context.colors.textSecondary,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: AppSpacing.sm),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    ),
  );
}
