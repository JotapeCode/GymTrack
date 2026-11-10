import 'dart:async';

import 'package:flutter/foundation.dart';

enum RestTimerStatus { idle, running, paused, finished }

/// Cronômetro de descanso entre séries.
///
/// O tempo restante é calculado a partir do horário de término, e não
/// contando "ticks": assim continua correto mesmo se o app ficar em
/// segundo plano por alguns segundos.
class RestTimerController extends ChangeNotifier {
  RestTimerController({
    this.duration = const Duration(seconds: 90),
    DateTime Function()? clock,
    this.onFinished,
  }) : _clock = clock ?? DateTime.now;

  static const presets = [
    Duration(seconds: 60),
    Duration(seconds: 90),
    Duration(minutes: 2),
    Duration(minutes: 3),
  ];

  final DateTime Function() _clock;
  final VoidCallback? onFinished;

  /// Duração total escolhida (preset + ajustes de +15s).
  Duration duration;

  RestTimerStatus _status = RestTimerStatus.idle;
  DateTime? _endsAt;
  Duration? _pausedRemaining;
  Timer? _ticker;

  RestTimerStatus get status => _status;
  bool get isRunning => _status == RestTimerStatus.running;

  Duration get remaining {
    switch (_status) {
      case RestTimerStatus.idle:
        return duration;
      case RestTimerStatus.paused:
        return _pausedRemaining!;
      case RestTimerStatus.finished:
        return Duration.zero;
      case RestTimerStatus.running:
        final left = _endsAt!.difference(_clock());
        return left.isNegative ? Duration.zero : left;
    }
  }

  /// De 0 (início) a 1 (fim do descanso).
  double get progress {
    if (duration == Duration.zero) return 1;
    final p = 1 - remaining.inMilliseconds / duration.inMilliseconds;
    return p.clamp(0, 1);
  }

  void selectPreset(Duration preset) {
    duration = preset;
    start();
  }

  void start() {
    _endsAt = _clock().add(duration);
    _status = RestTimerStatus.running;
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (!isRunning) return;
    _pausedRemaining = remaining;
    _status = RestTimerStatus.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  void resume() {
    if (_status != RestTimerStatus.paused) return;
    _endsAt = _clock().add(_pausedRemaining!);
    _status = RestTimerStatus.running;
    _startTicker();
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _status = RestTimerStatus.idle;
    notifyListeners();
  }

  /// Soma 15 segundos ao descanso (também funciona parado ou concluído).
  void addTime([Duration extra = const Duration(seconds: 15)]) {
    switch (_status) {
      case RestTimerStatus.running:
        _endsAt = _endsAt!.add(extra);
        duration += extra;
      case RestTimerStatus.paused:
        _pausedRemaining = _pausedRemaining! + extra;
        duration += extra;
      case RestTimerStatus.idle:
        duration += extra;
      case RestTimerStatus.finished:
        duration = extra;
        start();
        return;
    }
    notifyListeners();
  }

  /// Verifica se o tempo acabou. Chamado pelo ticker e exposto para testes.
  @visibleForTesting
  void tick() {
    if (!isRunning) return;
    if (remaining == Duration.zero) {
      _ticker?.cancel();
      _status = RestTimerStatus.finished;
      onFinished?.call();
    }
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
