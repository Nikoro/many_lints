import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when an outer BuildContext is used inside a nested builder callback
/// that has its own BuildContext parameter available.
class UseClosestBuildContext extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_closest_build_context',
    'Use the closest available BuildContext instead of the outer one.',
    correctionMessage:
        "Rename the inner callback's context parameter and use it instead.",
  );

  UseClosestBuildContext()
    : super(
        name: 'use_closest_build_context',
        description:
            'Warns when an outer BuildContext is used inside a nested '
            'builder callback that provides its own BuildContext.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final UseClosestBuildContext rule;

  _Visitor(this.rule);

  static const _buildContextChecker = TypeChecker.fromName(
    'BuildContext',
    packageName: 'flutter',
  );

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final parameters = node.parameters?.parameters;
    if (parameters == null) return;

    // Find the BuildContext parameter in this method
    final contextParam = _findBuildContextParam(parameters);
    if (contextParam == null) return;

    final contextName = contextParam.name?.lexeme;
    if (contextName == null) return;

    final body = node.body;

    // Search the body for nested closures that shadow BuildContext
    final finder = _NestedContextFinder(rule, contextName);
    body.visitChildren(finder);
  }

  FormalParameter? _findBuildContextParam(List<FormalParameter> parameters) {
    for (final param in parameters) {
      if (_isBuildContextType(param)) return param;
    }
    return null;
  }

  static bool _isBuildContextType(FormalParameter param) {
    // First try the explicit type annotation
    DartType? type;
    if (param is SimpleFormalParameter) {
      type = param.type?.type;
    } else if (param is DefaultFormalParameter) {
      final innerParam = param.parameter;
      if (innerParam is SimpleFormalParameter) {
        type = innerParam.type?.type;
      }
    }
    if (type != null) return _buildContextChecker.isExactlyType(type);

    // Fall back to the resolved element type (for untyped params like `_`)
    final element = param.declaredFragment?.element;
    if (element != null) {
      return _buildContextChecker.isExactlyType(element.type);
    }
    return false;
  }
}

/// Recursively searches for nested function expressions that have their own
/// BuildContext parameter but where the outer context name is referenced.
class _NestedContextFinder extends RecursiveAstVisitor<void> {
  final UseClosestBuildContext rule;
  final String outerContextName;

  _NestedContextFinder(this.rule, this.outerContextName);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _checkClosureForOuterContextUsage(node);
    // Continue searching nested closures within this closure
    super.visitFunctionExpression(node);
  }

  void _checkClosureForOuterContextUsage(FunctionExpression node) {
    final parameters = node.parameters?.parameters;
    if (parameters == null) return;

    // Check if this closure has a BuildContext parameter
    final innerContextParam = _findBuildContextParam(parameters);
    if (innerContextParam == null) return;

    final innerContextName = innerContextParam.name?.lexeme;
    // If the inner param has the same name as the outer one, the outer is
    // shadowed and can't be referenced — no issue.
    if (innerContextName == outerContextName) return;

    // Search the closure body for references to the outer context name
    final body = node.body;
    final usageFinder = _OuterContextUsageFinder(rule, outerContextName);
    body.visitChildren(usageFinder);
  }

  FormalParameter? _findBuildContextParam(List<FormalParameter> parameters) {
    for (final param in parameters) {
      if (_Visitor._isBuildContextType(param)) return param;
    }
    return null;
  }
}

/// Finds references to the outer context variable inside a nested closure body.
class _OuterContextUsageFinder extends RecursiveAstVisitor<void> {
  final UseClosestBuildContext rule;
  final String outerContextName;

  _OuterContextUsageFinder(this.rule, this.outerContextName);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == outerContextName) {
      // Exclude when part of a PrefixedIdentifier or PropertyAccess
      // (already handled by those visitors)
      final parent = node.parent;
      if (parent is PrefixedIdentifier && parent.prefix == node) {
        // This is the prefix — still a usage of the outer context
        rule.reportAtNode(node);
      } else if (parent is PropertyAccess && parent.target == node) {
        rule.reportAtNode(node);
      } else if (parent is! PrefixedIdentifier && parent is! PropertyAccess) {
        rule.reportAtNode(node);
      }
    }
    super.visitSimpleIdentifier(node);
  }

  // Stop at further nested closures that have their own BuildContext param,
  // to avoid false positives from deeper nesting levels
  @override
  void visitFunctionExpression(FunctionExpression node) {
    final parameters = node.parameters?.parameters;
    if (parameters != null) {
      for (final param in parameters) {
        if (_Visitor._isBuildContextType(param)) {
          // This nested closure has its own BuildContext — don't search inside
          return;
        }
      }
    }
    super.visitFunctionExpression(node);
  }
}
