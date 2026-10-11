import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

/// Add (no [transactionId]) or edit an existing transaction.
class TransactionFormScreen extends StatelessWidget {
  const TransactionFormScreen({this.transactionId, super.key});

  final String? transactionId;

  bool get isEditing => transactionId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const CloseButton()),
      body: ScreenPlaceholder(
        title: isEditing ? 'Edit transaction' : 'New transaction',
        description: 'The transaction form arrives in stage 3.',
      ),
    );
  }
}
