import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidRedundantElse extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_redundant_else',
    "This 'else' is redundant because the if branch always exits.",
    correctionMessage:
        "Remove the 'else' and move its body to the enclosing scope.",
  );

  AvoidRedundantElse()
    : super(
        name: 'avoid_redundant_else',
        description:
            'Warns when an else branch follows an if branch that always '
            'returns, throws, continues or breaks.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addIfStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidRedundantElse rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    final elseKeyword = node.elseKeyword;
    if (elseKeyword == null) return;

    if (node.elseStatement is IfStatement) return;

    if (!_alwaysExits(node.thenStatement)) return;

    rule.reportAtToken(elseKeyword);
  }

  bool _alwaysExits(Statement statement) => switch (statement) {
    ReturnStatement() || BreakStatement() || ContinueStatement() => true,
    ExpressionStatement(:final expression) => expression is ThrowExpression,
    Block(:final statements) =>
      statements.isNotEmpty && _alwaysExits(statements.last),
    _ => false,
  };
}
