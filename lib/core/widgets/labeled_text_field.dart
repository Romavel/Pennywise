import 'package:flutter/material.dart';

/// Text field with its label above the input, as used across the app's forms.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    required this.label,
    this.controller,
    this.validator,
    this.hintText,
    this.helperText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.suffix,
    this.onFieldSubmitted,
    this.enabled = true,
    this.autofocus = false,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final String? hintText;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The input below carries the label for screen readers.
        ExcludeSemantics(
          child: Text(
            label,
            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: label,
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            obscureText: obscureText,
            autocorrect: !obscureText,
            enableSuggestions: !obscureText,
            onFieldSubmitted: onFieldSubmitted,
            enabled: enabled,
            autofocus: autofocus,
            style: textTheme.bodyLarge?.copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: hintText,
              helperText: helperText,
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}
