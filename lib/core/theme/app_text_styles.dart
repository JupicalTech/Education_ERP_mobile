import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale built on Google Fonts' Inter for high legibility across
/// mobile dashboards, dense fee tables, and web views.
abstract final class AppTextStyles {
  static TextTheme buildTextTheme(TextTheme base, ColorScheme scheme) {
    final fontFamily = GoogleFonts.inter().fontFamily;
    final inter = base.apply(fontFamily: fontFamily);

    return inter
        .copyWith(
          headlineMedium: inter.headlineMedium?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          headlineSmall: inter.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleLarge: inter.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: inter.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: inter.titleSmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: inter.bodyLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
          bodyMedium: inter.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
          bodySmall: inter.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
          labelLarge: inter.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: inter.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: inter.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        )
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
  }
}
