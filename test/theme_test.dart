import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/controllers/theme_controller.dart';
import 'package:meu_app/theme/app_colors.dart';
import 'package:meu_app/theme/app_theme.dart';

/// Contraste WCAG entre duas cores (1 a 21).
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('tema escuro é o padrão e a troca notifica a interface', () async {
    final theme = ThemeController(persist: false);
    var notified = 0;
    theme.addListener(() => notified++);
    expect(theme.mode, ThemeMode.dark);

    await theme.setMode(ThemeMode.light);
    expect(theme.mode, ThemeMode.light);
    expect(notified, 1);

    await theme.setMode(ThemeMode.light);
    expect(notified, 1, reason: 'mesmo modo não deve reconstruir a tela');
  });

  test('cada tema expõe sua paleta', () {
    expect(AppTheme.dark.extension<AppPalette>()!.isDark, isTrue);
    expect(AppTheme.light.extension<AppPalette>()!.isDark, isFalse);
    expect(AppTheme.light.brightness, Brightness.light);
  });

  for (final p in [AppPalette.dark, AppPalette.light]) {
    final name = p.isDark ? 'escuro' : 'claro';

    test('textos têm contraste AA no tema $name', () {
      expect(contrast(p.textPrimary, p.card), greaterThanOrEqualTo(4.5));
      expect(contrast(p.textSecondary, p.card), greaterThanOrEqualTo(4.5));
      expect(
        contrast(p.textSecondary, p.background),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrast(p.onAccent, p.accent), greaterThanOrEqualTo(4.5));
      expect(contrast(p.accent, p.card), greaterThanOrEqualTo(3));
    });
  }

  test('cores claras de categoria escurecem no tema claro', () {
    const pink = Color(0xFFF472B6);
    expect(AppPalette.dark.adapt(pink), pink);
    final adapted = AppPalette.light.adapt(pink);
    expect(contrast(adapted, Colors.white), greaterThanOrEqualTo(4.5));
  });
}
