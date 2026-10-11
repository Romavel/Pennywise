import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

class BudgetDetailScreen extends StatelessWidget {
  const BudgetDetailScreen({required this.budgetId, super.key});

  final String budgetId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: const ScreenPlaceholder(
        title: 'Budget',
        description: 'Budget details arrive in stage 5.',
      ),
    );
  }
}
