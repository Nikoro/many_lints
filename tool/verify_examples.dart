import 'dart:io';

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

  const filePathDependentRules = {
    // Edge case: moving these examples would break the one-example-per-rule convention
    'match_lib_folder_structure',
    'prefer_correct_test_file_name',
    // Edge case: the example package has no test tree, so its example suppresses the rule
    'require_mirror_test',
  };
  final examples = Directory('example/lib').listSync().whereType<File>().where(
    (file) => file.path.endsWith('_example.dart'),
  );
  final missing = <String>[];
  final expectedRuleByFile = <String, String>{};

  for (final file in examples) {
    final fileName = file.uri.pathSegments.last;
    final ruleName = fileName.substring(
      0,
      fileName.length - '_example.dart'.length,
    );
    expectedRuleByFile[fileName] = ruleName;
    if (filePathDependentRules.contains(ruleName)) continue;

    final hasOwnDiagnostic = diagnostics.any(
      (diagnostic) =>
          diagnostic.code == ruleName && diagnostic.path.endsWith(fileName),
    );
    if (!hasOwnDiagnostic) missing.add(ruleName);
  }

  final unexpected = diagnostics.where((diagnostic) {
    final fileName = Uri.file(diagnostic.path).pathSegments.last;
    final expectedRule = expectedRuleByFile[fileName];
    return expectedRule == null || diagnostic.code != expectedRule;
  }).toList();

  if (missing.isNotEmpty) {
    stderr.writeln(
      'Examples that do not trigger their own rule: ${missing.join(', ')}',
    );
    exitCode = 1;
    return;
  }

  if (unexpected.isNotEmpty) {
    stderr.writeln(
      'Example analysis produced diagnostics outside the rule demonstrated '
      'by each file:',
    );
    for (final diagnostic in unexpected) {
      stderr.writeln(diagnostic.originalLine);
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Verified ${examples.length} isolated examples: no analyzer '
    'errors/warnings or cross-rule diagnostics, and '
    '${examples.length - filePathDependentRules.length} runnable rule demonstrations.',
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
