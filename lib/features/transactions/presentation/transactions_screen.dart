import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ScreenPlaceholder(
        title: 'Transactions',
        description: 'The transaction list and filters arrive in stage 3.',
      ),
    );
  }
}
