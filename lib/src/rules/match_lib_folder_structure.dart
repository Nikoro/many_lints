import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a file under `lib/` sits in a folder whose name is not
/// `lower_snake_case`.
///
/// A folder name becomes part of every `package:` URI that imports through it,
/// so it is public API in a way a local variable name is not. `CamelCase` or
/// `kebab-case` folders also break on case-insensitive filesystems: a folder
/// renamed from `Models` to `models` is invisible to git on macOS, and the
/// import keeps resolving locally while failing in CI.
///
/// The SDK's `file_names` rule checks the *file*; nothing in the SDK checks
/// the directories above it, which is the gap this fills.
class MatchLibFolderStructure extends ManyLintsRule {
  static const LintCode code = LintCode(
    'match_lib_folder_structure',
    "The folder '{0}' is not lower_snake_case.",
    correctionMessage: "Rename it to '{1}'.",
  );

  MatchLibFolderStructure()
    : super(
        name: 'match_lib_folder_structure',
        description:
            'Warns when a folder under lib/ is not named in lower_snake_case.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static final _validFolder = RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$');

  final MatchLibFolderStructure rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = rule.relativePath;
    if (path == null) return;

    final root = rule.config.stringOption('root', defaultValue: 'lib');
    if (!path.startsWith('$root/')) return;

    // Drop the root and the file itself; what is left is the folders between
    // them, which are what this rule is about.
    final segments = path.split('/');
    final folders = segments.sublist(1, segments.length - 1);

    for (final folder in folders) {
      if (_validFolder.hasMatch(folder)) continue;

      // Reported once per file, at the first offending folder: a second
      // diagnostic on the same path would be fixed by the same rename, and
      // every file in the folder already reports it once.
      rule.reportAtOffset(0, 0, arguments: [folder, _toSnakeCase(folder)]);
      return;
    }
  }

  String _toSnakeCase(String folder) {
    final buffer = StringBuffer();

    for (var i = 0; i < folder.length; i++) {
      final char = folder[i];
      if (char == '-' || char == ' ') {
        buffer.write('_');
        continue;
      }

      final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
      if (isUpper && i > 0 && folder[i - 1] != '_' && folder[i - 1] != '-') {
        buffer.write('_');
      }
      buffer.write(char.toLowerCase());
    }

    return buffer.toString();
  }
}
