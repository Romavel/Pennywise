import 'package:flutter/material.dart';

import '../domain/category.dart';

/// Category icon on its colored tile.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    required this.category,
    this.size = 40,
    this.radius = 12,
    super.key,
  });

  final Category category;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tone = category.tone;
    // The pastel tiles from the design are for light surfaces; on dark ones
    // use a tinted tile and a lighter icon instead.
    final background = dark
        ? tone.foreground.withValues(alpha: 0.28)
        : tone.background;
    final foreground = dark
        ? Color.lerp(tone.foreground, Colors.white, 0.6)!
        : tone.foreground;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(category.icon, size: size * 0.5, color: foreground),
    );
  }
}
