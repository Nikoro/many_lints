import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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

  void _check(FunctionBody body, TypeAnnotation? returnType) {
    if (!_returnsNothing(returnType)) return;

    if (body is! BlockFunctionBody) return;
    final statements = body.block.statements;
    if (statements.isEmpty) return;

    final last = statements.last;
    if (last is! ReturnStatement) return;

    if (last.expression != null) return;

    rule.reportAtNode(last);
  }

  bool _returnsNothing(TypeAnnotation? returnType) {
    if (returnType is! NamedType) return false;

    return switch (returnType.name.lexeme) {
      'void' => true,
      'Future' => switch (returnType.typeArguments?.arguments) {
        [NamedType(name: final argument)] => argument.lexeme == 'void',
        _ => false,
      },
      _ => false,
    };
  }
}
