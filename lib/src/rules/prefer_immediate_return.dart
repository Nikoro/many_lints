import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a local variable is declared only to be returned on the next
/// line.
///
/// `final result = compute(); return result;` introduces a name that
/// carries no information the return statement does not already give. The
/// extra line is one more thing to read and to keep in sync when the
/// expression changes.
class PreferImmediateReturn extends AnalysisRule {
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
  void registerNodeProcessors(
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
    // `var a = 1, b = 2;` cannot be collapsed into a return.
    if (variables.length != 1) return;

    final variable = variables.first;
    if (variable.name.lexeme != returned.name) return;

    // No initializer means there is nothing to return in its place.
    if (variable.initializer == null) return;

    // A `late` declaration has semantics of its own.
    if (declarationStatement.variables.isLate) return;

    // The name must resolve to this declaration, not a field or an outer
    // variable that merely shares the identifier.
    final declaredElement = variable.declaredFragment?.element;
    if (declaredElement == null) return;
    if (returned.element != declaredElement) return;

    // Any other reference in the enclosing function means the variable is
    // doing real work.
    final function = node.thisOrAncestorOfType<FunctionBody>();
    if (function == null) return;

    final counter = _ReferenceCounter(declaredElement);
    function.accept(counter);
    // One reference: the return itself.
    if (counter.count != 1) return;

    rule.reportAtNode(declarationStatement, arguments: [variable.name.lexeme]);
  }
}

/// Counts references to a specific local variable.
class _ReferenceCounter extends RecursiveAstVisitor<void> {
  final Object declaredElement;
  int count = 0;

  _ReferenceCounter(this.declaredElement);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // Skip the declaration's own name token.
    if (node.parent is VariableDeclaration) return;
    if (node.element == declaredElement) count++;
  }
}
