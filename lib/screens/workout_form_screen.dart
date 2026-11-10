import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/training_controller.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import '../widgets/rest_timer_card.dart';

/// Registro (ou edição) de um treino: exercício, data, séries e observações.
class WorkoutFormScreen extends StatefulWidget {
  const WorkoutFormScreen({super.key, this.workout, this.initialExerciseId});

  final Workout? workout;
  final int? initialExerciseId;

  @override
  State<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _SetFields {
  _SetFields({String reps = '', String weight = ''})
    : reps = TextEditingController(text: reps),
      weight = TextEditingController(text: weight);

  final TextEditingController reps;
  final TextEditingController weight;

  void dispose() {
    reps.dispose();
    weight.dispose();
  }
}

class _WorkoutFormScreenState extends State<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _notesController = TextEditingController(
    text: widget.workout?.notes,
  );
  final List<_SetFields> _sets = [];
  int? _exerciseId;
  late DateTime _date = widget.workout?.date ?? DateTime.now();
  bool _prefilledFromLast = false;
  bool _saving = false;

  bool get _isEditing => widget.workout != null;

  @override
  void initState() {
    super.initState();
    final workout = widget.workout;
    if (workout != null) {
      _exerciseId = workout.exerciseId;
      for (final s in workout.sets) {
        _sets.add(
          _SetFields(
            reps: '${s.reps}',
            weight: Formatters.decimalInput(s.weight),
          ),
        );
      }
    } else {
      final training = context.read<TrainingController>();
      _exerciseId =
          widget.initialExerciseId ??
          (training.exercises.isNotEmpty
              ? training.recentExercises.first.id
              : null);
      _prefillFromLast();
    }
    if (_sets.isEmpty) _sets.add(_SetFields());
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final s in _sets) {
      s.dispose();
    }
    super.dispose();
  }

  /// Ao criar, sugere as séries do último treino do exercício escolhido.
  void _prefillFromLast() {
    final id = _exerciseId;
    if (id == null || _isEditing) return;
    final last = context.read<TrainingController>().lastWorkoutFor(id);
    for (final s in _sets) {
      s.dispose();
    }
    _sets.clear();
    _prefilledFromLast = last != null;
    if (last == null) {
      _sets.addAll([_SetFields(), _SetFields(), _SetFields()]);
      return;
    }
    for (final s in last.sets) {
      _sets.add(
        _SetFields(
          reps: '${s.reps}',
          weight: Formatters.decimalInput(s.weight),
        ),
      );
    }
  }

  void _addSet() {
    final last = _sets.isEmpty ? null : _sets.last;
    setState(
      () => _sets.add(
        _SetFields(
          reps: last?.reps.text ?? '',
          weight: last?.weight.text ?? '',
        ),
      ),
    );
  }

  void _removeSet(int index) {
    if (_sets.length == 1) return;
    setState(() => _sets.removeAt(index).dispose());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_exerciseId == null) {
      showAppSnackBar(context, 'Selecione um exercício.', error: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final training = context.read<TrainingController>();
    final userId = context.read<AuthController>().currentUser!.id!;
    final notes = _notesController.text.trim();
    final workout = Workout(
      id: widget.workout?.id,
      userId: widget.workout?.userId ?? userId,
      exerciseId: _exerciseId!,
      date: _date,
      notes: notes.isEmpty ? null : notes,
      sets: [
        for (final (i, s) in _sets.indexed)
          WorkoutSet(
            setNumber: i + 1,
            reps: int.parse(s.reps.text.trim()),
            weight: Formatters.parseDecimal(s.weight.text)!,
          ),
      ],
    );

    final others = training
        .workoutsFor(workout.exerciseId)
        .where((w) => w.id != workout.id)
        .toList();

    await training.saveWorkout(workout);
    if (!mounted) return;
    final isRecord = TrainingController.isRecordOver(workout, others);
    showAppSnackBar(
      context,
      isRecord
          ? 'Novo recorde! 1RM estimado: '
                '${Formatters.weight(workout.bestOneRepMax.roundToDouble())} 🏆'
          : (_isEditing ? 'Registro atualizado.' : 'Treino registrado!'),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final training = context.watch<TrainingController>();
    final exercises = training.exercises;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar registro' : 'Registrar treino'),
      ),
      body: exercises.isEmpty
          ? const EmptyState(
              icon: Icons.fitness_center,
              title: 'Cadastre um exercício primeiro',
              message:
                  'Vá até a aba Treinos e cadastre um exercício para '
                  'registrar suas séries.',
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  DropdownButtonFormField<int>(
                    key: const Key('workout_exercise'),
                    initialValue: _exerciseId,
                    isExpanded: true,
                    dropdownColor: context.colors.cardHighlight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    decoration: const InputDecoration(
                      labelText: 'Exercício',
                      prefixIcon: Icon(Icons.fitness_center),
                    ),
                    items: [
                      for (final e in exercises)
                        DropdownMenuItem(
                          value: e.id,
                          child: Text('${e.name}  ·  ${e.muscleGroup.label}'),
                        ),
                    ],
                    onChanged: _isEditing
                        ? null
                        : (id) => setState(() {
                            _exerciseId = id;
                            _prefillFromLast();
                          }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        const IconBadge(icon: Icons.event_outlined),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data do treino',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                Formatters.longDate(_date),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.edit_calendar_outlined,
                          color: context.colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: AppSpacing.md),
                    const RestTimerCard(),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Séries (${_sets.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        key: const Key('workout_add_set'),
                        onPressed: _addSet,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar série'),
                      ),
                    ],
                  ),
                  if (_prefilledFromLast)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        'Preenchido com base no seu último treino. '
                        'Ajuste as cargas se você evoluiu!',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  for (final (i, s) in _sets.indexed)
                    _SetEditor(
                      key: ObjectKey(s),
                      index: i,
                      fields: s,
                      canRemove: _sets.length > 1,
                      onRemove: () => _removeSet(i),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      hintText: 'Ex.: senti o ombro, aumentar na próxima...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton.icon(
                    key: const Key('workout_save'),
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(
                      _isEditing ? 'Salvar alterações' : 'Salvar treino',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
    );
  }
}

class _SetEditor extends StatelessWidget {
  const _SetEditor({
    super.key,
    required this.index,
    required this.fields,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _SetFields fields;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm + 4,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: context.colors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                key: Key('set_reps_$index'),
                controller: fields.reps,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Repetições',
                  suffixText: 'reps',
                  fillColor: context.colors.background,
                ),
                validator: Validators.reps,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                key: Key('set_weight_$index'),
                controller: fields.weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Carga',
                  suffixText: 'kg',
                  fillColor: context.colors.background,
                ),
                validator: Validators.weight,
              ),
            ),
            IconButton(
              tooltip: 'Remover série',
              padding: const EdgeInsets.only(top: 12),
              onPressed: canRemove ? onRemove : null,
              icon: Icon(
                Icons.remove_circle_outline,
                color: canRemove ? context.colors.error : context.colors.border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
