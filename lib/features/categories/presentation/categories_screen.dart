import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: const ScreenPlaceholder(
        title: 'Categories',
        description: 'Built-in and custom categories arrive in stage 6.',
      ),
    );
  }
}
