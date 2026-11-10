import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_admin_controller.dart';
import '../../models/app_user.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/common.dart';

/// Cadastro e edição de usuários (somente administrador).
class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key, this.user});

  final AppUser? user;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.name);
  late final _email = TextEditingController(text: widget.user?.email);
  final _password = TextEditingController();
  late UserRole _role = widget.user?.role ?? UserRole.user;
  late bool _active = widget.user?.isActive ?? true;
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.user != null;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final base =
        widget.user ??
        AppUser(
          name: '',
          email: '',
          role: UserRole.user,
          createdAt: DateTime.now(),
        );
    final user = base.copyWith(
      name: _name.text.trim(),
      email: _email.text.trim(),
      role: _role,
      isActive: _active,
    );
    final error = await context.read<UserAdminController>().save(
      user,
      password: _password.text.isEmpty ? null : _password.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _error = error;
        _saving = false;
      });
      return;
    }
    final auth = context.read<AuthController>();
    if (user.id == auth.currentUser?.id) await auth.refresh();
    if (!mounted) return;
    showAppSnackBar(
      context,
      _isEditing ? 'Usuário atualizado.' : 'Usuário criado!',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar usuário' : 'Novo usuário'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextFormField(
              key: const Key('user_name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: Validators.name,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('user_email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('user_password'),
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: _isEditing ? 'Nova senha (opcional)' : 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => Validators.password(v, optional: _isEditing),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Tipo de usuário',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<UserRole>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: context.colors.accent.withValues(
                  alpha: 0.2,
                ),
                selectedForegroundColor: context.colors.accent,
                side: BorderSide(color: context.colors.border),
                minimumSize: const Size(0, 48),
              ),
              segments: const [
                ButtonSegment(
                  value: UserRole.user,
                  icon: Icon(Icons.person_outline),
                  label: Text('Usuário comum'),
                ),
                ButtonSegment(
                  value: UserRole.admin,
                  icon: Icon(Icons.verified_user_outlined),
                  label: Text('Administrador'),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                title: const Text('Conta ativa'),
                subtitle: Text(
                  _active
                      ? 'O usuário pode entrar no aplicativo'
                      : 'O acesso do usuário está bloqueado',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: context.colors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: context.colors.error),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              key: const Key('user_save'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Salvar alterações' : 'Criar usuário'),
            ),
          ],
        ),
      ),
    );
  }
}
