import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../../core/widgets/pennywise_logo.dart';
import '../../../core/widgets/segmented_switch.dart';
import '../domain/auth_validators.dart';
import 'auth_controller.dart';
import 'password_reset_sheet.dart';

enum AuthMode { login, signup }

/// Log in / sign up. On success the router leaves this screen by itself,
/// reacting to the new auth state.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  // Replaced on mode change to drop validation messages but keep the text.
  var _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _mode = AuthMode.login;
  var _passwordVisible = false;

  bool get _isSignup => _mode == AuthMode.signup;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setMode(AuthMode mode) {
    if (mode == _mode) return;
    ref.read(authControllerProvider.notifier).reset();
    setState(() {
      _mode = mode;
      _formKey = GlobalKey<FormState>();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    if (_isSignup) {
      await controller.signUp(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
      );
    } else {
      await controller.signIn(email: _email.text, password: _password.text);
    }
    if (mounted && !ref.read(authControllerProvider).hasError) {
      TextInput.finishAutofillContext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.pwColors;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: PennywiseLogo(size: 56, elevated: false),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _isSignup ? 'Create your account' : 'Welcome back',
                          style: textTheme.headlineMedium?.copyWith(
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isSignup
                              ? 'Track income, expenses and budgets in one place.'
                              : 'Log in to see your balance and budgets.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SegmentedSwitch(
                          segments: const [
                            (AuthMode.login, 'Log in'),
                            (AuthMode.signup, 'Sign up'),
                          ],
                          selected: _mode,
                          onChanged: isLoading ? null : _setMode,
                        ),
                        if (state.hasError) ...[
                          const SizedBox(height: 16),
                          ErrorBanner(message: _messageFor(state.error!)),
                        ],
                        const SizedBox(height: 24),
                        if (_isSignup) ...[
                          LabeledTextField(
                            key: const Key('auth-name'),
                            label: 'Display name',
                            controller: _name,
                            validator: AuthValidators.displayName,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.nickname],
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 14),
                        ],
                        LabeledTextField(
                          key: const Key('auth-email'),
                          label: 'Email',
                          controller: _email,
                          hintText: 'you@example.com',
                          validator: AuthValidators.email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 14),
                        LabeledTextField(
                          key: const Key('auth-password'),
                          label: 'Password',
                          controller: _password,
                          obscureText: !_passwordVisible,
                          helperText: _isSignup
                              ? 'At least ${AuthValidators.minPasswordLength} characters.'
                              : null,
                          validator: _isSignup
                              ? AuthValidators.newPassword
                              : AuthValidators.loginPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: [
                            _isSignup
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          onFieldSubmitted: (_) => _submit(),
                          enabled: !isLoading,
                          suffix: IconButton(
                            tooltip: _passwordVisible
                                ? 'Hide password'
                                : 'Show password',
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                          ),
                        ),
                        if (!_isSignup)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => showPasswordResetSheet(
                                      context,
                                      initialEmail: _email.text,
                                    ),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                        const Spacer(),
                        const SizedBox(height: 24),
                        FilledButton(
                          // Keeps the primary color while the request runs.
                          style: FilledButton.styleFrom(
                            disabledBackgroundColor: isLoading
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    semanticsLabel: 'Please wait',
                                  ),
                                )
                              : Text(_isSignup ? 'Create account' : 'Log in'),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: colors.mutedText,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Your data stays private and syncs across devices.',
                                style: textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _messageFor(Object error) =>
      error is AppFailure ? error.message : const UnexpectedFailure().message;
}
