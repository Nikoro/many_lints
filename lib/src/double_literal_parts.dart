/// A double literal split into the parts that decide whether it is formatted
/// correctly, shared by `double_literal_format` and its fix so that the rule's
/// message and the fix's edit can never disagree about the normalized form.
///
/// Only the decimal form is modelled. A hexadecimal literal cannot be a
/// `DoubleLiteral` in Dart, and an integer literal is out of scope, so the
/// parser rejects anything it does not fully understand rather than guessing —
/// a literal this class cannot describe is left alone.
class DoubleLiteralParts {
  /// Digits before the `.`, which is empty for `.5`.
  final String whole;

  /// Digits after the `.`, which is empty for `5e3` and for `5.` (which Dart
  /// does not accept, but which the parser still handles rather than crashing).
  final String fraction;

  /// The exponent suffix including its `e`, or the empty string when absent.
  ///
  /// Kept verbatim: `1.50e10` and `1.50E10` differ only in a character the
  /// rule has no opinion about, and rewriting it would make the fix touch
  /// something the diagnostic never mentioned.
  final String exponent;

  const DoubleLiteralParts({
    required this.whole,
    required this.fraction,
    required this.exponent,
  });

  /// Splits [lexeme] into its parts, or returns `null` when it is not a plain
  /// decimal double literal.
  ///
  /// Digit separators are rejected rather than normalized: `1_000.50` is
  /// `avoid_inconsistent_digit_separators`' territory, and stripping a
  /// trailing zero from it would have to decide where the separators land
  /// afterwards.
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

  /// Whether the literal is written as `.5` rather than `0.5`.
  bool get hasMissingLeadingZero => whole.isEmpty && fraction.isNotEmpty;

  /// Whether the literal carries more leading zeros than the single one that
  /// `0.5` needs, as in `00.5` or `01.5`.
  bool get hasRedundantLeadingZeros =>
      whole.length > 1 && whole.startsWith('0');

  /// Whether the fraction ends in a zero that changes nothing, as in `0.50`.
  ///
  /// A single `0` is never redundant: `1.0` cannot lose it without becoming
  /// `1.` (invalid) or the integer `1` (a different type).
  bool get hasTrailingZeros => fraction.length > 1 && fraction.endsWith('0');

  /// The literal rewritten with exactly one leading zero and no redundant
  /// trailing zeros.
  String normalized() {
    final normalizedWhole = _stripLeadingZeros(whole);

    // Stops at one digit, so `1.0` keeps its zero — `1.` is not valid Dart and
    // `1` is an int.
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
