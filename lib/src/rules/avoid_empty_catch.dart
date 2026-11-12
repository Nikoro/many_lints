import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidEmptyCatch extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_empty_catch',
    'This catch clause silently discards the failure.',
    correctionMessage:
        'Log it, rethrow it, wrap it, or return a fallback the caller can '
        'see.',
  );

  AvoidEmptyCatch()
    : super(
        name: 'avoid_empty_catch',
        description:
            'Warns when a catch clause does nothing with the exception it '
            'caught.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addTryStatement(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidEmptyCatch rule;

  _Visitor(this.rule);

  @override
  void visitTryStatement(TryStatement node) {
    final allowWithComment = rule.config.boolOption(
      'allow_with_comment',
      defaultValue: false,
    );

    for (final catchClause in node.catchClauses) {
      final body = catchClause.body;
      if (body.statements.isNotEmpty) continue;

      if (allowWithComment && _hasComment(body)) continue;

      rule.reportAtNode(catchClause);
    }
  }

  // Edge case: a comment in an empty block hangs off the closing brace
  bool _hasComment(Block body) => body.rightBracket.precedingComments != null;
}
