import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../many_lints_rule.dart';
import '../constant_expression.dart';

class AvoidAccessingCollectionsByConstantIndex extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_accessing_collections_by_constant_index',
    'Avoid accessing a collection by a constant index inside a loop.',
    correctionMessage:
        'Move the access outside the loop or use a loop-dependent index.',
  );

  AvoidAccessingCollectionsByConstantIndex()
    : super(
        name: 'avoid_accessing_collections_by_constant_index',
        description:
            'Warns when a collection is accessed by a constant index '
            'inside a loop body.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addIndexExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidAccessingCollectionsByConstantIndex rule;

  _Visitor(this.rule);

  @override
  void visitIndexExpression(IndexExpression node) {
    if (!_isInsideLoopBody(node)) return;
    if (!_isConstantIndex(node.index)) return;

    rule.reportAtNode(node);
  }

  static bool _isInsideLoopBody(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ForStatement ||
          current is WhileStatement ||
          current is DoStatement) {
        return true;
      }
      // Edge case: a loop in an outer function says nothing about an index inside a nested closure
      if (current is FunctionExpression ||
          current is FunctionDeclaration ||
          current is MethodDeclaration) {
        return false;
      }
      current = current.parent;
    }
    return false;
  }

  static bool _isConstantIndex(Expression expression) {
    if (expression is IntegerLiteral) return true;

    if (expression is SimpleIdentifier) {
      return isConstantIdentifier(expression);
    }

    if (expression is PrefixedIdentifier) {
      return isConstantIdentifier(expression.identifier);
    }

    if (expression is PropertyAccess) {
      return isConstantIdentifier(expression.propertyName);
    }

    return false;
  }
}
