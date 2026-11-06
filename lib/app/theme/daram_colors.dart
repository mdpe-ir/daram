import 'package:flutter/material.dart';

/// Spacing scale (logical pixels).
abstract final class DaramSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}

/// Corner radii used across the app.
abstract final class DaramRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double pill = 999;
}

/// Semantic colours that are not part of Material's [ColorScheme].
///
/// Both themes define these independently rather than inverting one another.
@immutable
class DaramColors extends ThemeExtension<DaramColors> {
  const DaramColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceElevated,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.income,
    required this.expense,
    required this.transfer,
    required this.warning,
    required this.chatUser,
    required this.chatAssistant,
    required this.navBar,
    required this.gradientStart,
    required this.gradientEnd,
    required this.shadow,
    required this.isDark,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceElevated;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color income;
  final Color expense;
  final Color transfer;
  final Color warning;
  final Color chatUser;
  final Color chatAssistant;
  final Color navBar;
  final Color gradientStart;
  final Color gradientEnd;
  final Color shadow;
  final bool isDark;

  LinearGradient get brandGradient => LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get balanceGradient => LinearGradient(
    colors: isDark
        ? [
            const Color(0xFF2A2766),
            const Color(0xFF4C3D8F),
            const Color(0xFF1B2140),
          ]
        : [
            const Color(0xFF5B57E8),
            const Color(0xFF7C6BF0),
            const Color(0xFF9F7AEA),
          ],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const DaramColors dark = DaramColors(
    background: Color(0xFF080C15),
    surface: Color(0xFF0F1523),
    surfaceMuted: Color(0xFF141C2C),
    surfaceElevated: Color(0xFF192235),
    border: Color(0xFF232D41),
    divider: Color(0xFF1C2436),
    textPrimary: Color(0xFFF3F5FA),
    textSecondary: Color(0xFFA3AEC2),
    textMuted: Color(0xFF6E7A90),
    accent: Color(0xFF7C79FF),
    accentSoft: Color(0xFF221F48),
    onAccent: Colors.white,
    income: Color(0xFF2ED3A3),
    expense: Color(0xFFFF5C7A),
    transfer: Color(0xFF45C6F0),
    warning: Color(0xFFF0B45C),
    chatUser: Color(0xFF282355),
    chatAssistant: Color(0xFF121A2A),
    navBar: Color(0xFF0C121E),
    gradientStart: Color(0xFF6D6AF6),
    gradientEnd: Color(0xFFA78BFA),
    shadow: Color(0x66000000),
    isDark: true,
  );

  static const DaramColors light = DaramColors(
    background: Color(0xFFF4F6FB),
    surface: Colors.white,
    surfaceMuted: Color(0xFFEDF0F7),
    surfaceElevated: Colors.white,
    border: Color(0xFFE3E7F0),
    divider: Color(0xFFEDF0F5),
    textPrimary: Color(0xFF0B1220),
    textSecondary: Color(0xFF526078),
    textMuted: Color(0xFF8D97AA),
    accent: Color(0xFF5B57E8),
    accentSoft: Color(0xFFECEBFF),
    onAccent: Colors.white,
    income: Color(0xFF0E9F6E),
    expense: Color(0xFFE23D5A),
    transfer: Color(0xFF0C8FD8),
    warning: Color(0xFFD97706),
    chatUser: Color(0xFFECEBFF),
    chatAssistant: Colors.white,
    navBar: Colors.white,
    gradientStart: Color(0xFF5B57E8),
    gradientEnd: Color(0xFF8B5CF6),
    shadow: Color(0x140B1220),
    isDark: false,
  );

  @override
  DaramColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceElevated,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? income,
    Color? expense,
    Color? transfer,
    Color? warning,
    Color? chatUser,
    Color? chatAssistant,
    Color? navBar,
    Color? gradientStart,
    Color? gradientEnd,
    Color? shadow,
    bool? isDark,
  }) {
    return DaramColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      transfer: transfer ?? this.transfer,
      warning: warning ?? this.warning,
      chatUser: chatUser ?? this.chatUser,
      chatAssistant: chatAssistant ?? this.chatAssistant,
      navBar: navBar ?? this.navBar,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      shadow: shadow ?? this.shadow,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  DaramColors lerp(ThemeExtension<DaramColors>? other, double t) {
    if (other is! DaramColors) return this;
    return DaramColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      chatUser: Color.lerp(chatUser, other.chatUser, t)!,
      chatAssistant: Color.lerp(chatAssistant, other.chatAssistant, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// Convenient access to DARAM tokens from any widget.
extension DaramThemeX on BuildContext {
  DaramColors get daram =>
      Theme.of(this).extension<DaramColors>() ?? DaramColors.light;
  TextTheme get texts => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
