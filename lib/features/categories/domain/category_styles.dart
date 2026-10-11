import 'package:flutter/material.dart';

import '../../../app/theme/category_palette.dart';

/// Icons and colors a custom category can use. They are stored by key, so
/// renaming a key here would break existing categories — add, don't rename.
abstract final class CategoryStyles {
  static const icons = <String, IconData>{
    'cart': Icons.shopping_cart_outlined,
    'restaurant': Icons.restaurant_outlined,
    'coffee': Icons.local_cafe_outlined,
    'bus': Icons.directions_bus_outlined,
    'car': Icons.directions_car_outlined,
    'flight': Icons.flight_outlined,
    'home': Icons.home_outlined,
    'bag': Icons.shopping_bag_outlined,
    'play': Icons.play_circle_outline,
    'music': Icons.music_note_outlined,
    'fitness': Icons.fitness_center_outlined,
    'heart': Icons.favorite_border,
    'pets': Icons.pets_outlined,
    'child': Icons.child_care_outlined,
    'book': Icons.menu_book_outlined,
    'phone': Icons.smartphone_outlined,
    'gift': Icons.card_giftcard_outlined,
    'work': Icons.work_outline,
    'laptop': Icons.laptop_outlined,
    'trending': Icons.trending_up,
    'savings': Icons.savings_outlined,
    'cash': Icons.attach_money,
    'dots': Icons.more_horiz,
  };

  static const tones = <String, CategoryTone>{
    'orange': CategoryPalette.food,
    'blue': CategoryPalette.transport,
    'teal': CategoryPalette.housing,
    'yellow': CategoryPalette.shopping,
    'purple': CategoryPalette.entertainment,
    'red': CategoryPalette.health,
    'indigo': CategoryPalette.education,
    'green': CategoryPalette.income,
    'brown': CategoryTone(Color(0xFFF1E4D6), Color(0xFF6B4423)),
    'pink': CategoryTone(Color(0xFFF7E0EC), Color(0xFF8A2F5E)),
    'gray': CategoryPalette.other,
  };

  static const defaultIcon = 'dots';
  static const defaultTone = 'gray';

  static IconData icon(String? key) => icons[key] ?? icons[defaultIcon]!;
  static CategoryTone tone(String? key) => tones[key] ?? tones[defaultTone]!;
}
