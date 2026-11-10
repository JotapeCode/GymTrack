import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/training_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/progress_chart.dart';
import '../widgets/workout_card.dart';
import 'workout_actions.dart';

/// Detalhes de um exercício: estatísticas, gráfico de evolução e registros.
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final int exerciseId;

  Future<void> _delete(
    BuildContext context,
    TrainingController training,
  ) async {
    final exercise = training.exerciseById(exerciseId)!;
    final confirmed = await confirmDialog(
      context,
      title: 'Excluir exercício?',
      message:
          '"${exercise.name}" e todos os seus registros de treino '
          'serão removidos permanentemente.',
    );
    if (!confirmed || !context.mounted) return;
    Navigator.of(context).pop();
    await training.deleteExercise(exercise);
  }

  @override
  Widget build(BuildContext context) {
    final training = context.watch<TrainingController>();
    final exercise = training.exerciseById(exerciseId);
    if (exercise == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final history = training.workoutsFor(exerciseId);
    final records = history.reversed.toList();
    final best = history.isEmpty
        ? 0.0
        : history.map((w) => w.maxWeight).reduce((a, b) => a > b ? a : b);
    final evolution = history.length < 2
        ? null
        : history.last.maxWeight - history.first.maxWeight;
    final oneRepMax = training.bestOneRepMaxFor(exerciseId);
    final increases = [
      for (var i = 1; i < history.length; i++)
        if (history[i].maxWeight > history[i - 1].maxWeight) i,
    ].length;

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        actions: [
          IconButton(
            tooltip: 'Editar exercício',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                WorkoutActions.openExerciseForm(context, exercise: exercise),
          ),
          IconButton(
            tooltip: 'Excluir exercício',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, training),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('detail_register'),
        onPressed: () =>
            WorkoutActions.openNewWorkout(context, exerciseId: exerciseId),
        icon: const Icon(Icons.add),
        label: const Text('Registrar treino'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          96,
        ),
        children: [
          Row(
            children: [
              MuscleGroupBadge(group: exercise.muscleGroup, size: 52),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.muscleGroup.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Cadastrado em ${Formatters.date(exercise.date)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (exercise.description?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              exercise.description!,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Grade 2×2: carga recorde e força estimada em cima, tendência
          // embaixo.
          _StatGrid(
            children: [
              StatCard(
                icon: Icons.emoji_events_outlined,
                label: 'Recorde',
                value: history.isEmpty ? '—' : Formatters.weight(best),
              ),
              StatCard(
                key: const Key('detail_one_rep_max'),
                icon: Icons.bolt_outlined,
                label: '1RM estimado',
                value: history.isEmpty
                    ? '—'
                    : Formatters.weight(oneRepMax.roundToDouble()),
                color: context.colors.info,
              ),
              StatCard(
                icon: Icons.show_chart,
                label: 'Evolução',
                value: evolution == null
                    ? '—'
                    : Formatters.signedWeight(evolution),
                color: (evolution ?? 0) >= 0
                    ? context.colors.accent
                    : context.colors.error,
              ),
              StatCard(
                icon: Icons.trending_up,
                label: 'Aumentos de carga',
                value: '$increases',
                color: context.colors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Evolução da carga máxima'),
          AppCard(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                ProgressChart(workouts: history),
                if (history.length >= 2)
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: context.colors.accent,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Aumento de carga',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: 'Registros (${records.length})'),
          if (records.isEmpty)
            InlineMessage('Nenhum treino registrado para este exercício.'),
          for (final w in records)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: WorkoutCard(
                workout: w,
                comparison: training.compare(w),
                showExerciseName: false,
                onEdit: () => WorkoutActions.openEditWorkout(context, w),
                onDelete: () => WorkoutActions.deleteWorkout(context, w),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 560 ? 4 : 2;
        final width =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final c in children) SizedBox(width: width, child: c),
          ],
        );
      },
    );
  }
}
