import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidUnnecessaryCall extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_call',
    "Invoke the function directly instead of through '.call()'.",
    correctionMessage: "Remove '.call'.",
  );

  AvoidUnnecessaryCall()
    : super(
        name: 'avoid_unnecessary_call',
        description:
            'Warns when a function is invoked through an explicit .call(), '
            'where a direct invocation says the same thing.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryCall rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'call') return;

    final target = node.target;
    if (target == null) return;

    // Edge case: `callback?()` does not parse, so the null-aware form needs `.call`
    if (node.isNullAware) return;

    if (target.staticType is! FunctionType) return;

    rule.reportAtNode(node.methodName);
  }
}
