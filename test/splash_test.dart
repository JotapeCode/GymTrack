import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/controllers/theme_controller.dart';
import 'package:meu_app/screens/splash_screen.dart';
import 'package:meu_app/widgets/brand.dart';

Widget _app(ThemeController theme) =>
    const MaterialApp(home: Scaffold(body: Text('app pronto')));

void main() {
  testWidgets('mostra a abertura e passa para o app ao terminar', (
    tester,
  ) async {
    await tester.pumpWidget(
      GymTrackBoot(
        initialize: () async => ThemeController(persist: false),
        builder: _app,
      ),
    );

    expect(find.byType(GymTrackMark), findsOneWidget);
    expect(find.text('Carregando seu progresso…'), findsOneWidget);
    expect(find.text('app pronto'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('app pronto'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('símbolo começa no centro, como na abertura nativa', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(ready: false, onComplete: () {})),
    );
    final screen = tester.getCenter(find.byType(Scaffold));
    final mark = tester.getCenter(find.byType(GymTrackMark));
    expect(
      (mark.dy - screen.dy).abs(),
      lessThan(3),
      reason: 'dy=${mark.dy - screen.dy}',
    );

    // Ao fim da entrada, a composição inteira fica centralizada (sobe).
    await tester.pump(const Duration(seconds: 2));
    expect(tester.getCenter(find.byType(GymTrackMark)).dy, lessThan(mark.dy));
  });

  testWidgets('espera o carregamento antes de sair da abertura', (
    tester,
  ) async {
    final loading = Completer<ThemeController>();
    await tester.pumpWidget(
      GymTrackBoot(initialize: () => loading.future, builder: _app),
    );

    // A animação termina, mas o app ainda está carregando.
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('app pronto'), findsNothing);

    loading.complete(ThemeController(persist: false));
    await tester.pumpAndSettle();
    expect(find.text('app pronto'), findsOneWidget);
  });

  testWidgets('falha no carregamento não prende o usuário na abertura', (
    tester,
  ) async {
    await tester.pumpWidget(
      GymTrackBoot(
        initialize: () => Future.error(Exception('falhou')),
        builder: _app,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('app pronto'), findsOneWidget);
  });
}
