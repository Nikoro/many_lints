import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidUnremovableCallbacksInListeners extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unremovable_callbacks_in_listeners',
    "An inline closure passed to '{0}' can never be removed.",
    correctionMessage:
        'Extract the callback to a method or field and pass that, so '
        "'removeListener' can match it by identity.",
  );

  AvoidUnremovableCallbacksInListeners()
    : super(
        name: 'avoid_unremovable_callbacks_in_listeners',
        description:
            'Warns when a closure literal is passed to addListener, making '
            'the listener impossible to remove.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnremovableCallbacksInListeners rule;

  _Visitor(this.rule);

  static const _addMethods = {'addListener', 'addStatusListener'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methods = {
      ..._addMethods,
      ...rule.config.stringListOption('additional_methods'),
    };

    if (!methods.contains(node.methodName.name)) return;

    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return;

    final argument = arguments.first;
    if (argument is! FunctionExpression) return;

    rule.reportAtNode(argument, arguments: [node.methodName.name]);
  }
}
