import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meu_app/models/workout.dart';
import 'package:meu_app/theme/app_theme.dart';
import 'package:meu_app/widgets/progress_chart.dart';

Workout _workout(int day, double weight) => Workout(
  id: day,
  userId: 1,
  exerciseId: 1,
  date: DateTime(2026, 11, day),
  sets: [WorkoutSet(setNumber: 1, reps: 10, weight: weight)],
);

Widget _app(ThemeData theme, List<Workout> workouts) => MaterialApp(
  theme: theme,
  home: Scaffold(body: ProgressChart(workouts: workouts)),
);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  for (final (name, theme) in [
    ('escuro', AppTheme.dark),
    ('claro', AppTheme.light),
  ]) {
    testWidgets('desenha o gráfico com 2+ treinos no tema $name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(theme, [_workout(1, 40), _workout(4, 45), _workout(8, 50)]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData.single.spots, hasLength(3));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('com 1 treino mostra orientação em vez do gráfico', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AppTheme.dark, [_workout(1, 40)]));

    expect(find.byType(LineChart), findsNothing);
    expect(find.textContaining('pelo menos 2 treinos'), findsOneWidget);
  });
}
