import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/ast_node_analysis.dart';

/// Suggests using `.byName()` instead of `.firstWhere((e) => e.name == value)`
/// on enum values.
class PreferEnumsByName extends AnalysisRule {
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
  void registerNodeProcessors(
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

    // Check that the target is .values on an enum type
    if (!_isEnumValues(node.target)) return;

    // Get the firstWhere callback argument
    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final callback = args.first;
    if (callback is! FunctionExpression) return;

    // Check that the callback has exactly one parameter
    final params = callback.parameters?.parameters;
    if (params == null || params.length != 1) return;
    final paramName = params.first.name?.lexeme;
    if (paramName == null) return;

    // Extract the body expression
    final bodyExpr = maybeGetSingleReturnExpression(callback.body);
    if (bodyExpr == null) return;

    // Check for pattern: param.name == value  or  value == param.name
    if (bodyExpr is! BinaryExpression) return;
    if (bodyExpr.operator.type != TokenType.EQ_EQ) return;

    if (_isParamNameAccess(bodyExpr.leftOperand, paramName) ||
        _isParamNameAccess(bodyExpr.rightOperand, paramName)) {
      rule.reportAtNode(node);
    }
  }

  /// Checks if [target] is `SomeEnum.values` where `SomeEnum` is an enum.
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

  /// Checks if [expr] is `paramName.name` — accessing the `.name` property
  /// on the callback parameter.
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
