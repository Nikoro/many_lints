import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_do_notation.dart';
import '../many_lints_rule.dart';

class AvoidDollarOutsideDoFrame extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_dollar_outside_do_frame',
    "Avoid calling a 'Do' block's extraction function inside a nested "
        'callback.',
    correctionMessage:
        'Extract the value in the block itself, then use it in the callback.',
  );

  AvoidDollarOutsideDoFrame()
    : super(
        name: 'avoid_dollar_outside_do_frame',
        description:
            "Warns when a Do block's extraction function is called from a "
            'nested callback, where its short-circuit unwinds through code '
            'that cannot handle it.',
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
  final AvoidDollarOutsideDoFrame rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final invocation = DoInvocation.tryRead(node);
    if (invocation == null) return;
    if (invocation.extractorName == null) return;

    invocation.body.accept(_NestedDollarFinder(rule, invocation));
  }
}

class _NestedDollarFinder extends DoBodyVisitor {
  final AvoidDollarOutsideDoFrame rule;

  int _closureDepth = 0;

  _NestedDollarFinder(this.rule, super.invocation);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _closureDepth++;
    super.visitFunctionExpression(node);
    _closureDepth--;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_reportIfNested(node)) return;
    super.visitMethodInvocation(node);
  }

  // Edge case: calling the block's $ parameter parses as a function expression invocation
  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (_reportIfNested(node)) return;
    super.visitFunctionExpressionInvocation(node);
  }

  // Edge case: a $ inside the arguments of a reported $ is the same mistake, so it is not visited
  bool _reportIfNested(Expression node) {
    if (_closureDepth == 0) return false;
    if (!invocation.isExtractorCall(node)) return false;

    rule.reportAtNode(node);
    return true;
  }
}
