import 'package:flutter/material.dart';

import '../controllers/training_controller.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'common.dart';

/// Card de um registro de treino com suas séries e a comparação
/// com o registro anterior do mesmo exercício.
class WorkoutCard extends StatelessWidget {
  const WorkoutCard({
    super.key,
    required this.workout,
    required this.comparison,
    this.showExerciseName = true,
    this.onEdit,
    this.onDelete,
  });

  final Workout workout;
  final WorkoutComparison comparison;
  final bool showExerciseName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final delta = comparison.weightDelta(workout);
    final increased = comparison.hasPrevious && delta > 0;

    return AppCard(
      borderColor: comparison.isPersonalRecord
          ? context.colors.accent.withValues(alpha: 0.6)
          : null,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      showExerciseName
                          ? workout.exerciseName
                          : Formatters.longDate(workout.date),
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      showExerciseName
                          ? '${Formatters.relativeDay(workout.date)} · '
                                '${Formatters.plural(workout.sets.length, 'série', 'séries')}'
                          : '${Formatters.plural(workout.sets.length, 'série', 'séries')} · '
                                '${Formatters.number(workout.totalVolume)} kg de volume',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (comparison.isPersonalRecord)
                const Tag(label: 'Recorde', icon: Icons.emoji_events_outlined),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: context.colors.textSecondary,
                  ),
                  tooltip: 'Opções',
                  onSelected: (value) =>
                      value == 'edit' ? onEdit?.call() : onDelete?.call(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: context.colors.error,
                        ),
                        title: Text(
                          'Excluir',
                          style: TextStyle(color: context.colors.error),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(width: AppSpacing.sm),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Column(
              children: [for (final set in workout.sets) _SetRow(set: set)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Carga máx.: ${Formatters.weight(workout.maxWeight)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (comparison.hasPrevious)
                  _DeltaChip(delta: delta, increased: increased)
                else
                  Text(
                    'Primeiro registro',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (workout.notes != null && workout.notes!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes,
                    size: 16,
                    color: context.colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      workout.notes!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.set});

  final WorkoutSet set;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.cardHighlight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${set.setNumber}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Série ${set.setNumber}',
            style: TextStyle(color: context.colors.textSecondary),
          ),
          const Spacer(),
          Text(
            '${set.reps} reps',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 72,
            child: Text(
              Formatters.weight(set.weight),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta, required this.increased});

  final double delta;
  final bool increased;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (delta) {
      > 0 => (
        context.colors.accent,
        Icons.arrow_upward,
        Formatters.signedWeight(delta),
      ),
      < 0 => (
        context.colors.error,
        Icons.arrow_downward,
        Formatters.signedWeight(delta),
      ),
      _ => (context.colors.textSecondary, Icons.drag_handle, 'Mesma carga'),
    };
    return Tag(label: label, icon: icon, color: color);
  }
}
