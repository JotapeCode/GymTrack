import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/training_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onNavigate});

  final ValueChanged<AppTab> onNavigate;

  Future<void> _logout(BuildContext context) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Sair da conta?',
      message: 'Você precisará entrar novamente para acessar seus treinos.',
      confirmLabel: 'Sair',
    );
    if (!confirmed || !context.mounted) return;
    context.read<TrainingController>().clear();
    context.read<AuthController>().logout();
  }

  Future<void> _editName(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final formKey = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nome'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: Validators.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (name == null || !context.mounted) return;
    final error = await context.read<AuthController>().updateName(name);
    if (context.mounted) {
      showAppSnackBar(
        context,
        error ?? 'Nome atualizado.',
        error: error != null,
      );
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ChangePasswordSheet(),
    );
    if (result != null && context.mounted) {
      showAppSnackBar(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    // Durante a animação de logout a tela antiga ainda é reconstruída.
    if (user == null) return const SizedBox.shrink();
    final training = context.watch<TrainingController>();
    final bestEvolution = training.evolutions.isEmpty
        ? null
        : training.evolutions.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                UserAvatar(initials: user.initials, size: 80),
                const SizedBox(height: AppSpacing.md),
                Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Tag(
                  label: user.role.label,
                  icon: user.isAdmin
                      ? Icons.verified_user_outlined
                      : Icons.person_outline,
                  color: user.isAdmin
                      ? context.colors.info
                      : context.colors.accent,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Membro desde ${Formatters.date(user.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.fitness_center,
                  label: 'Exercícios',
                  value: '${training.exercises.length}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Registros',
                  value: '${training.workouts.length}',
                  color: context.colors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  icon: Icons.trending_up,
                  label: 'Evolução',
                  value: bestEvolution == null
                      ? '—'
                      : '${bestEvolution.percent > 0 ? '+' : ''}'
                            '${bestEvolution.percent.toStringAsFixed(0)}%',
                  color: context.colors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Aparência'),
          const _ThemeSelector(),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Conta'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _OptionTile(
                  icon: Icons.badge_outlined,
                  label: 'Editar nome',
                  onTap: () => _editName(context, user.name),
                ),
                const Divider(indent: 56),
                _OptionTile(
                  icon: Icons.lock_reset,
                  label: 'Alterar senha',
                  onTap: () => _changePassword(context),
                ),
                if (user.isAdmin) ...[
                  const Divider(indent: 56),
                  _OptionTile(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Gerenciar usuários',
                    color: context.colors.info,
                    onTap: () => onNavigate(AppTab.users),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            key: const Key('profile_logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.error,
              side: BorderSide(
                color: context.colors.error.withValues(alpha: 0.5),
              ),
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              'GymTrack v1.0 · dados armazenados localmente',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Escolha entre tema escuro, claro ou o mesmo do aparelho.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ThemeMode>(
        key: const Key('profile_theme'),
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_outlined, size: 18),
            label: Text('Escuro'),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_outlined, size: 18),
            label: Text('Claro'),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.smartphone_outlined, size: 18),
            label: Text('Sistema'),
          ),
        ],
        selected: {theme.mode},
        onSelectionChanged: (s) => theme.setMode(s.first),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.accent;
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: context.colors.textSecondary),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await context.read<AuthController>().changePassword(
      _current.text,
      _new.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, 'Senha alterada com sucesso.');
    } else {
      setState(() {
        _error = error;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Alterar senha',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha atual'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Informe a senha atual' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _new,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nova senha'),
              validator: Validators.password,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nova senha',
              ),
              validator: (v) =>
                  v != _new.text ? 'As senhas não coincidem' : null,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  _error!,
                  style: TextStyle(color: context.colors.error),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: const Text('Salvar nova senha'),
            ),
          ],
        ),
      ),
    );
  }
}
