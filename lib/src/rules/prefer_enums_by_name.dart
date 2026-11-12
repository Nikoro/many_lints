import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ast_node_analysis.dart';

class PreferEnumsByName extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_enums_by_name',
    'Use .byName() instead of .firstWhere() to access enum values by name.',
    correctionMessage: 'Replace with .byName() for better readability.',
  );

  PreferEnumsByName()
    : super(
        name: 'prefer_enums_by_name',
        description:
            'Use .byName() instead of .firstWhere() to find enum values by name.',
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
  final PreferEnumsByName rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'firstWhere') return;

    if (!_isEnumValues(node.target)) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final callback = args.first;
    if (callback is! FunctionExpression) return;

    final params = callback.parameters?.parameters;
    if (params == null || params.length != 1) return;
    final paramName = params.first.name?.lexeme;
    if (paramName == null) return;

    final bodyExpr = maybeGetSingleReturnExpression(callback.body);
    if (bodyExpr == null) return;

    if (bodyExpr is! BinaryExpression) return;
    if (bodyExpr.operator.type != TokenType.EQ_EQ) return;

    if (_isParamNameAccess(bodyExpr.leftOperand, paramName) ||
        _isParamNameAccess(bodyExpr.rightOperand, paramName)) {
      rule.reportAtNode(node);
    }
  }

  static bool _isEnumValues(Expression? target) {
    if (target case PrefixedIdentifier(
      identifier: SimpleIdentifier(name: 'values'),
      prefix: SimpleIdentifier(element: final element?),
    ) when element is EnumElement) {
      return true;
    }
    if (target case PropertyAccess(
      propertyName: SimpleIdentifier(name: 'values'),
      target: Expression(staticType: final type?),
    )) {
      final typeElement = type.element;
      return typeElement is EnumElement;
    }
    return false;
  }

  static bool _isParamNameAccess(Expression expr, String paramName) {
    if (expr case PrefixedIdentifier(
      prefix: SimpleIdentifier(name: final prefix),
      identifier: SimpleIdentifier(name: 'name'),
    ) when prefix == paramName) {
      return true;
    }
    if (expr case PropertyAccess(
      target: SimpleIdentifier(name: final prefix),
      propertyName: SimpleIdentifier(name: 'name'),
    ) when prefix == paramName) {
      return true;
    }
    return false;
  }
}
