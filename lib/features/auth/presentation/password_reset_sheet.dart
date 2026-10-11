import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../domain/auth_validators.dart';
import 'auth_controller.dart';

Future<void> showPasswordResetSheet(
  BuildContext context, {
  String initialEmail = '',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PasswordResetSheet(initialEmail: initialEmail),
  );
}

class PasswordResetSheet extends ConsumerStatefulWidget {
  const PasswordResetSheet({this.initialEmail = '', super.key});

  final String initialEmail;

  @override
  ConsumerState<PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends ConsumerState<PasswordResetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail.trim());

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(passwordResetControllerProvider.notifier).send(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetControllerProvider);
    final sent = state.value ?? false;
    final textTheme = Theme.of(context).textTheme;
    final muted = context.pwColors.mutedText;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Reset password', style: textTheme.headlineSmall),
            const SizedBox(height: 6),
            if (sent)
              Text(
                // Same message whether or not the account exists, so the
                // form cannot be used to discover registered emails.
                'If an account exists for ${_email.text.trim()}, '
                'we’ve sent a link to reset the password. '
                'Check your inbox and spam folder.',
                style: textTheme.bodyLarge?.copyWith(color: muted),
              )
            else ...[
              Text(
                'Enter your account email and we’ll send you a link '
                'to choose a new password.',
                style: textTheme.bodyLarge?.copyWith(color: muted),
              ),
              if (state.hasError) ...[
                const SizedBox(height: 16),
                ErrorBanner(
                  message: state.error is AppFailure
                      ? (state.error! as AppFailure).message
                      : const UnexpectedFailure().message,
                ),
              ],
              const SizedBox(height: 20),
              LabeledTextField(
                key: const Key('reset-email'),
                label: 'Email',
                controller: _email,
                hintText: 'you@example.com',
                validator: AuthValidators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.send,
                autofillHints: const [AutofillHints.email],
                onFieldSubmitted: (_) => _send(),
                enabled: !state.isLoading,
                autofocus: widget.initialEmail.isEmpty,
              ),
            ],
            const SizedBox(height: 24),
            if (sent)
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              )
            else
              FilledButton(
                onPressed: state.isLoading ? null : _send,
                child: Text(state.isLoading ? 'Sending…' : 'Send reset link'),
              ),
          ],
        ),
      ),
    );
  }
}
