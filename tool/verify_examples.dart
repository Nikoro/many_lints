import 'dart:io';

/// Verifies that every runnable example triggers the rule named by its file.
///
/// The example package intentionally enables many_lints diagnostics, so a
/// normal `dart analyze example` exits non-zero and produces many expected
/// infos. This wrapper rejects analyzer errors and warnings while treating the
/// intended plugin infos as success.
Future<void> main() async {
  final result = await Process.run(Platform.resolvedExecutable, [
    'analyze',
    '--format',
    'machine',
    'example',
  ]);
  final output = '${result.stdout}\n${result.stderr}';
  final diagnostics = output
      .split('\n')
      .map(_Diagnostic.tryParse)
      .whereType<_Diagnostic>()
      .toList();

  final blocking = diagnostics
      .where((diagnostic) => diagnostic.severity != 'INFO')
      .toList();
  if (blocking.isNotEmpty) {
    stderr.writeln('Example analysis produced errors or warnings:');
    for (final diagnostic in blocking) {
      stderr.writeln(diagnostic.originalLine);
    }
    exitCode = 1;
    return;
  }

  const pathOnlyRules = {
    // These depend on the analyzed file's path. Their examples explain the
    // required layout because renaming/moving the files would break the
    // one-example-per-rule convention checked by the test suite.
    'match_lib_folder_structure',
    'prefer_correct_test_file_name',
  };
  final examples = Directory('example/lib').listSync().whereType<File>().where(
    (file) => file.path.endsWith('_example.dart'),
  );
  final missing = <String>[];

  for (final file in examples) {
    final fileName = file.uri.pathSegments.last;
    final ruleName = fileName.substring(
      0,
      fileName.length - '_example.dart'.length,
    );
    if (pathOnlyRules.contains(ruleName)) continue;

    final hasOwnDiagnostic = diagnostics.any(
      (diagnostic) =>
          diagnostic.code == ruleName && diagnostic.path.endsWith(fileName),
    );
    if (!hasOwnDiagnostic) missing.add(ruleName);
  }

  if (missing.isNotEmpty) {
    stderr.writeln(
      'Examples that do not trigger their own rule: ${missing.join(', ')}',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Verified ${examples.length} examples: no analyzer errors/warnings and '
    '${examples.length - pathOnlyRules.length} runnable rule demonstrations.',
  );
}

final class _Diagnostic {
  const _Diagnostic({
    required this.severity,
    required this.code,
    required this.path,
    required this.originalLine,
  });

  final String severity;
  final String code;
  final String path;
  final String originalLine;

  static _Diagnostic? tryParse(String line) {
    final fields = line.split('|');
    if (fields.length < 4) return null;
    final severity = fields[0];
    if (severity != 'INFO' && severity != 'WARNING' && severity != 'ERROR') {
      return null;
    }
    return _Diagnostic(
      severity: severity,
      code: fields[2].toLowerCase(),
      path: fields[3],
      originalLine: line,
    );
  }
}
