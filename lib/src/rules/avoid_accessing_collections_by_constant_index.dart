import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:many_lints/src/constant_expression.dart';

/// Warns when a collection is accessed by a constant index inside a loop body.
///
/// Accessing a collection with a constant index (e.g. `list[0]`) inside a loop
/// is suspicious — the index never changes, so the access likely belongs
/// outside the loop or the index should depend on the loop variable.
class AvoidAccessingCollectionsByConstantIndex extends AnalysisRule {
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
  void registerNodeProcessors(
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

  /// Returns `true` if [node] is inside the body of a loop statement.
  static bool _isInsideLoopBody(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ForStatement ||
          current is WhileStatement ||
          current is DoStatement) {
        return true;
      }
      // Stop at function boundaries — a loop in an outer function
      // doesn't make a nested closure's index access suspicious.
      if (current is FunctionExpression ||
          current is FunctionDeclaration ||
          current is MethodDeclaration) {
        return false;
      }
      current = current.parent;
    }
    return false;
  }

  /// Returns `true` if [expression] is a compile-time constant index.
  static bool _isConstantIndex(Expression expression) {
    // Integer literal: list[0]
    if (expression is IntegerLiteral) return true;

    // Simple identifier: list[constIndex]
    if (expression is SimpleIdentifier) {
      return isConstantIdentifier(expression);
    }

    // Prefixed identifier: SomeClass.constField
    if (expression is PrefixedIdentifier) {
      return isConstantIdentifier(expression.identifier);
    }

    // Property access: SomeClass.constField (alternative representation)
    if (expression is PropertyAccess) {
      return isConstantIdentifier(expression.propertyName);
    }

    return false;
  }
}
