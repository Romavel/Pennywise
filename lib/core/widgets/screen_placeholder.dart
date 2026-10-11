import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

/// Temporary body for screens that are built in later stages. Uses the real
/// screen title layout so navigation and theming can be checked end to end.
class ScreenPlaceholder extends StatelessWidget {
  const ScreenPlaceholder({
    required this.title,
    required this.description,
    this.children = const [],
    super.key,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          8,
          AppSpacing.screenHorizontal,
          96,
        ),
        children: [
          Text(title, style: textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            description,
            style: textTheme.bodyLarge?.copyWith(
              color: context.pwColors.mutedText,
            ),
          ),
          if (children.isNotEmpty)
            const SizedBox(height: AppSpacing.sectionGap),
          ...children,
        ],
      ),
    );
  }
}
