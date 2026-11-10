import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/rest_timer_controller.dart';
import '../theme/app_colors.dart';
import 'common.dart';

/// Card com o cronômetro de descanso entre séries.
class RestTimerCard extends StatefulWidget {
  const RestTimerCard({super.key});

  @override
  State<RestTimerCard> createState() => _RestTimerCardState();
}

class _RestTimerCardState extends State<RestTimerCard> {
  late final _timer = RestTimerController(onFinished: _alert);

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  /// Vibra e toca um som ao fim do descanso.
  Future<void> _alert() async {
    SystemSound.play(SystemSoundType.alert);
    for (var i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
  }

  static String _format(Duration d) {
    // Arredonda para cima: 0:00 só aparece quando o tempo acabou de fato.
    final total = (d.inMilliseconds / 1000).ceil();
    final m = total ~/ 60;
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String _presetLabel(Duration d) =>
      d.inSeconds < 120 ? '${d.inSeconds}s' : '${d.inMinutes} min';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _timer,
      builder: (context, _) {
        final status = _timer.status;
        final finished = status == RestTimerStatus.finished;
        final color = finished ? context.colors.warning : context.colors.accent;

        return AppCard(
          key: const Key('rest_timer'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconBadge(
                    icon: finished
                        ? Icons.notifications_active_outlined
                        : Icons.timer_outlined,
                    color: color,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          finished ? 'Descanso concluído!' : 'Descanso',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          _format(_timer.remaining),
                          key: const Key('rest_timer_value'),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: finished
                                ? color
                                : context.colors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Adicionar 15 segundos',
                    onPressed: _timer.addTime,
                    icon: const Text(
                      '+15s',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (status != RestTimerStatus.idle)
                    IconButton(
                      tooltip: 'Zerar',
                      onPressed: _timer.reset,
                      icon: const Icon(Icons.replay),
                    ),
                  IconButton.filled(
                    key: const Key('rest_timer_toggle'),
                    tooltip: switch (status) {
                      RestTimerStatus.running => 'Pausar',
                      RestTimerStatus.paused => 'Continuar',
                      _ => 'Iniciar descanso',
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: context.colors.isDark
                          ? context.colors.background
                          : Colors.white,
                    ),
                    onPressed: switch (status) {
                      RestTimerStatus.running => _timer.pause,
                      RestTimerStatus.paused => _timer.resume,
                      _ => _timer.start,
                    },
                    icon: Icon(
                      status == RestTimerStatus.running
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: status == RestTimerStatus.idle ? 0 : _timer.progress,
                  minHeight: 6,
                  color: color,
                  backgroundColor: context.colors.border,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final preset in RestTimerController.presets)
                    ChoiceChip(
                      label: Text(_presetLabel(preset)),
                      selected: _timer.duration == preset,
                      onSelected: (_) => _timer.selectPreset(preset),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
