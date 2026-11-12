import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferReturningCondition extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_returning_condition',
    'This returns the condition, spelled out as two branches.',
    correctionMessage: 'Return the condition directly.',
  );

  PreferReturningCondition()
    : super(
        name: 'prefer_returning_condition',
        description:
            'Warns when an if/return pair returns true and false, where the '
            'condition can be returned directly.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addIfStatement(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferReturningCondition rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    // Edge case: a pattern case binds variables the returned expression may use.
    if (node.caseClause != null) return;

    final thenValue = _returnedBoolean(node.thenStatement);
    if (thenValue == null) return;

    final elseValue = switch (node.elseStatement) {
      final Statement statement? => _returnedBoolean(statement),
      _ => _nextStatementBoolean(node),
    };
    if (elseValue == null) return;

    // Edge case: the same literal twice belongs to function_always_returns_same_value.
    if (thenValue == elseValue) return;

    rule.reportAtNode(node);
  }

  bool? _returnedBoolean(Statement statement) {
    final returnStatement = switch (statement) {
      ReturnStatement() && final s => s,
      Block(statements: [ReturnStatement() && final s]) => s,
      _ => null,
    };

    return switch (returnStatement?.expression) {
      BooleanLiteral(:final value) => value,
      _ => null,
    };
  }

  bool? _nextStatementBoolean(IfStatement node) {
    if (node.parent case Block(:final statements)) {
      final index = statements.indexOf(node);
      if (index >= 0 && index + 1 < statements.length) {
        return _returnedBoolean(statements[index + 1]);
      }
    }
    return null;
  }
}
