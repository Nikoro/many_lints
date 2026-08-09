import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a function with a nullable return type returns `null` on every
/// path.
///
/// Such a function has no reachable non-null result, so every caller is forced
/// to null-check a value that can never be anything else. It is usually an
/// unfinished implementation or a leftover from a refactor that removed the
/// real return.
///
/// **Bad:**
/// ```dart
/// String? lookup(String key) {
///   if (key.isEmpty) return null;
///   return null; // nothing can ever come back
/// }
/// ```
class FunctionAlwaysReturnsNull extends ManyLintsRule {
  static const LintCode code = LintCode(
    'function_always_returns_null',
    'This function returns null on every path.',
    correctionMessage:
        "Return a real value, or change the return type to 'void' if the "
        'function is meant to produce nothing.',
  );

  FunctionAlwaysReturnsNull()
    : super(
        name: 'function_always_returns_null',
        description:
            'Warns when a function with a nullable return type returns null '
            'on every path.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final FunctionAlwaysReturnsNull rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // An override must keep its inherited signature, so the author may have no
    // freedom to change it.
    if (node.metadata.any((a) => a.name.name == 'override')) return;

    _check(node.body, node.returnType, node.name);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.body, node.returnType, node.name);

  void _check(FunctionBody body, TypeAnnotation? returnType, Token name) {
    // A missing annotation means the type is inferred as `Null`, which the
    // analyzer surfaces on its own terms; requiring one keeps this rule to
    // code the author explicitly typed.
    final type = returnType?.type;
    if (type == null) return;

    // Only nullable, non-void returns are candidates. `void` and `Future<void>`
    // already say "no value", and a non-nullable return that yields null is a
    // compile error the analyzer handles.
    if (type is VoidType) return;
    if (type.nullabilitySuffix != NullabilitySuffix.question) return;

    // A `Future<T?>`/`Iterable<T?>` body returns the wrapper, not the value,
    // so the "always null" reading does not apply to async or generator
    // bodies.
    if (body.isAsynchronous || body.isGenerator) return;

    switch (body) {
      case ExpressionFunctionBody(:final expression):
        if (_isNullLiteral(expression)) rule.reportAtToken(name);
      case BlockFunctionBody(:final block):
        final finder = _ReturnFinder();
        block.accept(finder);

        // No return at all means the function falls off the end, which the
        // analyzer already reports as a missing return.
        if (finder.returns.isEmpty) return;

        // A bare `return;` in a nullable-returning function is legal and
        // yields null, so it counts as a null return here.
        if (finder.returns.every(
          (expression) => expression == null || _isNullLiteral(expression),
        )) {
          rule.reportAtToken(name);
        }
      default:
        return;
    }
  }

  bool _isNullLiteral(Expression expression) => switch (expression) {
    NullLiteral() => true,
    ParenthesizedExpression(:final expression) => _isNullLiteral(expression),
    _ => false,
  };
}

/// Collects the expressions of every `return` in a body, stopping at nested
/// functions so a closure's returns are not attributed to the outer function.
class _ReturnFinder extends RecursiveAstVisitor<void> {
  final List<Expression?> returns = [];

  @override
  void visitReturnStatement(ReturnStatement node) =>
      returns.add(node.expression);

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
