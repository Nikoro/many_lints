import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a file is longer than the configured budget.
///
/// A long file is where a module stops having a single subject: the name at
/// the top no longer describes everything below it, and finding the right
/// place to add something becomes a scroll rather than a decision. Enforcing
/// the budget in the analyzer puts the signal where splitting is still cheap.
///
/// The limit is `max_lines`, defaulting to 300. Blank lines and comments are
/// not counted by default, since a file is not hard to navigate because it is
/// well documented — set `count_comments: true` to include them.
///
/// Generated files are the obvious exception and are best handled with the
/// per-rule `exclude`, which every rule in this package supports:
///
/// ```yaml
/// rules:
///   avoid_long_files:
///     exclude: ["**/*.g.dart", "**/*.freezed.dart"]
/// ```
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

/// Long enough that a file reaching it usually covers more than one subject.
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

    // A file has no single node to point at, and reporting the whole unit
    // would underline every line in the editor. The first token is the
    // smallest anchor that still lands in the right file.
    rule.reportAtOffset(0, 0, arguments: ['$length', '$maxLines']);
  }

  /// Lines holding something other than whitespace or a comment.
  ///
  /// Counted from the token stream rather than by scanning text, so a `//`
  /// inside a string literal cannot be mistaken for a comment.
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
      // A multi-line string is one token spanning several lines, and every
      // one of them is code.
      for (var line = first; line <= last; line++) {
        lines.add(line);
      }
    }

    return lines.length;
  }
}
