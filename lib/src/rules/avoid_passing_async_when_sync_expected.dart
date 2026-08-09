import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when an `async` closure is passed where a `void`-returning function
/// is expected.
///
/// `void Function()` accepts an `async` closure: the returned `Future` is
/// assigned to `void` and dropped. Nothing awaits it, so the caller continues
/// before the work finishes, and an error thrown inside it becomes an
/// unhandled async error instead of something the caller can catch.
///
/// This is the only shape where the mismatch compiles. For any other return
/// type — `int Function()`, `String Function()` — the analyzer already rejects
/// `Future<int>` as not assignable, so there is nothing left for a lint to
/// catch. `dynamic` and `Object` returns accept the future *as a value*, which
/// the callee can still store or await, so they are not reported either.
///
/// **Bad:**
/// ```dart
/// void schedule(void Function() task) { ... }
///
/// schedule(() async {
///   await save(); // nothing awaits this; errors surface as unhandled
/// });
/// ```
///
/// **Good:**
/// ```dart
/// void schedule(Future<void> Function() task) { ... }
/// ```
///
/// Flutter's `onPressed` and friends are `void`-returning by design and are
/// commonly given `async` bodies. Add them to `ignored_parameters` — or set
/// `ignore_widget_callbacks` — when that is the intended fire-and-forget.
class AvoidPassingAsyncWhenSyncExpected extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_passing_async_when_sync_expected',
    "An async function is passed to '{0}', which expects a synchronous one.",
    correctionMessage:
        'The returned future is discarded, so nothing awaits this work and '
        "errors become unhandled. Change the parameter to return a 'Future', "
        'or handle the errors inside the callback.',
  );

  AvoidPassingAsyncWhenSyncExpected()
    : super(
        name: 'avoid_passing_async_when_sync_expected',
        description:
            'Warns when an async function is passed where a void-returning '
            'function is expected, silently discarding the future.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFunctionExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidPassingAsyncWhenSyncExpected rule;

  _Visitor(this.rule);

  /// Common Flutter callbacks that are `void` by contract and idiomatically
  /// given `async` bodies. Reported only when the user opts in.
  static const _widgetCallbacks = {
    'onPressed',
    'onTap',
    'onLongPress',
    'onChanged',
    'onSubmitted',
    'onDoubleTap',
    'onRefresh',
    'onSaved',
    'listener',
  };

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (!node.body.isAsynchronous) return;

    // `async*` returns a Stream — a different shape, not this rule's concern.
    if (node.body.isGenerator) return;

    // Only an argument position carries a parameter type to compare against.
    // A positional argument is the expression itself; a named one is wrapped
    // in a `NamedArgument`. Both expose `correspondingParameter`.
    final Argument argument;
    switch (node.parent) {
      case ArgumentList():
        argument = node;
      case final NamedArgument named when named.argumentExpression == node:
        argument = named;
      default:
        return;
    }

    final parameter = argument.correspondingParameter;
    final parameterType = parameter?.type;
    if (parameterType is! FunctionType) return;

    // Only `void` both accepts an async closure and silently drops it.
    if (parameterType.returnType is! VoidType) return;

    final parameterName = parameter?.name ?? '';

    if (rule.config
        .stringListOption('ignored_parameters')
        .contains(parameterName)) {
      return;
    }

    // `ignore_widget_callbacks: true` silences the Flutter handlers that are
    // fire-and-forget by contract. Off by default: the future really is
    // dropped there too, and a project that wants the reminder should get it.
    final ignoreWidgetCallbacks = rule.config.boolOption(
      'ignore_widget_callbacks',
      defaultValue: false,
    );

    if (ignoreWidgetCallbacks && _widgetCallbacks.contains(parameterName)) {
      return;
    }

    rule.reportAtNode(node, arguments: [parameterName]);
  }
}
