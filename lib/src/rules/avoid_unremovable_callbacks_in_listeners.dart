import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when an inline closure is passed to `addListener`.
///
/// `removeListener` matches by identity, and a closure literal creates a new
/// object every time it is evaluated. A listener added as a closure can
/// therefore never be removed: the object passed to `removeListener` is a
/// different one, so the call silently does nothing.
///
/// The listener then outlives the widget, holding its `State` — and everything
/// the closure captured — alive for as long as the notifier exists. It also
/// keeps firing, so a `setState` inside it runs against a disposed element.
///
/// **Bad:**
/// ```dart
/// controller.addListener(() => setState(() {})); // can never be removed
/// ```
///
/// **Good:**
/// ```dart
/// void _onChange() => setState(() {});
///
/// controller.addListener(_onChange);
/// controller.removeListener(_onChange); // same object, actually removes
/// ```
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

  /// Registration methods whose counterpart removes by identity.
  static const _addMethods = {'addListener', 'addStatusListener'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methods = {
      ..._addMethods,
      ...rule.config.stringListOption('additional_methods'),
    };

    if (!methods.contains(node.methodName.name)) return;

    // A registration with no removable counterpart is out of scope; this rule
    // is about the add/remove pair specifically.
    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return;

    final argument = arguments.first;
    if (argument is! FunctionExpression) return;

    rule.reportAtNode(argument, arguments: [node.methodName.name]);
  }
}
