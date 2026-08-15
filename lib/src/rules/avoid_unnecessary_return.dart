import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a bare `return;` is the last statement of a function that
/// returns nothing.
///
/// Control leaves the function there anyway, so the statement adds a line
/// without changing behaviour. Like a trailing `continue`, it usually survives
/// a change that moved or deleted the statements it once guarded, and it reads
/// as though something below is being skipped.
///
/// Only a `return` with no value is reported, and only in a function whose
/// return type is `void` or `Future<void>`. An early `return;` that genuinely
/// skips later statements is doing real work and is left alone.
class AvoidUnnecessaryReturn extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_return',
    'This `return` is the last statement of a function returning nothing.',
    correctionMessage: 'Remove it; control already leaves the function here.',
  );

  AvoidUnnecessaryReturn()
    : super(
        name: 'avoid_unnecessary_return',
        description:
            'Warns when a bare `return;` ends a void function, where control '
            'would leave it without the statement.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryReturn rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.body, node.returnType);

  @override
  void visitMethodDeclaration(MethodDeclaration node) =>
      _check(node.body, node.returnType);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // A declaration is handled above, where the return type is visible; a bare
    // closure would need inference, which this rule does not attempt.
    if (node.parent is FunctionDeclaration) return;
  }

  void _check(FunctionBody body, TypeAnnotation? returnType) {
    if (!_returnsNothing(returnType)) return;

    if (body is! BlockFunctionBody) return;
    final statements = body.block.statements;
    if (statements.isEmpty) return;

    final last = statements.last;
    if (last is! ReturnStatement) return;

    // `return value;` in a void function is a different mistake, and one the
    // analyzer already reports.
    if (last.expression != null) return;

    rule.reportAtNode(last);
  }

  /// Whether the annotation names a type that carries no value.
  ///
  /// An omitted return type is not treated as `void`: it means `dynamic`, and
  /// a `return;` there may be deliberate.
  bool _returnsNothing(TypeAnnotation? returnType) {
    if (returnType is! NamedType) return false;

    return switch (returnType.name.lexeme) {
      'void' => true,
      // `Future<void>` in an async function ends the same way.
      'Future' => switch (returnType.typeArguments?.arguments) {
        [NamedType(name: final argument)] => argument.lexeme == 'void',
        _ => false,
      },
      _ => false,
    };
  }
}
