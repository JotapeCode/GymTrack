import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meu_app/database/app_database.dart';
import 'package:meu_app/main.dart';
import 'package:meu_app/repositories/exercise_repository.dart';
import 'package:meu_app/repositories/user_repository.dart';
import 'package:meu_app/repositories/workout_repository.dart';
import 'package:meu_app/services/password_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('pt_BR');
  });

  GymTrackApp buildApp() {
    final passwords = PasswordService(iterations: 10);
    final db = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      passwordService: passwords,
    );
    return GymTrackApp(
      userRepository: UserRepository(db, passwords),
      exerciseRepository: ExerciseRepository(db),
      workoutRepository: WorkoutRepository(db),
    );
  }

  testWidgets('login valida campos obrigatórios', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Informe o e-mail'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login_email')), 'invalido');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();
    expect(find.text('E-mail inválido'), findsOneWidget);
  });

  testWidgets('admin entra e vê a aba de usuários', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login_email')),
      'admin@gymtrack.com',
    );
    await tester.enterText(find.byKey(const Key('login_password')), 'admin123');
    await tester.tap(find.byKey(const Key('login_submit')));
    // O banco FFI roda fora do relógio falso do teste: alterna tempo real
    // e frames até o dashboard carregar.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining(', Administrador'), findsOneWidget);
    expect(find.text('Usuários'), findsOneWidget);
    expect(find.text('Treinos'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });
}
