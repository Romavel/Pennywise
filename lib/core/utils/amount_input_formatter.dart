import 'package:flutter/services.dart';

/// Lets an amount field accept only digits with at most one decimal
/// separator ("." or ",") and two decimals.
final amountInputFormatter = TextInputFormatter.withFunction(
  (oldValue, newValue) =>
      _allowed.hasMatch(newValue.text) ? newValue : oldValue,
);

final _allowed = RegExp(r'^\d{0,10}([.,]\d{0,2})?$');
