import 'package:flutter/material.dart';

import '../models/muscle_group.dart';
import '../theme/app_colors.dart';
import 'brand.dart';

/// Logotipo do GymTrack: símbolo + nome.
class GymTrackLogo extends StatelessWidget {
  const GymTrackLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GymTrackAppIcon(size: size),
        const SizedBox(height: AppSpacing.md),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineMedium,
            children: [
              const TextSpan(text: 'Gym'),
              TextSpan(
                text: 'Track',
                style: TextStyle(color: c.accent),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card padrão: superfície com contorno sutil. No tema claro ganha uma
/// sombra quase imperceptível para separar o branco do fundo.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderColor,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(AppSpacing.radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: c.isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: color ?? c.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: borderColor ?? c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Indicador numérico. Em espaços largos fica em linha (ícone ao lado do
/// valor); em espaços estreitos, empilhado.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = color ?? c.accent;
    final valueText = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: TextStyle(
          fontSize: 22,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: c.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    );

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md - 2,
        vertical: AppSpacing.md - 2,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 140) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(icon: icon, color: tone, size: 30),
                const SizedBox(height: AppSpacing.sm + 2),
                valueText,
                const SizedBox(height: 2),
                labelText,
              ],
            );
          }
          return Row(
            children: [
              IconBadge(icon: icon, color: tone, size: 38),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [valueText, const SizedBox(height: 2), labelText],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Ícone sobre um fundo translúcido da mesma cor.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.color, this.size = 40});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = color ?? c.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.tint(tone),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: tone, size: size * 0.52),
    );
  }
}

class MuscleGroupBadge extends StatelessWidget {
  const MuscleGroupBadge({super.key, required this.group, this.size = 44});

  final MuscleGroup group;
  final double size;

  @override
  Widget build(BuildContext context) => IconBadge(
    icon: group.icon,
    color: context.colors.adapt(group.color),
    size: size,
  );
}

/// Etiqueta pequena (ex.: "Recorde", "Admin", "Ativo").
class Tag extends StatelessWidget {
  const Tag({super.key, required this.label, this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = color ?? c.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.tint(tone),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: tone),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SizedBox(
        // Altura fixa: seções com e sem ação ficam alinhadas.
        height: 36,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconBadge(
                icon: icon,
                size: 64,
                color: context.colors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensagem curta dentro de um card (listas vazias em seções).
class InlineMessage extends StatelessWidget {
  const InlineMessage(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Text(text, style: TextStyle(color: context.colors.textSecondary)),
  );
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.size = 48,
    this.color,
  });

  final String initials;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = color ?? c.accent;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.tint(tone), shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(
          color: tone,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  // O snackbar tem fundo invertido: no tema claro ele é escuro, então os
  // ícones usam os tons do tema escuro para manter o contraste.
  final onSnack = context.colors.isDark ? context.colors : AppPalette.dark;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: error ? onSnack.error : onSnack.accent,
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Excluir',
}) async {
  final c = context.colors;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: IconBadge(
        icon: Icons.warning_amber_rounded,
        color: c.error,
        size: 52,
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: c.error,
                  foregroundColor: c.isDark ? c.background : Colors.white,
                  minimumSize: const Size(0, 48),
                ),
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}
