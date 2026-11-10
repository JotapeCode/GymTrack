import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda a preferência de tema (escuro, claro ou do sistema).
/// O padrão é o tema escuro, identidade original do GymTrack.
class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode initial = ThemeMode.dark, this.persist = true})
    : _mode = initial;

  static const _key = 'theme_mode';

  /// Desligado nos testes, que não têm acesso ao armazenamento do aparelho.
  final bool persist;

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  /// Lê a preferência salva antes de abrir o app.
  static Future<ThemeController> load() async {
    try {
      final saved = await SharedPreferencesAsync().getString(_key);
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.dark,
      );
      return ThemeController(initial: mode);
    } catch (_) {
      return ThemeController();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    if (!persist) return;
    try {
      await SharedPreferencesAsync().setString(_key, mode.name);
    } catch (_) {
      // A troca já foi aplicada; só não ficará salva.
    }
  }
}
