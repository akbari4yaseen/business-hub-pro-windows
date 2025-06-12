import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class NumberInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat("#,##0.##");

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(',', '');
    if (text.isEmpty) return newValue;
    final value = double.tryParse(text);
    if (value == null) return oldValue;
    final newText = _formatter.format(value);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}



class NumberInput extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat("#,##0.##");

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;

    // Allow just the decimal point or incomplete decimals like "1."
    if (newText == '.' || newText.endsWith('.')) {
      return newValue;
    }

    // Remove commas
    final rawText = newText.replaceAll(',', '');

    // Allow empty input
    if (rawText.isEmpty) return newValue;

    // Check if it’s a valid double
    final value = double.tryParse(rawText);
    if (value == null) {
      return oldValue;
    }

    // Format the number
    String formatted = _formatter.format(value);

    // Preserve decimal point if user typed "."
    if (rawText.contains('.') && !formatted.contains('.')) {
      formatted += '.';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

