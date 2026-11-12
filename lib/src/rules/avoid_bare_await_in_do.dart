import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_do_notation.dart';
import '../many_lints_rule.dart';

class AvoidBareAwaitInDo extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_bare_await_in_do',
    "Avoid awaiting a raw Future inside a 'Do' block.",
    correctionMessage:
        "Wrap it in an fpdart type and extract it with '\$' so a failure "
        'short-circuits the block instead of escaping it.',
  );

  AvoidBareAwaitInDo()
    : super(
        name: 'avoid_bare_await_in_do',
        description:
            'Warns when an async Do body awaits a Future directly rather than '
            'through the block\'s extraction function, escaping its tracking.',
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
  final AvoidBareAwaitInDo rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final invocation = DoInvocation.tryRead(node);
    if (invocation == null) return;

    if (!invocation.isAsync) return;

    _BareAwaitFinder(rule, invocation).run();
  }
}

class _BareAwaitFinder extends DoBodyVisitor {
  final AvoidBareAwaitInDo rule;

  // Edge case: depth is counted, not cut off, as a closure may hold a nested Do that must be visited
  int _closureDepth = 0;

  _BareAwaitFinder(this.rule, super.invocation);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _closureDepth++;
    super.visitFunctionExpression(node);
    _closureDepth--;
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    super.visitAwaitExpression(node);

    if (_closureDepth > 0) return;
    if (invocation.isExtractorCall(node.expression)) return;

    rule.reportAtNode(node);
  }
}
