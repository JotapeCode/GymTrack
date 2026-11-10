import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/controllers/training_controller.dart';
import 'package:meu_app/models/workout.dart';

Workout _workout(List<(int reps, double weight)> sets, {int id = 1}) => Workout(
  id: id,
  userId: 1,
  exerciseId: 1,
  date: DateTime(2026, 11, 1),
  sets: [
    for (final (i, (reps, weight)) in sets.indexed)
      WorkoutSet(setNumber: i + 1, reps: reps, weight: weight),
  ],
);

void main() {
  group('1RM estimado (Epley)', () {
    test('calcula carga × (1 + reps/30)', () {
      const set = WorkoutSet(setNumber: 1, reps: 10, weight: 60);
      expect(set.estimatedOneRepMax, closeTo(80, 0.001));
    });

    test('com 1 repetição é a própria carga', () {
      const set = WorkoutSet(setNumber: 1, reps: 1, weight: 100);
      expect(set.estimatedOneRepMax, 100);
    });

    test('treino usa a melhor série', () {
      final w = _workout([(12, 50), (8, 60), (5, 65)]);
      // 50×1,4=70 · 60×1,267=76 · 65×1,167=75,8
      expect(w.bestOneRepMax, closeTo(76, 0.01));
    });

    test('treino sem séries tem 1RM zero', () {
      expect(_workout([]).bestOneRepMax, 0);
    });
  });

  group('Recorde pessoal', () {
    test('mesma carga com mais repetições é recorde', () {
      final before = _workout([(8, 80)], id: 1);
      final now = _workout([(12, 80)], id: 2);
      expect(TrainingController.isRecordOver(now, [before]), isTrue);
    });

    test('mesma carga e repetições não é recorde', () {
      final before = _workout([(8, 80)], id: 1);
      final now = _workout([(8, 80)], id: 2);
      expect(TrainingController.isRecordOver(now, [before]), isFalse);
    });

    test('mais carga com bem menos repetições pode não ser recorde', () {
      final before = _workout([(12, 80)], id: 1); // 1RM 112
      final now = _workout([(2, 85)], id: 2); // 1RM 90,7
      expect(TrainingController.isRecordOver(now, [before]), isFalse);
    });

    test('primeiro registro nunca é recorde', () {
      expect(
        TrainingController.isRecordOver(_workout([(5, 100)]), []),
        isFalse,
      );
    });
  });
}
