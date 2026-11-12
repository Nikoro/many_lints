import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ast_node_analysis.dart';
import '../flutter_type_checkers.dart';

class AvoidWrappingInPadding extends ManyLintsRule {
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
  final AvoidWrappingInPadding rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isExpressionExactlyType(node, paddingChecker)) return;
    _check(node.argumentList, node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final type = node.staticType;
    if (type == null || !paddingChecker.isExactlyType(type)) return;
    _check(node.argumentList, node.methodName);
  }

  void _check(ArgumentList argumentList, AstNode reportNode) {
    final childExpr = namedArgumentValue(argumentList.arguments, 'child');
    if (childExpr == null) return;

    final (childTypeName, childArgList) = _getChildInfo(childExpr);
    if (childTypeName == null || childArgList == null) return;

    final childType = childExpr.staticType;
    if (childType is! InterfaceType) return;
    if (!_hasPaddingParam(childType)) return;

    if (childArgList.arguments.whereType<NamedArgument>().any(
      (e) => e.name.lexeme == 'padding',
    )) {
      return;
    }

    rule.reportAtNode(reportNode, arguments: [childTypeName]);
  }

  static (String?, ArgumentList?) _getChildInfo(Expression expr) {
    if (expr is InstanceCreationExpression) {
      return (expr.constructorName.type.name.lexeme, expr.argumentList);
    }
    if (expr is MethodInvocation) {
      return (expr.methodName.name, expr.argumentList);
    }
    return (null, null);
  }

  static bool _hasPaddingParam(InterfaceType type) {
    for (final constructor in type.element.constructors) {
      for (final param in constructor.formalParameters) {
        if (param.isNamed && param.name == 'padding') return true;
      }
    }
    return false;
  }
}
