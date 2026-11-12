String fileBaseName(String relativePath) {
  final name = relativePath.split('/').last;
  return name.endsWith('.dart') ? name.substring(0, name.length - 5) : name;
}

bool hasIgnoredSuffix(String relativePath, List<String> suffixes) {
  if (suffixes.isEmpty) return false;

  final name = relativePath.split('/').last;
  return suffixes.any((suffix) => suffix.isNotEmpty && name.endsWith(suffix));
}

String toSnakeCase(String identifier) {
  final buffer = StringBuffer();

  for (var i = 0; i < identifier.length; i++) {
    final char = identifier[i];
    if (!_isUpper(char)) {
      buffer.write(char);
      continue;
    }

    final isFirst = i == 0;
    final followsLower = !isFirst && !_isUpper(identifier[i - 1]);
    // Edge case: the last capital of a run starts the next word, like the `C` of `HTTPClient`
    final endsRun =
        !isFirst &&
        _isUpper(identifier[i - 1]) &&
        i + 1 < identifier.length &&
        !_isUpper(identifier[i + 1]) &&
        identifier[i + 1] != '_';

    if (followsLower || endsRun) buffer.write('_');
    buffer.write(char.toLowerCase());
  }

  return buffer.toString();
}

bool _isUpper(String char) {
  final code = char.codeUnitAt(0);
  return code >= 0x41 && code <= 0x5A;
}
