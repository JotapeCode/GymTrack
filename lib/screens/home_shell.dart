import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/training_controller.dart';
import '../theme/app_colors.dart';
import 'admin/users_screen.dart';
import 'dashboard_screen.dart';
import 'exercises_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

/// Abas do aplicativo. A aba "Usuários" só existe para administradores.
enum AppTab { home, exercises, history, profile, users }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppTab _tab = AppTab.home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthController>().currentUser;
      if (user != null) {
        context.read<TrainingController>().loadForUser(user.id!);
      }
    });
  }

  void _goTo(AppTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthController, bool>(
      (a) => a.currentUser?.isAdmin ?? false,
    );
    final tabs = [
      AppTab.home,
      AppTab.exercises,
      AppTab.history,
      if (isAdmin) AppTab.users,
      AppTab.profile,
    ];
    final current = tabs.contains(_tab) ? _tab : AppTab.home;

    final Widget page = switch (current) {
      AppTab.home => DashboardScreen(onNavigate: _goTo),
      AppTab.exercises => const ExercisesScreen(),
      AppTab.history => const HistoryScreen(),
      AppTab.users => const UsersScreen(),
      AppTab.profile => ProfileScreen(onNavigate: _goTo),
    };

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.015),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(current), child: page),
      ),
      // Contorno superior discreto separa a navegação do conteúdo rolável.
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
        child: NavigationBar(
          selectedIndex: tabs.indexOf(current),
          onDestinationSelected: (i) => _goTo(tabs[i]),
          destinations: [for (final tab in tabs) _destination(tab)],
        ),
      ),
    );
  }

  NavigationDestination _destination(AppTab tab) => switch (tab) {
    AppTab.home => const NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Início',
    ),
    AppTab.exercises => const NavigationDestination(
      icon: Icon(Icons.fitness_center_outlined),
      selectedIcon: Icon(Icons.fitness_center),
      label: 'Treinos',
    ),
    AppTab.history => const NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: 'Histórico',
    ),
    AppTab.users => const NavigationDestination(
      icon: Icon(Icons.admin_panel_settings_outlined),
      selectedIcon: Icon(Icons.admin_panel_settings),
      label: 'Usuários',
    ),
    AppTab.profile => const NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Perfil',
    ),
  };
}
