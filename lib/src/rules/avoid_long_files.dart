import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidLongFiles extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_long_files',
    'This file is {0} lines long, over the limit of {1}.',
    correctionMessage:
        'Split out the part that has its own subject, or raise max_lines.',
  );

  AvoidLongFiles()
    : super(
        name: 'avoid_long_files',
        description: 'Warns when a file exceeds the configured line budget.',
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

const _defaultMaxLines = 300;

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidLongFiles rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final maxLines = rule.config.intOption(
      'max_lines',
      defaultValue: _defaultMaxLines,
    );
    final countComments = rule.config.boolOption(
      'count_comments',
      defaultValue: false,
    );

    final length = countComments
        ? node.lineInfo.lineCount
        : _codeLineCount(node);
    if (length <= maxLines) return;

    // Edge case: a file has no single node, and reporting the unit would underline every line
    rule.reportAtOffset(0, 0, arguments: ['$length', '$maxLines']);
  }

  int _codeLineCount(CompilationUnit node) {
    final lineInfo = node.lineInfo;
    final lines = <int>{};

    for (
      var token = node.beginToken;
      !token.isEof;
      token = token.next ?? token
    ) {
      final first = lineInfo.getLocation(token.offset).lineNumber;
      final last = lineInfo.getLocation(token.end).lineNumber;
      // Edge case: a multi-line string is one token, yet every line it spans is code
      for (var line = first; line <= last; line++) {
        lines.add(line);
      }
    }

    return lines.length;
  }
}
