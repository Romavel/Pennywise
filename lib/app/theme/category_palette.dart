import 'package:flutter/material.dart';

/// Tile background / icon color pair for a category.
@immutable
class CategoryTone {
  const CategoryTone(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

/// Colors of the built-in categories, keyed by their stable ids.
abstract final class CategoryPalette {
  static const food = CategoryTone(Color(0xFFFBE6D7), Color(0xFF9A4A16));
  static const transport = CategoryTone(Color(0xFFDDEBF3), Color(0xFF245E80));
  static const housing = CategoryTone(Color(0xFFDCE7EA), Color(0xFF173F4F));
  static const shopping = CategoryTone(Color(0xFFFBF0D2), Color(0xFF7A5B0E));
  static const entertainment = CategoryTone(
    Color(0xFFECE4F3),
    Color(0xFF5B3F7A),
  );
  static const health = CategoryTone(Color(0xFFF7E0E0), Color(0xFF8E2F2F));
  static const education = CategoryTone(Color(0xFFE2E8F6), Color(0xFF2E4A8A));
  static const other = CategoryTone(Color(0xFFE8ECEA), Color(0xFF3F4A47));
  static const income = CategoryTone(Color(0xFFDCEFE5), Color(0xFF14613F));

  /// Series colors for the spending chart, light theme. "Other" is darker
  /// than in the mockup (#B9C2BE), which was too close to Shopping's yellow
  /// to tell apart (OKLab ΔE 14 < 15); #8C9692 passes at ΔE 22.
  static const chartHousing = Color(0xFF173F4F);
  static const chartFood = Color(0xFFE07B39);
  static const chartTransport = Color(0xFF5C9EC4);
  static const chartShopping = Color(0xFFF2C14E);
  static const chartOther = Color(0xFF8C9692);

  /// The same series, stepped for the dark surface (from the dark mockup).
  static const chartHousingDark = Color(0xFF3E7F96);
  static const chartFoodDark = Color(0xFFE8894A);
  static const chartTransportDark = Color(0xFF9CCDE8);
  static const chartShoppingDark = Color(0xFFF2C14E);
  static const chartOtherDark = Color(0xFF5E6B67);
}
