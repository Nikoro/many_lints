class DoubleLiteralParts {
  final String whole;

  final String fraction;

  final String exponent;

  const DoubleLiteralParts({
    required this.whole,
    required this.fraction,
    required this.exponent,
  });

  static DoubleLiteralParts? tryParse(String lexeme) {
    if (lexeme.isEmpty || lexeme.contains('_')) return null;

    var mantissa = lexeme;
    var exponent = '';

    final exponentIndex = lexeme.indexOf(RegExp('[eE]'));
    if (exponentIndex >= 0) {
      mantissa = lexeme.substring(0, exponentIndex);
      exponent = lexeme.substring(exponentIndex);
    }

    final dotIndex = mantissa.indexOf('.');
    final whole = dotIndex < 0 ? mantissa : mantissa.substring(0, dotIndex);
    final fraction = dotIndex < 0 ? '' : mantissa.substring(dotIndex + 1);

    if (!_isDigits(whole) || !_isDigits(fraction)) return null;
    if (mantissa.indexOf('.') != mantissa.lastIndexOf('.')) return null;

    return DoubleLiteralParts(
      whole: whole,
      fraction: fraction,
      exponent: exponent,
    );
  }

  bool get hasMissingLeadingZero => whole.isEmpty && fraction.isNotEmpty;

  bool get hasRedundantLeadingZeros =>
      whole.length > 1 && whole.startsWith('0');

  bool get hasTrailingZeros => fraction.length > 1 && fraction.endsWith('0');

  String normalized() {
    final normalizedWhole = _stripLeadingZeros(whole);

    // Edge case: `1.0` keeps one zero, since `1.` is not valid Dart and `1` is an int
    var normalizedFraction = fraction;
    while (normalizedFraction.length > 1 && normalizedFraction.endsWith('0')) {
      normalizedFraction = normalizedFraction.substring(
        0,
        normalizedFraction.length - 1,
      );
    }

    if (normalizedFraction.isEmpty) {
      return exponent.isEmpty
          ? '$normalizedWhole.0'
          : '$normalizedWhole$exponent';
    }

    return '$normalizedWhole.$normalizedFraction$exponent';
  }

  static String _stripLeadingZeros(String digits) {
    var index = 0;
    while (index < digits.length - 1 && digits[index] == '0') {
      index++;
    }
    final stripped = digits.substring(index);
    return stripped.isEmpty ? '0' : stripped;
  }

  static bool _isDigits(String value) =>
      value.isEmpty || RegExp(r'^\d+$').hasMatch(value);
}
