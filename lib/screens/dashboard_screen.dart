import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/training_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'home_shell.dart';
import 'workout_actions.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});

  final ValueChanged<AppTab> onNavigate;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    // Durante a animação de logout a tela antiga ainda é reconstruída.
    if (user == null) return const SizedBox.shrink();
    final training = context.watch<TrainingController>();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => training.loadForUser(user.id!),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            _Header(
              greeting: Formatters.greeting(),
              name: user.firstName,
              initials: user.initials,
              isAdmin: user.isAdmin,
              onAvatarTap: () => onNavigate(AppTab.profile),
            ),
            const SizedBox(height: AppSpacing.lg),
            _RegisterCard(
              onPressed: training.exercises.isEmpty
                  ? () => WorkoutActions.openExerciseForm(context)
                  : () => WorkoutActions.openNewWorkout(context),
              hasExercises: training.exercises.isNotEmpty,
            ),
            const SizedBox(height: AppSpacing.md),
            if (training.isLoading && training.workouts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _StatsGrid(training: training),
              if (user.isAdmin) ...[
                const SizedBox(height: AppSpacing.md),
                _AdminCard(onTap: () => onNavigate(AppTab.users)),
              ],
              const SizedBox(height: AppSpacing.lg),
              _LastWorkout(training: training),
              const SizedBox(height: AppSpacing.lg),
              _EvolutionSummary(
                training: training,
                onSeeAll: () => onNavigate(AppTab.exercises),
              ),
              const SizedBox(height: AppSpacing.lg),
              _RecentExercises(
                training: training,
                onSeeAll: () => onNavigate(AppTab.exercises),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.name,
    required this.initials,
    required this.isAdmin,
    required this.onAvatarTap,
  });

  final String greeting;
  final String name;
  final String initials;
  final bool isAdmin;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Formatters.longDate(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                '$greeting, $name',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (isAdmin) ...[
                const SizedBox(height: 6),
                Tag(
                  label: 'Administrador',
                  icon: Icons.verified_user_outlined,
                  color: context.colors.info,
                ),
              ],
            ],
          ),
        ),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onAvatarTap,
          child: UserAvatar(initials: initials, size: 52),
        ),
      ],
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({required this.onPressed, required this.hasExercises});

  final VoidCallback onPressed;
  final bool hasExercises;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Única superfície colorida da tela: é a ação principal do app.
    return AppCard(
      color: Color.alphaBlend(c.accent.withValues(alpha: 0.07), c.card),
      borderColor: c.accent.withValues(alpha: c.isDark ? 0.28 : 0.22),
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasExercises ? 'Pronto para treinar?' : 'Comece agora',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            hasExercises
                ? 'Registre suas séries, cargas e repetições.'
                : 'Cadastre seu primeiro exercício.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('dashboard_register'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: Text(hasExercises ? 'Registrar treino' : 'Novo exercício'),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.training});

  final TrainingController training;

  @override
  Widget build(BuildContext context) {
    final cards = [
      StatCard(
        icon: Icons.fitness_center,
        label: 'Exercícios',
        value: '${training.exercises.length}',
      ),
      StatCard(
        icon: Icons.assignment_turned_in_outlined,
        label: 'Registros',
        value: '${training.workouts.length}',
        color: context.colors.info,
      ),
      StatCard(
        icon: Icons.calendar_month_outlined,
        label: 'Dias treinados',
        value: '${training.trainingDays}',
        color: context.colors.warning,
      ),
      StatCard(
        icon: Icons.local_fire_department_outlined,
        label: 'Últimos 7 dias',
        value: '${training.workoutsThisWeek}',
        color: context.colors.highlight,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 560 ? 4 : 2;
        final width =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final c in cards) SizedBox(width: width, child: c)],
        );
      },
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(
            icon: Icons.admin_panel_settings_outlined,
            color: context.colors.info,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Área administrativa',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Gerencie usuários e permissões',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.textSecondary),
        ],
      ),
    );
  }
}

class _LastWorkout extends StatelessWidget {
  const _LastWorkout({required this.training});

  final TrainingController training;

  @override
  Widget build(BuildContext context) {
    final last = training.lastWorkout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Último treino'),
        if (last == null)
          InlineMessage('Nenhum treino registrado ainda.')
        else
          Builder(
            builder: (context) {
              final exercise = training.exerciseById(last.exerciseId);
              final cmp = training.compare(last);
              final delta = cmp.weightDelta(last);
              return AppCard(
                onTap: exercise == null
                    ? null
                    : () => WorkoutActions.openExercise(context, exercise),
                child: Row(
                  children: [
                    if (exercise != null)
                      MuscleGroupBadge(group: exercise.muscleGroup),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            last.exerciseName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${Formatters.relativeDay(last.date)} · '
                            '${Formatters.plural(last.sets.length, 'série', 'séries')} · '
                            '${last.totalReps} reps',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.weight(last.maxWeight),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        if (cmp.hasPrevious && delta != 0)
                          Text(
                            Formatters.signedWeight(delta),
                            style: TextStyle(
                              color: delta > 0
                                  ? context.colors.accent
                                  : context.colors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _EvolutionSummary extends StatelessWidget {
  const _EvolutionSummary({required this.training, required this.onSeeAll});

  final TrainingController training;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final evolutions = training.evolutions.take(4).toList();
    if (evolutions.isEmpty) return const SizedBox.shrink();
    final maxPercent = evolutions
        .map((e) => e.percent.abs())
        .fold<double>(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Evolução de carga',
          action: TextButton(
            onPressed: onSeeAll,
            child: const Text('Ver tudo'),
          ),
        ),
        AppCard(
          child: Column(
            children: [
              for (final (i, e) in evolutions.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: () => WorkoutActions.openExercise(context, e.exercise),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.exercise.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${Formatters.weight(e.firstWeight)} → '
                            '${Formatters.weight(e.lastWeight)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 56,
                            child: Text(
                              '${e.percent >= 0 ? '+' : ''}'
                              '${e.percent.toStringAsFixed(0)}%',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: e.percent > 0
                                    ? context.colors.accent
                                    : e.percent < 0
                                    ? context.colors.error
                                    : context.colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: e.percent.abs() / maxPercent,
                          ),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (_, value, _) => LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor: context.colors.cardHighlight,
                            color: e.percent >= 0
                                ? context.colors.accent
                                : context.colors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentExercises extends StatelessWidget {
  const _RecentExercises({required this.training, required this.onSeeAll});

  final TrainingController training;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final recent = training.recentExercises.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Exercícios recentes',
          action: recent.isEmpty
              ? null
              : TextButton(onPressed: onSeeAll, child: const Text('Ver todos')),
        ),
        if (recent.isEmpty)
          InlineMessage('Você ainda não cadastrou exercícios.'),
        for (final e in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Builder(
              builder: (context) {
                final last = training.lastWorkoutFor(e.id!);
                return AppCard(
                  onTap: () => WorkoutActions.openExercise(context, e),
                  padding: const EdgeInsets.all(AppSpacing.sm + 4),
                  child: Row(
                    children: [
                      MuscleGroupBadge(group: e.muscleGroup, size: 40),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              last == null
                                  ? e.muscleGroup.label
                                  : '${e.muscleGroup.label} · '
                                        '${Formatters.relativeDay(last.date)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (last != null)
                        Text(
                          Formatters.weight(last.maxWeight),
                          style: const TextStyle(fontWeight: FontWeight.w700),
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
    );
  }
}
