import 'package:flutter/material.dart';

/// Paleta do GymTrack, com uma versão para cada tema.
///
/// As cores são lidas do tema atual com `context.colors`, então toda a
/// interface acompanha a troca entre modo claro e escuro.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.card,
    required this.cardHighlight,
    required this.border,
    required this.accent,
    required this.accentDark,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.error,
    required this.warning,
    required this.info,
    required this.highlight,
    required this.snackBackground,
    required this.snackForeground,
  });

  final Brightness brightness;

  /// Fundo das telas.
  final Color background;

  /// Superfície de cards, campos e barra de navegação.
  final Color card;

  /// Superfície elevada: menus, trilhos de progresso, campos internos.
  final Color cardHighlight;

  /// Contornos e divisórias.
  final Color border;

  /// Verde da marca: ações principais e indicadores positivos.
  final Color accent;
  final Color accentDark;

  /// Texto e ícones sobre o verde da marca.
  final Color onAccent;

  final Color textPrimary;
  final Color textSecondary;

  final Color error;
  final Color warning;
  final Color info;

  /// Cor de apoio para indicadores (ex.: frequência semanal).
  final Color highlight;

  final Color snackBackground;
  final Color snackForeground;

  bool get isDark => brightness == Brightness.dark;

  /// Tema escuro — identidade oficial do GymTrack (#0F172A / #22C55E).
  /// Superfícies próximas do fundo e texto levemente acinzentado para
  /// reduzir o cansaço visual.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0F172A),
    card: Color(0xFF172135),
    cardHighlight: Color(0xFF1F2B42),
    border: Color(0xFF26334B),
    accent: Color(0xFF22C55E),
    accentDark: Color(0xFF16A34A),
    onAccent: Color(0xFF052E16),
    textPrimary: Color(0xFFE6EBF2),
    textSecondary: Color(0xFF94A3B8),
    error: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF38BDF8),
    highlight: Color(0xFFF472B6),
    snackBackground: Color(0xFF26334B),
    snackForeground: Color(0xFFE6EBF2),
  );

  /// Tema claro — fundo cinza-azulado suave, superfícies brancas e tons
  /// mais escuros das cores de destaque para manter o contraste (AA).
  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF3F5F9),
    card: Color(0xFFFFFFFF),
    cardHighlight: Color(0xFFEDF1F6),
    border: Color(0xFFE1E7EF),
    accent: Color(0xFF15803D),
    accentDark: Color(0xFF166534),
    onAccent: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF5A6A82),
    error: Color(0xFFDC2626),
    warning: Color(0xFFB45309),
    info: Color(0xFF0369A1),
    highlight: Color(0xFFBE185D),
    snackBackground: Color(0xFF1E293B),
    snackForeground: Color(0xFFF1F5F9),
  );

  /// Ajusta uma cor de categoria (ex.: grupo muscular) ao tema: no modo
  /// claro, escurece tons muito luminosos para manter a legibilidade.
  Color adapt(Color color) {
    if (isDark) return color;
    final hsl = HSLColor.fromColor(color);
    return hsl.lightness > 0.38 ? hsl.withLightness(0.38).toColor() : color;
  }

  /// Fundo translúcido para ícones e etiquetas de uma cor.
  Color tint(Color color) => color.withValues(alpha: isDark ? 0.14 : 0.10);

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: l(background, other.background),
      card: l(card, other.card),
      cardHighlight: l(cardHighlight, other.cardHighlight),
      border: l(border, other.border),
      accent: l(accent, other.accent),
      accentDark: l(accentDark, other.accentDark),
      onAccent: l(onAccent, other.onAccent),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      error: l(error, other.error),
      warning: l(warning, other.warning),
      info: l(info, other.info),
      highlight: l(highlight, other.highlight),
      snackBackground: l(snackBackground, other.snackBackground),
      snackForeground: l(snackForeground, other.snackForeground),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}

/// Espaçamentos e raios padronizados.
///
/// Raios seguem a hierarquia: cards (16) > campos e botões (12) > ícones e
/// etiquetas (10 / 8).
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const radius = 16.0;
  static const radiusSm = 12.0;
}
