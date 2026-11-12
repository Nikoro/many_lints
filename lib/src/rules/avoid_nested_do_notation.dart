import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_do_notation.dart';
import '../many_lints_rule.dart';

class AvoidNestedDoNotation extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_nested_do_notation',
    "Avoid nesting one 'Do' block inside another.",
    correctionMessage:
        "Extract the inner block's steps in the outer block instead, so a "
        'failure short-circuits the whole pipeline.',
  );

  AvoidNestedDoNotation()
    : super(
        name: 'avoid_nested_do_notation',
        description:
            'Warns when an fpdart Do block is nested inside another, where the '
            'inner block short-circuits on its own instead of failing the '
            'outer pipeline.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidNestedDoNotation rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (DoInvocation.tryRead(node) == null) return;
    if (!_hasEnclosingDoBlock(node)) return;

    rule.reportAtNode(node.constructorName);
  }

  bool _hasEnclosingDoBlock(AstNode node) {
    for (
      AstNode? parent = node.parent;
      parent != null;
      parent = parent.parent
    ) {
      if (parent is InstanceCreationExpression &&
          DoInvocation.tryRead(parent) != null) {
        return true;
      }
    }
    return false;
  }
}
