import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'daram_colors.dart';

/// DARAM's independently designed light and dark themes.
abstract final class DaramTheme {
  static const String fontFamily = 'Vazirmatn';

  static ThemeData light() => _build(Brightness.light, DaramColors.light);

  static ThemeData dark() => _build(Brightness.dark, DaramColors.dark);

  static ThemeData _build(Brightness brightness, DaramColors colors) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: colors.accent,
            brightness: brightness,
          ).copyWith(
            primary: colors.accent,
            onPrimary: colors.onAccent,
            secondary: colors.transfer,
            surface: colors.surface,
            onSurface: colors.textPrimary,
            error: colors.expense,
            onError: Colors.white,
            outline: colors.border,
            outlineVariant: colors.divider,
          ),
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final text = _textTheme(colors);

    return base.copyWith(
      textTheme: text,
      primaryTextTheme: text,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: colors.textPrimary, size: 22),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DaramRadius.lg),
          side: BorderSide(color: colors.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: colors.textSecondary, size: 22),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: colors.textMuted),
        labelStyle: text.bodyMedium?.copyWith(color: colors.textSecondary),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: colors.accent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DaramRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DaramRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DaramRadius.md),
          borderSide: BorderSide(color: colors.accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DaramRadius.md),
          borderSide: BorderSide(color: colors.expense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DaramRadius.md),
          borderSide: BorderSide(color: colors.expense, width: 1.4),
        ),
        errorStyle: text.bodySmall?.copyWith(color: colors.expense),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          disabledBackgroundColor: colors.surfaceMuted,
          disabledForegroundColor: colors.textMuted,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DaramRadius.md),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          minimumSize: const Size(0, 50),
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DaramRadius.md),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: text.labelLarge?.copyWith(color: colors.accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DaramRadius.sm),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceMuted,
        selectedColor: colors.accentSoft,
        disabledColor: colors.surfaceMuted,
        labelStyle: text.labelMedium!,
        secondaryLabelStyle: text.labelMedium!.copyWith(color: colors.accent),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DaramRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DaramRadius.xl),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DaramRadius.xxl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: colors.border,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? colors.surfaceElevated : colors.textPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: isDark ? colors.textPrimary : Colors.white,
        ),
        actionTextColor: colors.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DaramRadius.md),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.surfaceMuted,
        circularTrackColor: colors.surfaceMuted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.navBar,
        indicatorColor: colors.accentSoft,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textSecondary,
        textColor: colors.textPrimary,
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DaramRadius.md),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.onAccent
              : colors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : colors.surfaceMuted,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.accent
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.onAccent
                : colors.textSecondary,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DaramRadius.sm),
            ),
          ),
          textStyle: WidgetStatePropertyAll(text.labelMedium),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DaramRadius.xl),
        ),
        headerBackgroundColor: colors.surfaceMuted,
        headerForegroundColor: colors.textPrimary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(DaramRadius.xs),
          border: Border.all(color: colors.border),
        ),
        textStyle: text.bodySmall,
        waitDuration: const Duration(milliseconds: 400),
      ),
      splashColor: colors.accent.withValues(alpha: 0.06),
      highlightColor: colors.accent.withValues(alpha: 0.04),
      hoverColor: colors.accent.withValues(alpha: 0.04),
    );
  }

  static TextTheme _textTheme(DaramColors colors) {
    TextStyle style(
      double size,
      FontWeight weight, {
      double height = 1.45,
      double? spacing,
    }) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      color: colors.textPrimary,
    );

    final secondaryStyle = style(14, FontWeight.w400);
    return TextTheme(
      displayLarge: style(36, FontWeight.w800, height: 1.15, spacing: -0.8),
      displayMedium: style(30, FontWeight.w800, height: 1.2, spacing: -0.6),
      displaySmall: style(26, FontWeight.w700, height: 1.25, spacing: -0.4),
      headlineLarge: style(24, FontWeight.w700, height: 1.3, spacing: -0.3),
      headlineMedium: style(21, FontWeight.w700, height: 1.3),
      headlineSmall: style(19, FontWeight.w600, height: 1.35),
      titleLarge: style(18, FontWeight.w600, height: 1.4),
      titleMedium: style(16, FontWeight.w600),
      titleSmall: style(14, FontWeight.w600),
      bodyLarge: style(15, FontWeight.w400, height: 1.75),
      bodyMedium: secondaryStyle.copyWith(height: 1.7),
      bodySmall: style(12.5, FontWeight.w400, height: 1.6),
      labelLarge: style(14, FontWeight.w600),
      labelMedium: style(12.5, FontWeight.w500),
      labelSmall: style(11.5, FontWeight.w500),
    );
  }
}
