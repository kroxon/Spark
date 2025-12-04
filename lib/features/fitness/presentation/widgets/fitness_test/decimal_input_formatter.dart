import 'package:flutter/services.dart';

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;
    
    // Allow empty
    if (newText.isEmpty) return newValue;

    // Replace comma with dot for validation
    String normalized = newText.replaceAll(',', '.');
    
    // Allow only one dot/comma
    if ('.'.allMatches(normalized).length > 1) {
      return oldValue;
    }

    // Validate format: digits, optional dot/comma, optional digits
    // Regex: ^\d*([.,]\d*)?$
    final regExp = RegExp(r'^\d*([.,]\d*)?$');
    if (!regExp.hasMatch(newText)) {
      return oldValue;
    }

    return newValue;
  }
}
