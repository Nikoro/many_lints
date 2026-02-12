import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/ast_node_analysis.dart';
import 'package:many_lints/src/type_checker.dart';

/// Suggests using .any() or .every() instead of .where().isEmpty/.isNotEmpty.
class PreferAnyOrEvery extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_any_or_every',
    'Use .{0}() instead of .where().{1}.',
    correctionMessage:
        'Replace with .{0}() for better readability and performance.',
  );

  PreferAnyOrEvery()
    : super(
        name: 'prefer_any_or_every',
        description:
            'Use .any() or .every() instead of .where().isEmpty/isNotEmpty.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferAnyOrEvery rule;

  _Visitor(this.rule);

  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node case PropertyAccess(
      propertyName: SimpleIdentifier(
        name: final property && ('isEmpty' || 'isNotEmpty'),
      ),
      target: MethodInvocation(
        target: Expression(staticType: final targetType?),
        methodName: SimpleIdentifier(name: 'where'),
        argumentList: ArgumentList(arguments: [_]),
      ),
    ) when _iterableChecker.isAssignableFromType(targetType)) {
      final isNotEmpty = property == 'isNotEmpty';
      rule.reportAtNode(
        node,
        arguments: [isNotEmpty ? 'any' : 'every', property],
      );
    }
  }
}

/// Builds a replacement expression for .every() with negated predicate.
String? buildEveryReplacement(String collection, Expression predicate) {
  if (predicate is! FunctionExpression) return null;

  final body = predicate.body;
  final innerExpr = maybeGetSingleReturnExpression(body);
  if (innerExpr == null) return null;

  final params = predicate.parameters!.toSource();
  final negated = negateExpression(innerExpr);
  return '$collection.every($params => $negated)';
}

/// Negates an expression, handling double negation and parenthesization.
String negateExpression(Expression expr) {
  // Double negation removal: !x -> x
  if (expr is PrefixExpression && expr.operator.type == TokenType.BANG) {
    return expr.operand.toSource();
  }
  // Simple expressions don't need parentheses
  if (expr is SimpleIdentifier ||
      expr is PrefixedIdentifier ||
      expr is MethodInvocation ||
      expr is PropertyAccess ||
      expr is IndexExpression ||
      expr is ParenthesizedExpression ||
      expr is PrefixExpression ||
      expr is BooleanLiteral) {
    return '!${expr.toSource()}';
  }
  // Binary and other complex expressions need parentheses
  return '!(${expr.toSource()})';
}
