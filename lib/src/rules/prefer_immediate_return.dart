import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferImmediateReturn extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_immediate_return',
    "The variable '{0}' is only used by the return on the next line.",
    correctionMessage: 'Return the expression directly.',
  );

  PreferImmediateReturn()
    : super(
        name: 'prefer_immediate_return',
        description:
            'Warns when a local variable is declared and then immediately '
            'returned without being used for anything else.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addBlock(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferImmediateReturn rule;

  _Visitor(this.rule);

  @override
  void visitBlock(Block node) {
    final statements = node.statements;
    if (statements.length < 2) return;

    final returnStatement = statements.last;
    if (returnStatement is! ReturnStatement) return;

    final returned = returnStatement.expression;
    if (returned is! SimpleIdentifier) return;

    final declarationStatement = statements[statements.length - 2];
    if (declarationStatement is! VariableDeclarationStatement) return;

    final variables = declarationStatement.variables.variables;
    if (variables.length != 1) return;

    final variable = variables.first;
    if (variable.name.lexeme != returned.name) return;

    if (variable.initializer == null) return;

    if (declarationStatement.variables.isLate) return;

    final declaredElement = variable.declaredFragment?.element;
    if (declaredElement == null) return;
    if (returned.element != declaredElement) return;

    final function = node.thisOrAncestorOfType<FunctionBody>();
    if (function == null) return;

    final counter = _ReferenceCounter(declaredElement);
    function.accept(counter);
    final isReferencedOnlyByReturn = counter.count == 1;
    if (!isReferencedOnlyByReturn) return;

    rule.reportAtNode(declarationStatement, arguments: [variable.name.lexeme]);
  }
}

class _ReferenceCounter extends RecursiveAstVisitor<void> {
  final Object declaredElement;
  int count = 0;

  _ReferenceCounter(this.declaredElement);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final isDeclaredName = node.parent is VariableDeclaration;
    if (isDeclaredName) return;
    if (node.element == declaredElement) count++;
  }
}
