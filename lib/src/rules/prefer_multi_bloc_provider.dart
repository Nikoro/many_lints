import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../bloc_type_checkers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

class PreferMultiBlocProvider extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_multi_bloc_provider',
    "Prefer '{0}' instead of multiple nested '{1}'s.",
    correctionMessage: "Wrap the nested '{1}'s in a single '{0}'.",
  );

  PreferMultiBlocProvider()
    : super(
        name: 'prefer_multi_bloc_provider',
        description:
            'Warns when nested BlocProvider, BlocListener, or '
            'RepositoryProvider can be replaced with their Multi* counterpart.',
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

typedef _ProviderType = ({
  TypeChecker checker,
  String multiName,
  String singleName,
});

const List<_ProviderType> _providerTypes = [
  (
    checker: blocProviderChecker,
    multiName: 'MultiBlocProvider',
    singleName: 'BlocProvider',
  ),
  (
    checker: blocListenerChecker,
    multiName: 'MultiBlocListener',
    singleName: 'BlocListener',
  ),
  (
    checker: repositoryProviderChecker,
    multiName: 'MultiRepositoryProvider',
    singleName: 'RepositoryProvider',
  ),
];

_ProviderType? _matchProviderType(DartType? staticType) {
  if (staticType == null) return null;
  for (final entry in _providerTypes) {
    if (entry.checker.isExactlyType(staticType)) return entry;
  }
  return null;
}

(ArgumentList, DartType?)? _getCallInfo(Expression node) {
  if (node is InstanceCreationExpression) {
    return (node.argumentList, node.staticType);
  }
  if (node is MethodInvocation) {
    return (node.argumentList, node.staticType);
  }
  return null;
}

bool _isChildOfSameProviderType(Expression node, TypeChecker checker) {
  final namedArg = node.parent;
  if (namedArg is! NamedArgument) return false;
  if (namedArg.name.lexeme != 'child') return false;

  final argList = namedArg.parent;
  if (argList is! ArgumentList) return false;

  final parentCall = argList.parent;
  if (parentCall is! Expression) return false;

  final parentType = parentCall.staticType;
  if (parentType == null) return false;

  return checker.isExactlyType(parentType);
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferMultiBlocProvider rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node, node.staticType, node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(node, node.staticType, node.methodName);
  }

  void _check(Expression node, DartType? staticType, AstNode reportNode) {
    final match = _matchProviderType(staticType);
    if (match == null) return;

    final checker = match.checker;

    final isNestedInSameProvider = _isChildOfSameProviderType(node, checker);
    if (isNestedInSameProvider) return;

    final callInfo = _getCallInfo(node);
    if (callInfo == null) return;

    final childExpr = namedArgumentValue(callInfo.$1.arguments, 'child');
    if (childExpr == null) return;

    final childType = childExpr.staticType;
    if (childType == null || !checker.isExactlyType(childType)) return;

    rule.reportAtNode(
      reportNode,
      arguments: [match.multiName, match.singleName],
    );
  }
}
