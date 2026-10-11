import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/app/theme/app_colors.dart';
import 'package:pennywise/app/theme/app_theme.dart';

void main() {
  test('light and dark themes carry the Pennywise color tokens', () {
    expect(AppTheme.light.extension<PennywiseColors>(), PennywiseColors.light);
    expect(AppTheme.dark.extension<PennywiseColors>(), PennywiseColors.dark);
    expect(AppTheme.light.colorScheme.primary, AppPalette.lightPrimary);
    expect(AppTheme.dark.colorScheme.primary, AppPalette.darkPrimary);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });

  test('PennywiseColors.lerp interpolates between themes', () {
    final mid = PennywiseColors.light.lerp(PennywiseColors.dark, 0.5);
    expect(
      mid.income,
      Color.lerp(AppPalette.lightIncome, AppPalette.darkIncome, 0.5),
    );
    expect(PennywiseColors.light.lerp(null, 0.5), PennywiseColors.light);
  });
}
