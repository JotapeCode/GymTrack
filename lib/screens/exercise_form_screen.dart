import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/training_controller.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';

/// Cadastro e edição de exercícios.
class ExerciseFormScreen extends StatefulWidget {
  const ExerciseFormScreen({super.key, this.exercise});

  final Exercise? exercise;

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.exercise?.name,
  );
  late final _descriptionController = TextEditingController(
    text: widget.exercise?.description,
  );
  late MuscleGroup? _group = widget.exercise?.muscleGroup;
  late DateTime _date = widget.exercise?.date ?? DateTime.now();
  bool _groupError = false;
  bool _saving = false;

  static const _suggestions = [
    ('Supino reto', MuscleGroup.peito),
    ('Rosca direta', MuscleGroup.biceps),
    ('Tríceps pulley', MuscleGroup.triceps),
    ('Agachamento livre', MuscleGroup.pernas),
    ('Puxada alta', MuscleGroup.costas),
    ('Desenvolvimento', MuscleGroup.ombros),
    ('Abdominal supra', MuscleGroup.abdomen),
  ];

  bool get _isEditing => widget.exercise != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _groupError = _group == null);
    if (!valid || _group == null) return;

    setState(() => _saving = true);
    final userId = context.read<AuthController>().currentUser!.id!;
    final description = _descriptionController.text.trim();
    final exercise = Exercise(
      id: widget.exercise?.id,
      userId: widget.exercise?.userId ?? userId,
      name: _nameController.text.trim(),
      muscleGroup: _group!,
      description: description.isEmpty ? null : description,
      date: _date,
    );
    await context.read<TrainingController>().saveExercise(exercise);
    if (!mounted) return;
    showAppSnackBar(
      context,
      _isEditing ? 'Exercício atualizado.' : 'Exercício cadastrado!',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar exercício' : 'Novo exercício'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextFormField(
              key: const Key('exercise_name'),
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome do exercício',
                hintText: 'Ex.: Supino reto',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              validator: (v) => Validators.required(v, 'Nome'),
            ),
            if (!_isEditing) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final (name, group) in _suggestions)
                    ActionChip(
                      label: Text(name),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() {
                        _nameController.text = name;
                        _group = group;
                        _groupError = false;
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Grupo muscular',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final g in MuscleGroup.values)
                  ChoiceChip(
                    avatar: Icon(
                      g.icon,
                      size: 18,
                      color: _group == g
                          ? context.colors.adapt(g.color)
                          : context.colors.textSecondary,
                    ),
                    label: Text(g.label),
                    selected: _group == g,
                    showCheckmark: false,
                    selectedColor: context.colors.tint(
                      context.colors.adapt(g.color),
                    ),
                    side: BorderSide(
                      color: _group == g
                          ? context.colors.adapt(g.color)
                          : context.colors.border,
                    ),
                    onSelected: (_) => setState(() {
                      _group = g;
                      _groupError = false;
                    }),
                  ),
              ],
            ),
            if (_groupError)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm, left: 12),
                child: Text(
                  'Selecione o grupo muscular',
                  style: TextStyle(color: context.colors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Ex.: pegada aberta, banco inclinado...',
                alignLabelWithHint: true,
              ),
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
                          'Data',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          Formatters.date(_date),
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
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              key: const Key('exercise_save'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Salvar alterações' : 'Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}
