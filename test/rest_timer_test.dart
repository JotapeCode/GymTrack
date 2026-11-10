import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/controllers/rest_timer_controller.dart';

void main() {
  late DateTime now;
  late int finishedCalls;
  late RestTimerController timer;

  setUp(() {
    now = DateTime(2026, 11, 10, 10);
    finishedCalls = 0;
    timer = RestTimerController(
      duration: const Duration(seconds: 90),
      clock: () => now,
      onFinished: () => finishedCalls++,
    );
  });

  tearDown(() => timer.dispose());

  test('começa parado com a duração escolhida', () {
    expect(timer.status, RestTimerStatus.idle);
    expect(timer.remaining, const Duration(seconds: 90));
  });

  test('conta o tempo a partir do horário de término', () {
    timer.start();
    now = now.add(const Duration(seconds: 30));
    expect(timer.remaining, const Duration(seconds: 60));
    expect(timer.progress, closeTo(1 / 3, 0.001));
  });

  test('pausa congela o tempo e continua de onde parou', () {
    timer.start();
    now = now.add(const Duration(seconds: 20));
    timer.pause();
    now = now.add(const Duration(minutes: 5));
    expect(timer.remaining, const Duration(seconds: 70));
    timer.resume();
    now = now.add(const Duration(seconds: 10));
    expect(timer.remaining, const Duration(seconds: 60));
  });

  test('+15s aumenta o descanso em andamento', () {
    timer.start();
    timer.addTime();
    expect(timer.remaining, const Duration(seconds: 105));
  });

  test('ao chegar a zero, conclui e avisa uma única vez', () {
    timer.start();
    now = now.add(const Duration(seconds: 91));
    timer.tick();
    timer.tick();
    expect(timer.status, RestTimerStatus.finished);
    expect(timer.remaining, Duration.zero);
    expect(finishedCalls, 1);
  });

  test('preset troca a duração e já inicia', () {
    timer.selectPreset(const Duration(minutes: 2));
    expect(timer.status, RestTimerStatus.running);
    expect(timer.remaining, const Duration(minutes: 2));
  });
}
