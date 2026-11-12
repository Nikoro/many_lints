import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidUnnecessaryContinue extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_continue',
    'This `continue` is the last statement in the loop body.',
    correctionMessage: 'Remove it; the loop already continues here.',
  );

  AvoidUnnecessaryContinue()
    : super(
        name: 'avoid_unnecessary_continue',
        description:
            'Warns when a `continue` ends a loop body, where control would '
            'reach the next iteration without it.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
    registry.addWhileStatement(this, visitor);
    registry.addDoStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryContinue rule;

  _Visitor(this.rule);

  @override
  void visitForStatement(ForStatement node) => _check(node.body);

  @override
  void visitWhileStatement(WhileStatement node) => _check(node.body);

  @override
  void visitDoStatement(DoStatement node) => _check(node.body);

  void _check(Statement body) {
    final last = switch (body) {
      Block(:final statements) when statements.isNotEmpty => statements.last,
      ContinueStatement() => body,
      _ => null,
    };

    if (last case ContinueStatement(label: null)) rule.reportAtNode(last);
  }
}
