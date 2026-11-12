import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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

    if (node.body.isGenerator) return;

    final argument = _asArgument(node);
    if (argument == null) return;

    final parameter = argument.correspondingParameter;
    final parameterType = parameter?.type;
    if (parameterType is! FunctionType) return;

    if (parameterType.returnType is! VoidType) return;

    final parameterName = parameter?.name ?? '';

    if (rule.config
        .stringListOption('ignored_parameters')
        .contains(parameterName)) {
      return;
    }

    final ignoreWidgetCallbacks = rule.config.boolOption(
      'ignore_widget_callbacks',
      defaultValue: true,
    );

    if (ignoreWidgetCallbacks && _widgetCallbacks.contains(parameterName)) {
      return;
    }

    rule.reportAtNode(node, arguments: [parameterName]);
  }

  Argument? _asArgument(FunctionExpression node) => switch (node.parent) {
    ArgumentList() => node,
    final NamedArgument named when named.argumentExpression == node => named,
    _ => null,
  };
}
