import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Shape and spacing tokens shared by widgets.
abstract final class AppSpacing {
  static const screenHorizontal = 20.0;
  static const screenTop = 52.0;
  static const sectionGap = 16.0;
  static const minTouchTarget = 44.0;
}

abstract final class AppRadii {
  static const card = 20.0;
  static const listGroup = 16.0;
  static const input = 14.0;
  static const iconTile = 12.0;
  static const button = 16.0;
  static const fab = 20.0;
}

abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    colors: PennywiseColors.light,
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.lightPrimary,
      onPrimary: AppPalette.lightOnPrimary,
      primaryContainer: AppPalette.lightPrimaryContainer,
      onPrimaryContainer: AppPalette.lightPrimary,
      secondary: AppPalette.accent,
      onSecondary: AppPalette.onAccent,
      error: AppPalette.lightBudgetOver,
      onError: Colors.white,
      errorContainer: AppPalette.lightWarningBg,
      onErrorContainer: AppPalette.lightWarningFg,
      surface: AppPalette.lightBackground,
      onSurface: AppPalette.lightText,
      onSurfaceVariant: AppPalette.lightMuted,
      surfaceContainerLowest: AppPalette.lightSurface,
      surfaceContainerLow: AppPalette.lightSurface,
      surfaceContainer: AppPalette.lightSurface,
      surfaceContainerHigh: AppPalette.lightSurface,
      surfaceContainerHighest: AppPalette.lightTrack,
      outline: AppPalette.lightInputBorder,
      outlineVariant: AppPalette.lightTrack,
    ),
    navIndicator: AppPalette.lightPrimaryContainer,
    navSelected: AppPalette.lightPrimary,
    navSurface: AppPalette.lightSurface,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colors: PennywiseColors.dark,
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppPalette.darkPrimary,
      onPrimary: AppPalette.darkOnPrimary,
      primaryContainer: AppPalette.darkNavPill,
      onPrimaryContainer: AppPalette.darkNavActive,
      secondary: AppPalette.accent,
      onSecondary: AppPalette.onAccent,
      error: AppPalette.darkBudgetOver,
      onError: AppPalette.darkOnPrimary,
      errorContainer: AppPalette.darkWarningBg,
      onErrorContainer: AppPalette.darkWarningFg,
      surface: AppPalette.darkBackground,
      onSurface: AppPalette.darkText,
      onSurfaceVariant: AppPalette.darkMuted,
      surfaceContainerLowest: AppPalette.darkSurface,
      surfaceContainerLow: AppPalette.darkSurface,
      surfaceContainer: AppPalette.darkSurface,
      surfaceContainerHigh: AppPalette.darkSurface,
      surfaceContainerHighest: AppPalette.darkTrack,
      outline: AppPalette.darkDivider,
      outlineVariant: AppPalette.darkDivider,
    ),
    navIndicator: AppPalette.darkNavPill,
    navSelected: AppPalette.darkNavActive,
    navSurface: AppPalette.darkSurface,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required PennywiseColors colors,
    required Color navIndicator,
    required Color navSelected,
    required Color navSurface,
  }) {
    final textTheme = AppTypography.textTheme(
      scheme.onSurface,
      colors.mutedText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(color: colors.mutedText),
        hintStyle: textTheme.bodyLarge?.copyWith(color: colors.mutedText),
        border: _inputBorder(scheme.outline),
        enabledBorder: _inputBorder(scheme.outline),
        focusedBorder: _inputBorder(scheme.primary, width: 2),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 2),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        elevation: 6,
        highlightElevation: 8,
        sizeConstraints: const BoxConstraints.tightFor(width: 60, height: 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.fab),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: navSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: navIndicator,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? textTheme.labelSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: navSelected,
                )
              : textTheme.labelSmall!.copyWith(color: colors.mutedText),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? navSelected
                : colors.mutedText,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: colors.track,
          selectedBackgroundColor: colors.card,
          selectedForegroundColor: scheme.onSurface,
          foregroundColor: colors.mutedText,
          side: BorderSide.none,
          textStyle: textTheme.labelMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: colors.track),
        backgroundColor: colors.card,
        selectedColor: scheme.primary,
        labelStyle: textTheme.labelMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: colors.track,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: color, width: width),
      );
}
