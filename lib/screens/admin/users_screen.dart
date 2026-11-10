import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_admin_controller.dart';
import '../../models/app_user.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import 'user_form_screen.dart';

/// Área exclusiva do administrador: lista e gerenciamento de usuários.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthController>().currentUser?.isAdmin ?? false) {
        context.read<UserAdminController>().load();
      }
    });
  }

  Future<void> _openForm([AppUser? user]) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => UserFormScreen(user: user)));
  }

  Future<void> _delete(AppUser user) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Excluir usuário?',
      message:
          '${user.name} (${user.email}) e todos os seus treinos serão '
          'removidos permanentemente.',
    );
    if (!confirmed || !mounted) return;
    final currentId = context.read<AuthController>().currentUser!.id!;
    final error = await context.read<UserAdminController>().delete(
      user,
      currentUserId: currentId,
    );
    if (mounted) {
      showAppSnackBar(
        context,
        error ?? 'Usuário excluído.',
        error: error != null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AuthController>().currentUser;
    // Durante a animação de logout a tela antiga ainda é reconstruída.
    if (current == null) return const SizedBox.shrink();
    if (!current.isAdmin) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Acesso restrito',
          message: 'Somente administradores podem acessar esta área.',
        ),
      );
    }
    final admin = context.watch<UserAdminController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Usuários')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('users_add'),
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Novo usuário'),
      ),
      body: admin.isLoading && admin.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: admin.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  96,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.group_outlined,
                          label: 'Usuários',
                          value: '${admin.users.length}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatCard(
                          icon: Icons.verified_user_outlined,
                          label: 'Admins',
                          value: '${admin.adminCount}',
                          color: context.colors.info,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatCard(
                          icon: Icons.toggle_on_outlined,
                          label: 'Ativos',
                          value: '${admin.activeCount}',
                          color: context.colors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: 'Usuários cadastrados'),
                  for (final user in admin.users)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _UserTile(
                        user: user,
                        isCurrent: user.id == current.id,
                        onEdit: () => _openForm(user),
                        onDelete: () => _delete(user),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.isCurrent,
    required this.onEdit,
    required this.onDelete,
  });

  final AppUser user;
  final bool isCurrent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final roleColor = user.isAdmin
        ? context.colors.info
        : context.colors.accent;
    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 4,
        AppSpacing.xs,
        AppSpacing.sm + 4,
      ),
      child: Row(
        children: [
          UserAvatar(
            initials: user.initials,
            color: user.isActive ? roleColor : context.colors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrent ? '${user.name} (você)' : user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Tag(
                      label: user.isAdmin ? 'Admin' : 'Comum',
                      color: roleColor,
                    ),
                    Tag(
                      label: user.isActive ? 'Ativo' : 'Inativo',
                      color: user.isActive
                          ? context.colors.accent
                          : context.colors.error,
                      icon: user.isActive
                          ? Icons.check_circle_outline
                          : Icons.block,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar',
            onPressed: onEdit,
            icon: Icon(
              Icons.edit_outlined,
              color: context.colors.textSecondary,
            ),
          ),
          IconButton(
            tooltip: 'Excluir',
            onPressed: isCurrent ? null : onDelete,
            icon: Icon(
              Icons.delete_outline,
              color: isCurrent ? context.colors.border : context.colors.error,
            ),
          ),
        ],
      ),
    );
  }
}
