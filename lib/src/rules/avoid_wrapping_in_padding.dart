import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/ast_node_analysis.dart';
import 'package:many_lints/src/type_checker.dart';

/// Warns when a widget that supports a `padding` parameter is wrapped in a
/// `Padding` widget. The padding should be passed directly to the child widget
/// instead.
class AvoidWrappingInPadding extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_wrapping_in_padding',
    "Avoid wrapping a '{0}' in a 'Padding' widget.",
    correctionMessage:
        "Try using the 'padding' argument of the '{0}' widget directly.",
  );

  AvoidWrappingInPadding()
    : super(
        name: 'avoid_wrapping_in_padding',
        description:
            'Avoid wrapping widgets that support padding in a Padding widget.',
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

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidWrappingInPadding rule;

  _Visitor(this.rule);

  static const _paddingChecker = TypeChecker.fromName(
    'Padding',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isExpressionExactlyType(node, _paddingChecker)) return;
    _check(node.argumentList, node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final type = node.staticType;
    if (type == null || !_paddingChecker.isExactlyType(type)) return;
    _check(node.argumentList, node.methodName);
  }

  void _check(ArgumentList argumentList, AstNode reportNode) {
    // Find the child argument
    final childArg = argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((e) => e.name.label.name == 'child');
    if (childArg == null) return;

    final childExpr = childArg.expression;

    // Get the child widget's type name and argument list
    final (childTypeName, childArgList) = _getChildInfo(childExpr);
    if (childTypeName == null || childArgList == null) return;

    // Check if the child widget's type has a 'padding' named parameter
    final childType = childExpr.staticType;
    if (childType is! InterfaceType) return;
    if (!_hasPaddingParam(childType)) return;

    // Check the child doesn't already have a padding argument set
    if (childArgList.arguments.whereType<NamedExpression>().any(
      (e) => e.name.label.name == 'padding',
    )) {
      return;
    }

    rule.reportAtNode(reportNode, arguments: [childTypeName]);
  }

  /// Returns the type name and argument list of the child expression.
  static (String?, ArgumentList?) _getChildInfo(Expression expr) {
    if (expr is InstanceCreationExpression) {
      return (expr.constructorName.type.name.lexeme, expr.argumentList);
    }
    if (expr is MethodInvocation) {
      return (expr.methodName.name, expr.argumentList);
    }
    return (null, null);
  }

  /// Checks whether any constructor on the type has a `padding` named param.
  static bool _hasPaddingParam(InterfaceType type) {
    for (final constructor in type.element.constructors) {
      for (final param in constructor.formalParameters) {
        if (param.isNamed && param.name == 'padding') return true;
      }
    }
    return false;
  }
}
