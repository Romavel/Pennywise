import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ScreenPlaceholder(
        title: 'Welcome',
        description: 'Log in and sign up arrive in stage 2.',
      ),
    );
  }
}
