import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ScreenPlaceholder(
        title: 'Reports',
        description: 'Charts and monthly reports arrive in stage 5.',
      ),
    );
  }
}
