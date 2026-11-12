class DigitSeparatorGrouping {
  final String prefix;

  final List<String> groups;

  final String suffix;

  const DigitSeparatorGrouping({
    required this.prefix,
    required this.groups,
    required this.suffix,
  });

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

    final digits = prefix.isEmpty
        ? RegExp(r'^[\d_]+')
        : RegExp(r'^[\da-fA-F_]+');
    final match = digits.firstMatch(rest);
    if (match == null) return null;

    final integerPart = match.group(0)!;
    final suffix = rest.substring(integerPart.length);

    if (!integerPart.contains('_')) return null;

    final groups = integerPart.split('_');
    // Edge case: Dart rejects stray separators, so an empty group means an unexpected lexeme
    if (groups.any((group) => group.isEmpty)) return null;

    return DigitSeparatorGrouping(
      prefix: prefix,
      groups: groups,
      suffix: suffix,
    );
  }

  bool get isHexadecimal => prefix == '0x' || prefix == '0X';

  String get digits => groups.join();

  bool isConsistentWith(int expected) {
    if (groups.length < 2) return true;

    final size = expected > 0 ? expected : groups.last.length;
    final trailing = groups.skip(1);

    return trailing.every((group) => group.length == size) &&
        groups.first.length <= size &&
        groups.first.isNotEmpty;
  }

  String describeGroups() => groups.map((group) => group.length).join('-');

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
