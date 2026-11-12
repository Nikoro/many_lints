import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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
    if (node.metadata.any((a) => a.name.name == 'override')) return;

    _reportIfAlwaysNull(node.body, node.returnType, node.name);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _reportIfAlwaysNull(
        node.functionExpression.body,
        node.returnType,
        node.name,
      );

  void _reportIfAlwaysNull(
    FunctionBody body,
    TypeAnnotation? returnType,
    Token name,
  ) {
    final type = returnType?.type;
    if (type == null) return;

    if (type is VoidType) return;
    if (type.nullabilitySuffix != NullabilitySuffix.question) return;

    if (body.isAsynchronous || body.isGenerator) return;

    switch (body) {
      case ExpressionFunctionBody(:final expression):
        if (_isNullLiteral(expression)) rule.reportAtToken(name);
      case BlockFunctionBody(:final block):
        final finder = _ReturnFinder();
        block.accept(finder);

        if (finder.returns.isEmpty) return;

        if (finder.returns.every(_yieldsNull)) rule.reportAtToken(name);
      default:
        return;
    }
  }

  bool _yieldsNull(Expression? returned) =>
      returned == null || _isNullLiteral(returned);

  bool _isNullLiteral(Expression expression) => switch (expression) {
    NullLiteral() => true,
    ParenthesizedExpression(:final expression) => _isNullLiteral(expression),
    _ => false,
  };
}

class _ReturnFinder extends RecursiveAstVisitor<void> {
  final List<Expression?> returns = [];

  @override
  void visitReturnStatement(ReturnStatement node) =>
      returns.add(node.expression);

  // Edge case: a nested closure's returns belong to the closure, not the enclosing function
  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
