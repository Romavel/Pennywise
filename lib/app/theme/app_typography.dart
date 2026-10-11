import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bricolage Grotesque for display text and amounts, DM Sans for UI.
abstract final class AppTypography {
  static const tabularFigures = [FontFeature.tabularFigures()];

  static TextTheme textTheme(Color textColor, Color mutedColor) {
    TextStyle display(double size, {double letterSpacing = -0.02}) =>
        GoogleFonts.bricolageGrotesque(
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: size * letterSpacing,
          height: 1.15,
          color: textColor,
          fontFeatures: tabularFigures,
        );

    TextStyle body(
      double size, {
      FontWeight weight = FontWeight.w400,
      Color? color,
    }) => GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      height: 1.35,
      color: color ?? textColor,
    );

    return TextTheme(
      // Balance on the dashboard hero card.
      displaySmall: display(36, letterSpacing: -0.03),
      // Screen titles.
      headlineMedium: display(28),
      // Amounts on summary cards.
      headlineSmall: display(22),
      titleLarge: body(18, weight: FontWeight.w700),
      titleMedium: body(16, weight: FontWeight.w600),
      titleSmall: body(15, weight: FontWeight.w600),
      bodyLarge: body(15),
      bodyMedium: body(15),
      bodySmall: body(12, color: mutedColor),
      labelLarge: body(15, weight: FontWeight.w600),
      labelMedium: body(13, weight: FontWeight.w500),
      labelSmall: body(11, weight: FontWeight.w500),
    );
  }
}
