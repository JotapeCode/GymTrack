import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const fontFamily = 'Inter';

  static ThemeData get dark => build(AppPalette.dark);
  static ThemeData get light => build(AppPalette.light);

  /// Estilo das barras do sistema (status e navegação) para cada tema.
  static SystemUiOverlayStyle overlayFor(AppPalette p) => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: p.isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: p.isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: p.card,
    systemNavigationBarIconBrightness: p.isDark
        ? Brightness.light
        : Brightness.dark,
  );

  static ThemeData build(AppPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.accent,
      onSecondary: p.onAccent,
      surface: p.card,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerHighest: p.cardHighlight,
      surfaceContainerHigh: p.card,
      surfaceContainer: p.card,
      surfaceContainerLow: p.card,
      error: p.error,
      onError: p.isDark ? p.background : Colors.white,
      outline: p.border,
      outlineVariant: p.border,
      inverseSurface: p.snackBackground,
      onInverseSurface: p.snackForeground,
    );

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
    );
    const buttonText = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 15,
      letterSpacing: 0,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: p.background,
      extensions: [p],
    );

    // Inter é desenhada para espaçamento neutro: o tracking padrão do
    // Material 3 (+0,25 / +0,5) deixa o texto "esticado". Títulos ganham
    // tracking levemente negativo, como em interfaces de produto.
    TextStyle style(
      double size,
      FontWeight weight,
      Color color, {
      double spacing = 0,
      double height = 1.35,
    }) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
    );

    final textTheme = base.textTheme
        .apply(
          fontFamily: fontFamily,
          bodyColor: p.textPrimary,
          displayColor: p.textPrimary,
        )
        .copyWith(
          headlineMedium: style(
            26,
            FontWeight.w700,
            p.textPrimary,
            spacing: -0.6,
            height: 1.2,
          ),
          headlineSmall: style(
            22,
            FontWeight.w700,
            p.textPrimary,
            spacing: -0.4,
            height: 1.25,
          ),
          titleLarge: style(
            20,
            FontWeight.w700,
            p.textPrimary,
            spacing: -0.3,
            height: 1.3,
          ),
          titleMedium: style(16, FontWeight.w600, p.textPrimary, spacing: -0.1),
          titleSmall: style(14, FontWeight.w600, p.textPrimary),
          bodyLarge: style(16, FontWeight.w400, p.textPrimary, height: 1.45),
          bodyMedium: style(14.5, FontWeight.w400, p.textPrimary, height: 1.45),
          bodySmall: style(13, FontWeight.w400, p.textSecondary, height: 1.4),
          labelLarge: style(14, FontWeight.w600, p.textPrimary),
          labelMedium: style(12.5, FontWeight.w500, p.textSecondary),
          labelSmall: style(11.5, FontWeight.w500, p.textSecondary),
        );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: textTheme,
      dividerColor: p.border,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlayFor(p),
        titleTextStyle: style(
          19,
          FontWeight.w700,
          p.textPrimary,
          spacing: -0.3,
        ),
        iconTheme: IconThemeData(color: p.textPrimary),
        actionsIconTheme: IconThemeData(color: p.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          side: BorderSide(color: p.border),
        ),
      ),
      iconTheme: IconThemeData(color: p.textSecondary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: p.textSecondary),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (s) => TextStyle(
            color: s.contains(WidgetState.error)
                ? p.error
                : s.contains(WidgetState.focused)
                ? p.accent
                : p.textSecondary,
          ),
        ),
        hintStyle: TextStyle(color: p.textSecondary.withValues(alpha: 0.8)),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
        errorStyle: TextStyle(color: p.error, fontSize: 12.5),
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        disabledBorder: inputBorder(p.border.withValues(alpha: 0.6)),
        focusedBorder: inputBorder(p.accent, 1.5),
        errorBorder: inputBorder(p.error),
        focusedErrorBorder: inputBorder(p.error, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.cardHighlight,
          disabledForegroundColor: p.textSecondary,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: roundedShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: p.border),
          shape: roundedShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          shape: roundedShape,
          textStyle: buttonText.copyWith(fontSize: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.textSecondary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        elevation: p.isDark ? 2 : 3,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
        extendedTextStyle: buttonText,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: p.tint(p.accent),
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            letterSpacing: 0,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? p.accent
                : p.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? p.accent
                : p.textSecondary,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.tint(p.accent),
        side: BorderSide(color: p.border),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: p.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: fontFamily,
          color: p.accent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        checkmarkColor: p.accent,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: p.card,
          foregroundColor: p.textSecondary,
          selectedBackgroundColor: p.tint(p.accent),
          selectedForegroundColor: p.accent,
          side: BorderSide(color: p.border),
          textStyle: buttonText.copyWith(fontSize: 13.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: style(
          19,
          FontWeight.w700,
          p.textPrimary,
          spacing: -0.3,
        ),
        contentTextStyle: style(
          14.5,
          FontWeight.w400,
          p.textSecondary,
          height: 1.45,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius + 4),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.border,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.snackBackground,
        elevation: 2,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: p.snackForeground,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      popupMenuTheme: PopupMenuThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        textStyle: style(14.5, FontWeight.w500, p.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          side: BorderSide(color: p.border),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.card,
        headerForegroundColor: p.textPrimary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.cardHighlight,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? p.onAccent : p.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.cardHighlight,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
