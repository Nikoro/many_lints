/// Shared machinery for the rules that check a file's *path* rather than its
/// AST — `prefer_match_file_name`, `prefer_correct_test_file_name`,
/// `match_lib_folder_structure` and `format_test_name`.
///
/// All four reduce to comparing one identifier against one path segment, so
/// the segment extraction and the identifier-to-snake_case conversion live
/// here rather than being rewritten four times with four sets of edge cases.
library;

/// The file name at the end of [relativePath], without its `.dart` extension.
///
/// `lib/data/user_repository.dart` → `user_repository`.
String fileBaseName(String relativePath) {
  final name = relativePath.split('/').last;
  return name.endsWith('.dart') ? name.substring(0, name.length - 5) : name;
}

/// Whether [relativePath]'s file name ends with any of [suffixes].
///
/// Matched against the base name rather than the whole path, so `.g.dart`
/// means "generated file" and cannot be accidentally satisfied by a directory
/// that happens to end the same way. Comparison includes the extension, since
/// `.g.dart` is how users write these and stripping it first would force them
/// to write `.g` instead.
bool hasIgnoredSuffix(String relativePath, List<String> suffixes) {
  if (suffixes.isEmpty) return false;

  final name = relativePath.split('/').last;
  return suffixes.any((suffix) => suffix.isNotEmpty && name.endsWith(suffix));
}

/// [identifier] converted to the `lower_snake_case` a file name uses.
///
/// `UserRepository` → `user_repository`, `HTTPClient` → `http_client`,
/// `Pin2Code` → `pin2_code`.
///
/// The acronym handling is the part worth getting right: a naive
/// "underscore before every capital" turns `HTTPClient` into
/// `h_t_t_p_client`, so a run of capitals is kept together and broken only
/// before the last one, which belongs to the following word.
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
    // The last capital of a run starts the next word: the `C` of `HTTPClient`.
    final endsRun =
        !isFirst &&
        _isUpper(identifier[i - 1]) &&
        i + 1 < identifier.length &&
        !_isUpper(identifier[i + 1]) &&
        identifier[i + 1] != '_';

    if (followsLower || endsRun) buffer.write('_');
    buffer.write(char.toLowerCase());
  }

  // A leading underscore survives from a private name; the caller decides
  // whether privacy matters, so it is not stripped here.
  return buffer.toString();
}

bool _isUpper(String char) {
  final code = char.codeUnitAt(0);
  return code >= 0x41 && code <= 0x5A;
}
