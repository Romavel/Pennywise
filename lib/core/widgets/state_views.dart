import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../errors/app_failure.dart';

/// Centered spinner for screens that are loading data.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading'));
}

/// Shown when loading data failed.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  static String messageFor(Object error) =>
      error is AppFailure ? error.message : const UnexpectedFailure().message;

  @override
  Widget build(BuildContext context) {
    return MessageView(
      icon: Icons.cloud_off_outlined,
      title: 'Couldn’t load your data',
      message: messageFor(error),
      action: onRetry == null
          ? null
          : OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
    );
  }
}

/// Icon, title, explanation and an optional action — used for empty and
/// error states.
class MessageView extends StatelessWidget {
  const MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.pwColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 30, color: colors.mutedText),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: colors.mutedText),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              IntrinsicWidth(child: action),
            ],
          ],
        ),
      ),
    );
  }
}
