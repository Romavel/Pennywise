import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/pennywise_logo.dart';

/// Shown while Firebase starts. Navigation away is handled by the router
/// redirect once [firebaseInitProvider] succeeds.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  static const _subtle = Color(0xFFCFE3DD);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(firebaseInitProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppPalette.lightPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 64),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const PennywiseLogo(),
              const SizedBox(height: 22),
              Text(
                'Pennywise',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Know where your money goes.',
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: _subtle,
                ),
              ),
              const Spacer(flex: 3),
              if (init.hasError && !init.isLoading)
                _ErrorStatus(
                  error: init.error!,
                  onRetry: () => ref.invalidate(firebaseInitProvider),
                )
              else
                const _LoadingStatus(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingStatus extends StatelessWidget {
  const _LoadingStatus();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFFA8EBC9),
            backgroundColor: Color(0xFF2B6A62),
            semanticsLabel: 'Loading',
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Getting things ready…',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: SplashScreen._subtle),
        ),
      ],
    );
  }
}

class _ErrorStatus extends StatelessWidget {
  const _ErrorStatus({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is AppFailure
        ? (error as AppFailure).message
        : const UnexpectedFailure().message;

    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.accent,
            foregroundColor: AppPalette.onAccent,
          ),
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
      ],
    );
  }
}
