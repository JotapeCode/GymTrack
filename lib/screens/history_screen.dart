import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/training_controller.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/progress_chart.dart';
import '../widgets/workout_card.dart';
import 'workout_actions.dart';

/// Histórico de treinos com filtros por exercício e por período.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? _exerciseId;
  DateTimeRange? _range;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _range,
      helpText: 'Filtrar por período',
      saveText: 'Aplicar',
    );
    if (picked != null) setState(() => _range = picked);
  }

  bool _inRange(Workout w) {
    final range = _range;
    if (range == null) return true;
    final day = DateTime(w.date.year, w.date.month, w.date.day);
    return !day.isBefore(range.start) && !day.isAfter(range.end);
  }

  @override
  Widget build(BuildContext context) {
    final training = context.watch<TrainingController>();
    if (_exerciseId != null && training.exerciseById(_exerciseId!) == null) {
      _exerciseId = null;
    }
    final filtered = training.workouts
        .where((w) => _exerciseId == null || w.exerciseId == _exerciseId)
        .where(_inRange)
        .toList();
    final totalVolume = filtered.fold<double>(0, (a, w) => a + w.totalVolume);

    // Agrupa os registros por dia.
    final groups = <DateTime, List<Workout>>{};
    for (final w in filtered) {
      groups
          .putIfAbsent(
            DateTime(w.date.year, w.date.month, w.date.day),
            () => [],
          )
          .add(w);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Filtrar por data',
            onPressed: _pickRange,
            icon: Icon(
              Icons.date_range,
              color: _range == null ? null : context.colors.accent,
            ),
          ),
        ],
      ),
      body: training.workouts.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'Sem histórico ainda',
              message: 'Seus treinos registrados aparecerão aqui.',
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      children: [
                        _chip(
                          'Todos',
                          _exerciseId == null,
                          () => setState(() => _exerciseId = null),
                        ),
                        for (final e in training.exercises)
                          _chip(
                            e.name,
                            _exerciseId == e.id,
                            () => setState(() => _exerciseId = e.id),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_range != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: InputChip(
                          avatar: Icon(
                            Icons.date_range,
                            size: 18,
                            color: context.colors.accent,
                          ),
                          label: Text(
                            '${Formatters.date(_range!.start)} — '
                            '${Formatters.date(_range!.end)}',
                          ),
                          onPressed: _pickRange,
                          onDeleted: () => setState(() => _range = null),
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.assignment_outlined,
                            label: 'Registros',
                            value: '${filtered.length}',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StatCard(
                            icon: Icons.scale_outlined,
                            label: 'Volume total',
                            value: '${Formatters.number(totalVolume)} kg',
                            color: context.colors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_exerciseId != null && filtered.length >= 2)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: AppCard(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.sm,
                                bottom: AppSpacing.md,
                              ),
                              child: Text(
                                'Evolução — ${filtered.first.exerciseName}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            ProgressChart(
                              workouts: filtered.reversed.toList(),
                              height: 180,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'Nenhum registro encontrado',
                      message: 'Altere os filtros para ver outros treinos.',
                    ),
                  ),
                for (final entry in groups.entries) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        '${Formatters.relativeDay(entry.key)} · '
                        '${Formatters.longDate(entry.key)}',
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    sliver: SliverList.separated(
                      itemCount: entry.value.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final w = entry.value[i];
                        return WorkoutCard(
                          workout: w,
                          comparison: training.compare(w),
                          onEdit: () =>
                              WorkoutActions.openEditWorkout(context, w),
                          onDelete: () =>
                              WorkoutActions.deleteWorkout(context, w),
                        );
                      },
                    ),
                  ),
                ],
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
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
