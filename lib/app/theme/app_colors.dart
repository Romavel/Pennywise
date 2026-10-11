import 'package:flutter/material.dart';

/// Raw color tokens from `docs/design/DESIGN_TOKENS.md`. Widgets should not
/// use these directly — read them through [ColorScheme] or [PennywiseColors].
abstract final class AppPalette {
  // Light
  static const lightBackground = Color(0xFFF3F5F4);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF12201E);
  static const lightMuted = Color(0xFF5B6663);
  static const lightPrimary = Color(0xFF0F4C45);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFDCEBE6);
  static const lightDivider = Color(0xFFEDF1EF);
  static const lightTrack = Color(0xFFE3E9E7);
  static const lightInputBorder = Color(0xFFD3DCD9);
  static const lightIncome = Color(0xFF14613F);
  static const lightExpense = Color(0xFFB23F0E);
  static const lightBudgetNear = Color(0xFFB7790F);
  static const lightBudgetOver = Color(0xFFC2410C);
  static const lightWarningBg = Color(0xFFFDE7DC);
  static const lightWarningFg = Color(0xFF9A3412);

  // Dark
  static const darkBackground = Color(0xFF0E1514);
  static const darkSurface = Color(0xFF18221F);
  static const darkText = Color(0xFFE8EEEC);
  static const darkMuted = Color(0xFF9AA8A3);
  static const darkPrimary = Color(0xFF4CC3A0);
  static const darkOnPrimary = Color(0xFF06201A);
  static const darkHeroCard = Color(0xFF14463F);
  static const darkNavPill = Color(0xFF1E3A34);
  static const darkNavActive = Color(0xFF7FD8BC);
  static const darkDivider = Color(0xFF24302D);
  static const darkTrack = Color(0xFF26332F);
  static const darkIncome = Color(0xFF6FD6A6);
  static const darkExpense = Color(0xFFF59A6E);
  static const darkBudgetNear = Color(0xFFF2B544);
  static const darkBudgetOver = Color(0xFFF2875A);
  // Not in the mockups; derived from the light warning pair.
  static const darkWarningBg = Color(0xFF3A2219);
  static const darkWarningFg = Color(0xFFF59A6E);

  // Shared
  static const accent = Color(0xFFE07B39);
  static const onAccent = Color(0xFF1B0E05);
}

/// App-specific semantic colors that [ColorScheme] has no slot for.
@immutable
class PennywiseColors extends ThemeExtension<PennywiseColors> {
  const PennywiseColors({
    required this.background,
    required this.card,
    required this.heroCard,
    required this.onHeroCard,
    required this.mutedText,
    required this.divider,
    required this.track,
    required this.accent,
    required this.onAccent,
    required this.income,
    required this.expense,
    required this.budgetOk,
    required this.budgetNear,
    required this.budgetOver,
    required this.warningBackground,
    required this.warningForeground,
  });

  static const light = PennywiseColors(
    background: AppPalette.lightBackground,
    card: AppPalette.lightSurface,
    heroCard: AppPalette.lightPrimary,
    onHeroCard: AppPalette.lightOnPrimary,
    mutedText: AppPalette.lightMuted,
    divider: AppPalette.lightDivider,
    track: AppPalette.lightTrack,
    accent: AppPalette.accent,
    onAccent: AppPalette.onAccent,
    income: AppPalette.lightIncome,
    expense: AppPalette.lightExpense,
    budgetOk: AppPalette.lightPrimary,
    budgetNear: AppPalette.lightBudgetNear,
    budgetOver: AppPalette.lightBudgetOver,
    warningBackground: AppPalette.lightWarningBg,
    warningForeground: AppPalette.lightWarningFg,
  );

  static const dark = PennywiseColors(
    background: AppPalette.darkBackground,
    card: AppPalette.darkSurface,
    heroCard: AppPalette.darkHeroCard,
    onHeroCard: AppPalette.darkText,
    mutedText: AppPalette.darkMuted,
    divider: AppPalette.darkDivider,
    track: AppPalette.darkTrack,
    accent: AppPalette.accent,
    onAccent: AppPalette.onAccent,
    income: AppPalette.darkIncome,
    expense: AppPalette.darkExpense,
    budgetOk: AppPalette.darkPrimary,
    budgetNear: AppPalette.darkBudgetNear,
    budgetOver: AppPalette.darkBudgetOver,
    warningBackground: AppPalette.darkWarningBg,
    warningForeground: AppPalette.darkWarningFg,
  );

  final Color background;
  final Color card;
  final Color heroCard;
  final Color onHeroCard;
  final Color mutedText;
  final Color divider;
  final Color track;
  final Color accent;
  final Color onAccent;
  final Color income;
  final Color expense;
  final Color budgetOk;
  final Color budgetNear;
  final Color budgetOver;
  final Color warningBackground;
  final Color warningForeground;

  @override
  PennywiseColors copyWith({
    Color? background,
    Color? card,
    Color? heroCard,
    Color? onHeroCard,
    Color? mutedText,
    Color? divider,
    Color? track,
    Color? accent,
    Color? onAccent,
    Color? income,
    Color? expense,
    Color? budgetOk,
    Color? budgetNear,
    Color? budgetOver,
    Color? warningBackground,
    Color? warningForeground,
  }) {
    return PennywiseColors(
      background: background ?? this.background,
      card: card ?? this.card,
      heroCard: heroCard ?? this.heroCard,
      onHeroCard: onHeroCard ?? this.onHeroCard,
      mutedText: mutedText ?? this.mutedText,
      divider: divider ?? this.divider,
      track: track ?? this.track,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      budgetOk: budgetOk ?? this.budgetOk,
      budgetNear: budgetNear ?? this.budgetNear,
      budgetOver: budgetOver ?? this.budgetOver,
      warningBackground: warningBackground ?? this.warningBackground,
      warningForeground: warningForeground ?? this.warningForeground,
    );
  }

  @override
  PennywiseColors lerp(PennywiseColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return PennywiseColors(
      background: l(background, other.background),
      card: l(card, other.card),
      heroCard: l(heroCard, other.heroCard),
      onHeroCard: l(onHeroCard, other.onHeroCard),
      mutedText: l(mutedText, other.mutedText),
      divider: l(divider, other.divider),
      track: l(track, other.track),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      income: l(income, other.income),
      expense: l(expense, other.expense),
      budgetOk: l(budgetOk, other.budgetOk),
      budgetNear: l(budgetNear, other.budgetNear),
      budgetOver: l(budgetOver, other.budgetOver),
      warningBackground: l(warningBackground, other.warningBackground),
      warningForeground: l(warningForeground, other.warningForeground),
    );
  }
}

extension PennywiseThemeX on BuildContext {
  PennywiseColors get pwColors => Theme.of(this).extension<PennywiseColors>()!;
}
