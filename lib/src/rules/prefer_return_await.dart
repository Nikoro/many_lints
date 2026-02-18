import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a Future is returned without `await` inside a try-catch block.
///
/// Returning a Future without awaiting it in a try-catch block means any
/// exception thrown by the Future will NOT be caught by the catch clause.
/// The Future completes after the function has already returned, so the
/// catch clause never has a chance to handle the error.
///
/// **Bad:**
/// ```dart
/// Future<String> fetch() async {
///   try {
///     return asyncOperation();
///   } catch (e) {
///     return 'fallback';
///   }
/// }
/// ```
///
/// **Good:**
/// ```dart
/// Future<String> fetch() async {
///   try {
///     return await asyncOperation();
///   } catch (e) {
///     return 'fallback';
///   }
/// }
/// ```
class PreferReturnAwait extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_return_await',
    'Missing await on returned Future inside try-catch block.',
    correctionMessage: 'Add await before the returned expression.',
  );

  PreferReturnAwait()
    : super(
        name: 'prefer_return_await',
        description:
            'Warns when a Future is returned without await inside a '
            'try-catch block.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addReturnStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferReturnAwait rule;

  _Visitor(this.rule);

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression == null) return;

    // Already awaited — nothing to report.
    if (expression is AwaitExpression) return;

    // Check if the expression's static type is a Future.
    final type = expression.staticType;
    if (type == null || !_isFutureType(type)) return;

    // Check if we're inside a try body or catch clause.
    if (!_isInsideTryCatch(node)) return;

    // Check if the enclosing function is async.
    if (!_isEnclosingFunctionAsync(node)) return;

    rule.reportAtNode(expression);
  }

  /// Returns true if [type] is `Future<T>` or `FutureOr<T>`.
  static bool _isFutureType(DartType type) {
    if (type is! InterfaceType) return false;
    final name = type.element.name;
    return name == 'Future' || name == 'FutureOr';
  }

  /// Walks up the AST to check if [node] is inside a try body or catch clause
  /// (but not in a finally block). Stops at function boundaries.
  static bool _isInsideTryCatch(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      // Stop at function boundaries.
      if (current is FunctionExpression ||
          current is FunctionDeclaration ||
          current is MethodDeclaration) {
        return false;
      }

      if (current is TryStatement) {
        // We're directly inside the try statement — check if we're in the
        // try body or a catch clause (not the finally block).
        return _isInTryBodyOrCatch(node, current);
      }

      current = current.parent;
    }
    return false;
  }

  /// Returns true if [node] is contained within the try body or a catch
  /// clause of [tryStatement], not in the finally block.
  static bool _isInTryBodyOrCatch(AstNode node, TryStatement tryStatement) {
    // Check if node is inside the try body.
    if (_isDescendantOf(node, tryStatement.body)) return true;

    // Check if node is inside any catch clause.
    for (final catchClause in tryStatement.catchClauses) {
      if (_isDescendantOf(node, catchClause)) return true;
    }

    return false;
  }

  /// Returns true if [node] is a descendant of [ancestor].
  static bool _isDescendantOf(AstNode node, AstNode ancestor) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current == ancestor) return true;
      current = current.parent;
    }
    return false;
  }

  /// Walks up the AST to find the enclosing function and checks if it's async.
  static bool _isEnclosingFunctionAsync(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is FunctionExpression) {
        return current.body.isAsynchronous;
      }
      if (current is MethodDeclaration) {
        return current.body.isAsynchronous;
      }
      current = current.parent;
    }
    return false;
  }
}
