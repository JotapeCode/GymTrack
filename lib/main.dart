import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/training_controller.dart';
import 'controllers/user_admin_controller.dart';
import 'database/app_database.dart';
import 'repositories/exercise_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/workout_repository.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/password_service.dart';
import 'services/session_store.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';

  final passwordService = PasswordService();
  final database = AppDatabase(passwordService: passwordService);
  final userRepository = UserRepository(database, passwordService);
  final auth = AuthController(
    userRepository,
    session: SharedPrefsSessionStore(),
  );

  // A tela de abertura aparece imediatamente; o carregamento (datas,
  // sessão salva e tema) acontece enquanto ela é exibida.
  runApp(
    GymTrackBoot(
      initialize: () async {
        final (_, _, theme) = await (
          initializeDateFormatting('pt_BR'),
          auth.restoreSession(),
          ThemeController.load(),
        ).wait;
        return theme;
      },
      builder: (theme) => GymTrackApp(
        authController: auth,
        themeController: theme,
        userRepository: userRepository,
        exerciseRepository: ExerciseRepository(database),
        workoutRepository: WorkoutRepository(database),
      ),
    ),
  );
}

class GymTrackApp extends StatelessWidget {
  const GymTrackApp({
    super.key,
    required this.userRepository,
    required this.exerciseRepository,
    required this.workoutRepository,
    this.authController,
    this.themeController,
  });

  /// Preferência de tema já carregada; se nula, usa o tema escuro.
  final ThemeController? themeController;

  /// Controller já com a sessão restaurada; se nulo, cria um sem sessão salva.
  final AuthController? authController;

  final UserRepository userRepository;
  final ExerciseRepository exerciseRepository;
  final WorkoutRepository workoutRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => authController ?? AuthController(userRepository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              TrainingController(exerciseRepository, workoutRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => UserAdminController(userRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => themeController ?? ThemeController(persist: false),
        ),
      ],
      builder: (context, _) => MaterialApp(
        title: 'GymTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: context.watch<ThemeController>().mode,
        themeAnimationDuration: const Duration(milliseconds: 250),
        // Ícones da barra de status e de navegação acompanham o tema.
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.overlayFor(context.colors),
          child: child!,
        ),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _AuthGate(),
      ),
    );
  }
}

/// Exibe o login ou o app conforme a sessão.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthController, int?>((a) => a.currentUser?.id);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: user == null
          ? const LoginScreen()
          : HomeShell(key: ValueKey(user)),
    );
  }
}
