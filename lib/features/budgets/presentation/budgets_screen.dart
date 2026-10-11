import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ScreenPlaceholder(
        title: 'Budgets',
        description: 'Monthly category budgets arrive in stage 5.',
      ),
    );
  }
}
