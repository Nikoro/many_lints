import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/type_checker.dart';

/// Warns when nested `BlocProvider`, `BlocListener`, or `RepositoryProvider`
/// widgets can be consolidated using `MultiBlocProvider`,
/// `MultiBlocListener`, or `MultiRepositoryProvider`.
class PreferMultiBlocProvider extends AnalysisRule {
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
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

/// Maps each single-provider type checker to (multiName, singleName).
const _providerTypes = [
  (
    TypeChecker.fromName('BlocProvider', packageName: 'flutter_bloc'),
    'MultiBlocProvider',
    'BlocProvider',
  ),
  (
    TypeChecker.fromName('BlocListener', packageName: 'flutter_bloc'),
    'MultiBlocListener',
    'BlocListener',
  ),
  (
    TypeChecker.fromName('RepositoryProvider', packageName: 'flutter_bloc'),
    'MultiRepositoryProvider',
    'RepositoryProvider',
  ),
];

/// Finds which provider type matches [staticType], or returns `null`.
(TypeChecker, String, String)? _matchProviderType(DartType? staticType) {
  if (staticType == null) return null;
  for (final entry in _providerTypes) {
    if (entry.$1.isExactlyType(staticType)) return entry;
  }
  return null;
}

/// Extracts the `child:` named argument expression from an argument list.
Expression? _findChildExpression(ArgumentList argumentList) {
  for (final arg in argumentList.arguments) {
    if (arg is NamedExpression && arg.name.label.name == 'child') {
      return arg.expression;
    }
  }
  return null;
}

/// Returns the [ArgumentList] and static type of a provider-like expression.
(ArgumentList, DartType?)? _getCallInfo(Expression node) {
  if (node is InstanceCreationExpression) {
    return (node.argumentList, node.staticType);
  }
  if (node is MethodInvocation) {
    return (node.argumentList, node.staticType);
  }
  return null;
}

/// Returns `true` if [node] is the `child:` of a parent call that matches
/// the same provider type.
bool _isChildOfSameProviderType(Expression node, TypeChecker checker) {
  final namedExpr = node.parent;
  if (namedExpr is! NamedExpression) return false;
  if (namedExpr.name.label.name != 'child') return false;

  final argList = namedExpr.parent;
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

    final checker = match.$1;

    // Only report on the outermost nested provider
    if (_isChildOfSameProviderType(node, checker)) return;

    // Check if the `child:` is also the same provider type
    final callInfo = _getCallInfo(node);
    if (callInfo == null) return;

    final childExpr = _findChildExpression(callInfo.$1);
    if (childExpr == null) return;

    final childType = childExpr.staticType;
    if (childType == null || !checker.isExactlyType(childType)) return;

    rule.reportAtNode(reportNode, arguments: [match.$2, match.$3]);
  }
}
