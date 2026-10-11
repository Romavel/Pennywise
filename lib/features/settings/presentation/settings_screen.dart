import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/screen_placeholder.dart';
import '../../auth/data/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(authStateProvider).value;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: ScreenPlaceholder(
        title: 'Settings',
        description: 'Profile, currency and account options arrive in stage 6.',
        children: [
          if (user != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(user.displayName ?? 'Your account'),
                subtitle: Text(user.email),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
          ],
          Text('Theme', style: textTheme.labelMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) =>
                ref.read(themeModeProvider.notifier).set(selection.single),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Card(
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categories'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.categories),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }

  // The router moves to the auth screen once the auth state changes.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on AppFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
