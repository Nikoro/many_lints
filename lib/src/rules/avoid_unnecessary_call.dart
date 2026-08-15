import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a function is invoked through an explicit `.call()`.
///
/// `callback.call()` and `callback()` do the same thing, and the shorter one
/// is how a function is invoked everywhere else in the language. Spelling out
/// `.call` makes a plain invocation look like a method on an object, so a
/// reader stops to check whether the receiver is a callable class.
///
/// The one place `.call` is required is a null-aware invocation
/// (`callback?.call()`), which has no shorthand, so that is left alone.
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

    // `callback?.call()` has no shorthand — `callback?()` does not parse.
    if (node.isNullAware) return;

    // Only a function has an implicit `call`; a class defining `call` as a
    // real method is invoking that method, and `.call` is part of its name.
    if (target.staticType is! FunctionType) return;

    rule.reportAtNode(node.methodName);
  }
}
