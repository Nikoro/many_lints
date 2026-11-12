import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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

    final segments = path.split('/');
    final foldersBetweenRootAndFile = segments.sublist(1, segments.length - 1);

    final firstInvalidFolder = foldersBetweenRootAndFile
        .where((folder) => !_validFolder.hasMatch(folder))
        .firstOrNull;
    if (firstInvalidFolder == null) return;

    rule.reportAtOffset(
      0,
      0,
      arguments: [firstInvalidFolder, _toSnakeCase(firstInvalidFolder)],
    );
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
