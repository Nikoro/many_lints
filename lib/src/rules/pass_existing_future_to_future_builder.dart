import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../async_builder_utils.dart';
import '../type_checker.dart';

/// Warns when a `FutureBuilder` receives a newly created `Future`.
///
/// `build()` may run many times per second. Creating the future inline means
/// a fresh one is built on every rebuild, so the `FutureBuilder` restarts
/// from `ConnectionState.waiting` and the underlying work — often a network
/// request — is repeated.
class PassExistingFutureToFutureBuilder extends ManyLintsRule {
  static const LintCode code = LintCode(
    'pass_existing_future_to_future_builder',
    'This creates a new Future on every rebuild.',
    correctionMessage:
        'Store the Future in a field (initialized in initState) or a '
        'provider, and pass that existing instance instead.',
  );

  PassExistingFutureToFutureBuilder()
    : super(
        name: 'pass_existing_future_to_future_builder',
        description:
            'Warns when a FutureBuilder is given a Future created inline, '
            'which restarts the future on every rebuild.',
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
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PassExistingFutureToFutureBuilder rule;

  _Visitor(this.rule);

  static const _futureBuilderChecker = TypeChecker.fromName(
    'FutureBuilder',
    packageName: 'flutter',
  );

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node, node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // A constructor call without type arguments parses as a MethodInvocation.
    _check(node, node.argumentList);
  }

  void _check(Expression node, ArgumentList argumentList) {
    final type = node.staticType;
    if (type == null || !_futureBuilderChecker.isAssignableFromType(type)) {
      return;
    }

    final future = namedArgument(argumentList.arguments, 'future');
    if (future == null) return;

    if (createsNewAsyncSource(future, _futureChecker)) {
      rule.reportAtNode(future);
    }
  }
}
