import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/state_views.dart';
import 'settings_controller.dart';

Future<void> showDeleteAccountDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const DeleteAccountDialog(),
);

/// Asks for the password before permanently deleting the account. The
/// router leaves the signed-in screens once the user is signed out.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _password = TextEditingController();
  var _attempted = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() => _attempted = true);
    if (_password.text.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await ref
        .read(deleteAccountControllerProvider.notifier)
        .delete(_password.text);
    const deleted = SnackBar(
      content: Text('Your account and data were deleted.'),
    );
    // Signing out can remove this dialog together with the signed-in
    // screens; that only happens when the deletion succeeded.
    if (!mounted) {
      messenger.showSnackBar(deleted);
      return;
    }
    if (ref.read(deleteAccountControllerProvider).hasError) return;
    navigator.pop();
    messenger.showSnackBar(deleted);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deleteAccountControllerProvider);
    final busy = state.isLoading;
    final colors = context.pwColors;

    return AlertDialog(
      title: const Text('Delete account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This permanently deletes your account with all transactions, '
              'budgets and categories. It can’t be undone.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('delete-password-field'),
              controller: _password,
              enabled: !busy,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _delete(),
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _attempted && _password.text.isEmpty
                    ? 'Enter your password to confirm.'
                    : null,
              ),
            ),
            if (state.hasError) ...[
              const SizedBox(height: 12),
              ErrorBanner(message: ErrorView.messageFor(state.error!)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: colors.expense),
          onPressed: busy ? null : _delete,
          child: Text(busy ? 'Deleting…' : 'Delete account'),
        ),
      ],
    );
  }
}
