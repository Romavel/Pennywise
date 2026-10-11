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

  /// Series colors for charts (spending by category).
  static const chartHousing = Color(0xFF173F4F);
  static const chartFood = Color(0xFFE07B39);
  static const chartTransport = Color(0xFF5C9EC4);
  static const chartShopping = Color(0xFFF2C14E);
  static const chartOther = Color(0xFFB9C2BE);
}
