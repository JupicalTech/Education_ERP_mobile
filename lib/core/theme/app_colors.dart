import 'package:flutter/material.dart';

/// Central color palette for the Education ERP design system.
///
/// To change the brand primary color across the entire app, update [primary].
abstract final class AppColors {
  // Brand colors — change [primary] here to re-theme the whole app.
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF7C3AED);

  // Light surfaces & neutrals (cool off-white canvas, pure white cards)
  static const Color lightBackground = Color(0xFFF4F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEEF3FA);
  static const Color lightBorder = Color(0xFFE5ECF6);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark surfaces & neutrals
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF283548);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Semantic status colors (attendance, fees, and dashboard accents)
  static const Color successLight = Color(0xFF16A34A);
  static const Color successContainerLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF4ADE80);
  static const Color successContainerDark = Color(0xFF14532D);

  static const Color warningLight = Color(0xFFD97706);
  static const Color warningContainerLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color warningContainerDark = Color(0xFF451A03);

  static const Color errorLight = Color(0xFFDC2626);
  static const Color errorContainerLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFF87171);
  static const Color errorContainerDark = Color(0xFF450A0A);

  static const Color infoLight = Color(0xFF2563EB);
  static const Color infoContainerLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF60A5FA);
  static const Color infoContainerDark = Color(0xFF1E3A8A);

  static const Color accentLight = Color(0xFF7C3AED);
  static const Color accentContainerLight = Color(0xFFEDE9FE);
  static const Color accentDark = Color(0xFFA78BFA);
  static const Color accentContainerDark = Color(0xFF2E1065);
}

/// Theme extension exposing semantic status & pastel accent colors.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.error,
    required this.errorContainer,
    required this.info,
    required this.infoContainer,
    required this.accent,
    required this.accentContainer,
  });

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final Color info;
  final Color infoContainer;
  final Color accent;
  final Color accentContainer;

  static const light = AppSemanticColors(
    success: AppColors.successLight,
    successContainer: AppColors.successContainerLight,
    warning: AppColors.warningLight,
    warningContainer: AppColors.warningContainerLight,
    error: AppColors.errorLight,
    errorContainer: AppColors.errorContainerLight,
    info: AppColors.infoLight,
    infoContainer: AppColors.infoContainerLight,
    accent: AppColors.accentLight,
    accentContainer: AppColors.accentContainerLight,
  );

  static const dark = AppSemanticColors(
    success: AppColors.successDark,
    successContainer: AppColors.successContainerDark,
    warning: AppColors.warningDark,
    warningContainer: AppColors.warningContainerDark,
    error: AppColors.errorDark,
    errorContainer: AppColors.errorContainerDark,
    info: AppColors.infoDark,
    infoContainer: AppColors.infoContainerDark,
    accent: AppColors.accentDark,
    accentContainer: AppColors.accentContainerDark,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? error,
    Color? errorContainer,
    Color? info,
    Color? infoContainer,
    Color? accent,
    Color? accentContainer,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      accent: accent ?? this.accent,
      accentContainer: accentContainer ?? this.accentContainer,
    );
  }

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
    );
  }
}

extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
