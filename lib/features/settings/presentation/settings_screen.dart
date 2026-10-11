import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/widgets/segmented_switch.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_validators.dart';
import '../../categories/data/category_providers.dart';
import '../data/profile_providers.dart';
import '../domain/user_profile.dart';
import 'delete_account_dialog.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final email = ref.watch(authStateProvider).value?.email ?? '';
    final categoryCount = ref.watch(categoryCatalogProvider).all.length;
    final busy = ref.watch(settingsControllerProvider).isLoading;
    final controller = ref.read(settingsControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    // Report failed saves; successful ones are visible in the UI already.
    ref.listen(settingsControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(ErrorView.messageFor(error))));
      }
    });

    if (profile == null) return const Scaffold(body: LoadingView());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            8,
            AppSpacing.screenHorizontal,
            24,
          ),
          children: [
            Text('Settings', style: textTheme.headlineMedium),
            const SizedBox(height: 14),
            _ProfileCard(name: profile.displayName, email: email),
            const SizedBox(height: 14),
            _Section(
              title: 'Profile',
              footnote: 'Changing currency doesn’t convert past amounts.',
              children: [
                _Row(
                  label: 'Display name',
                  value: profile.displayName,
                  onTap: busy
                      ? null
                      : () => _editName(context, controller, profile),
                ),
                _Row(
                  label: 'Base currency',
                  value: Currencies.label(profile.currency),
                  onTap: busy
                      ? null
                      : () => _pickCurrency(context, controller, profile),
                ),
                _Row(
                  label: 'Categories',
                  value: '$categoryCount',
                  onTap: () => context.push(AppRoutes.categories),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Appearance',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Theme', style: textTheme.bodyLarge),
                      const SizedBox(height: 10),
                      SegmentedSwitch(
                        segments: const [
                          (ThemeMode.light, 'Light'),
                          (ThemeMode.dark, 'Dark'),
                          (ThemeMode.system, 'System'),
                        ],
                        selected: profile.themeMode,
                        onChanged: busy ? null : controller.updateTheme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Account',
              footnote:
                  'Deleting your account permanently removes all '
                  'transactions, budgets and categories. You’ll be asked to '
                  'confirm.',
              children: [
                _ActionRow(
                  icon: Icons.logout,
                  label: 'Log out',
                  onTap: () => _signOut(context, ref),
                ),
                _ActionRow(
                  icon: Icons.delete_outline,
                  label: 'Delete account',
                  destructive: true,
                  onTap: () => showDeleteAccountDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '${AppInfo.name} ${AppInfo.version}',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    SettingsController controller,
    UserProfile profile,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: profile.displayName),
    );
    if (name != null && name.trim() != profile.displayName) {
      await controller.updateDisplayName(name);
    }
  }

  Future<void> _pickCurrency(
    BuildContext context,
    SettingsController controller,
    UserProfile profile,
  ) async {
    final code = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  'Base currency',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              RadioGroup<String>(
                groupValue: profile.currency,
                onChanged: (value) => Navigator.pop(context, value),
                child: Column(
                  children: [
                    for (final MapEntry(key: code, value: name)
                        in Currencies.supported.entries)
                      RadioListTile<String>(
                        value: code,
                        title: Text(code),
                        subtitle: Text(name),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (code != null && code != profile.currency) {
      await controller.updateCurrency(code);
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // The router moves to the auth screen once the auth state changes.
      await ref.read(authRepositoryProvider).signOut();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(ErrorView.messageFor(e))));
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.pwColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: scheme.primary,
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: context.pwColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase heading, a white group of rows and an optional note below.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.footnote});

  final String title;
  final List<Widget> children;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.72,
                color: colors.mutedText,
              ),
            ),
          ),
        ),
        Material(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) Divider(color: colors.divider),
                  child,
                ],
              ],
            ),
          ),
        ),
        if (footnote != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(footnote!, style: textTheme.bodySmall),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: colors.mutedText,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: colors.mutedText),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? context.pwColors.expense
        : Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: destructive ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Display name'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('display-name-field'),
          controller: _controller,
          autofocus: true,
          maxLength: UserProfile.maxNameLength,
          textCapitalization: TextCapitalization.words,
          validator: AuthValidators.displayName,
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
