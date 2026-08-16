/// How a numeric literal's digit separators split it into groups, shared by
/// `avoid_inconsistent_digit_separators` and its fix so the diagnostic and the
/// edit agree on the regrouped form.
///
/// Only the part of the literal that carries separators is modelled. Dart
/// allows `_` in the fraction and exponent too, but grouping there follows the
/// opposite direction (left to right from the point), so each run is analysed
/// on its own terms rather than being flattened into one sequence.
class DigitSeparatorGrouping {
  /// The literal's prefix (`0x`, `0X`, `0b`) or the empty string.
  final String prefix;

  /// The digit groups of the integer part, in source order, so `1_000` gives
  /// `['1', '000']`.
  final List<String> groups;

  /// Everything after the integer part — the fraction, exponent and any type
  /// suffix — kept verbatim so regrouping never rewrites it.
  final String suffix;

  const DigitSeparatorGrouping({
    required this.prefix,
    required this.groups,
    required this.suffix,
  });

  /// Splits [lexeme] into its groups, or returns `null` when it carries no
  /// separators in the integer part or is not a shape this class understands.
  static DigitSeparatorGrouping? of(String lexeme) {
    var rest = lexeme;
    var prefix = '';

    for (final candidate in const ['0x', '0X', '0b', '0B']) {
      if (rest.startsWith(candidate)) {
        prefix = candidate;
        rest = rest.substring(candidate.length);
        break;
      }
    }

    // The integer part ends at the first character that is neither a digit of
    // the literal's base nor a separator.
    final digits = prefix.isEmpty
        ? RegExp(r'^[\d_]+')
        : RegExp(r'^[\da-fA-F_]+');
    final match = digits.firstMatch(rest);
    if (match == null) return null;

    final integerPart = match.group(0)!;
    final suffix = rest.substring(integerPart.length);

    if (!integerPart.contains('_')) return null;

    final groups = integerPart.split('_');
    // A leading, trailing or doubled separator is a syntax error Dart would
    // have rejected, so an empty group means the lexeme is not what it seems.
    if (groups.any((group) => group.isEmpty)) return null;

    return DigitSeparatorGrouping(
      prefix: prefix,
      groups: groups,
      suffix: suffix,
    );
  }

  bool get isHexadecimal => prefix == '0x' || prefix == '0X';

  /// The digits with every separator removed.
  String get digits => groups.join();

  /// Whether the grouping is regular for a group size of [expected].
  ///
  /// Every group but the first must be exactly [expected] long, and the first
  /// may be shorter — `1_000` is correct precisely because the leading group
  /// is what is left over. An [expected] of `0` means "any size", which still
  /// requires the groups to agree with each other.
  bool isConsistentWith(int expected) {
    if (groups.length < 2) return true;

    final size = expected > 0 ? expected : groups.last.length;
    final trailing = groups.skip(1);

    return trailing.every((group) => group.length == size) &&
        groups.first.length <= size &&
        groups.first.isNotEmpty;
  }

  /// A human-readable rendering of the current group sizes, as `2-2-3`.
  String describeGroups() => groups.map((group) => group.length).join('-');

  /// The literal rewritten with groups of [expected] digits, counted from the
  /// right.
  ///
  /// When [expected] is `0` the size is taken from the literal's own last
  /// group, so "any size, used consistently" has a canonical repair.
  String regrouped(int expected) {
    final size = expected > 0 ? expected : groups.last.length;
    if (size <= 0) return '$prefix$digits$suffix';

    final source = digits;
    final regrouped = <String>[];

    for (var end = source.length; end > 0; end -= size) {
      final start = end - size < 0 ? 0 : end - size;
      regrouped.insert(0, source.substring(start, end));
    }

    return '$prefix${regrouped.join('_')}$suffix';
  }
}
