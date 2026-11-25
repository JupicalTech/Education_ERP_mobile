import 'package:flutter/material.dart';

/// Central color palette for the Education ERP design system.
///
/// To change the brand primary color across the entire app, update [primary].
abstract final class AppColors {
  // Brand colors — change [primary] here to re-theme the whole app.
  static const Color primary = Color(0xFF2457A6);
  static const Color secondary = Color(0xFF2E7D87);

  // Light surfaces & neutrals (warm off-white canvas, pure white cards)
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEEF1F6);
  static const Color lightBorder = Color(0xFFE2E6EE);
  static const Color lightTextPrimary = Color(0xFF1A2130);
  static const Color lightTextSecondary = Color(0xFF5A657A);

  // Dark surfaces & neutrals
  static const Color darkBackground = Color(0xFF11151E);
  static const Color darkSurface = Color(0xFF19202C);
  static const Color darkSurfaceVariant = Color(0xFF232C3D);
  static const Color darkBorder = Color(0xFF2E384D);
  static const Color darkTextPrimary = Color(0xFFF1F4F9);
  static const Color darkTextSecondary = Color(0xFFA6B1C4);

  // Semantic status colors (attendance & fee states)
  static const Color successLight = Color(0xFF1B7F4E);
  static const Color successContainerLight = Color(0xFFE5F6ED);
  static const Color successDark = Color(0xFF5AD094);
  static const Color successContainerDark = Color(0xFF133B27);

  static const Color warningLight = Color(0xFFB4690E);
  static const Color warningContainerLight = Color(0xFFFFF4E2);
  static const Color warningDark = Color(0xFFF5B851);
  static const Color warningContainerDark = Color(0xFF3E2A0B);

  static const Color errorLight = Color(0xFFC53939);
  static const Color errorContainerLight = Color(0xFFFDECEC);
  static const Color errorDark = Color(0xFFF28B82);
  static const Color errorContainerDark = Color(0xFF471B1B);

  static const Color infoLight = Color(0xFF2563EB);
  static const Color infoContainerLight = Color(0xFFEAF1FF);
  static const Color infoDark = Color(0xFF8AB4F8);
  static const Color infoContainerDark = Color(0xFF172C4D);
}

/// Theme extension exposing semantic status colors for attendance and fees.
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
  });

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final Color info;
  final Color infoContainer;

  static const light = AppSemanticColors(
    success: AppColors.successLight,
    successContainer: AppColors.successContainerLight,
    warning: AppColors.warningLight,
    warningContainer: AppColors.warningContainerLight,
    error: AppColors.errorLight,
    errorContainer: AppColors.errorContainerLight,
    info: AppColors.infoLight,
    infoContainer: AppColors.infoContainerLight,
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
    );
  }
}

extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
