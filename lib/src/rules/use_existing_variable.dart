import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when an expression duplicates the initializer of an existing variable
/// in the same scope. Suggests reusing the variable instead of repeating the
/// expression.
class UseExistingVariable extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_existing_variable',
    "The expression duplicates the initializer of '{0}'.",
    correctionMessage: "Use '{0}' instead of repeating the expression.",
  );

  UseExistingVariable()
    : super(
        name: 'use_existing_variable',
        description:
            'Warns when an expression duplicates the initializer of an '
            'existing variable in the same scope.',
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
  final UseExistingVariable rule;

  _Visitor(this.rule);

  @override
  void visitBlock(Block node) {
    // Collect final/const variable declarations with their initializer source
    // Then scan for duplicate expressions appearing after each declaration
    final variables = <_VariableInfo>[];

    for (final statement in node.statements) {
      // First, check if any existing variable initializers are duplicated
      // in this statement
      if (variables.isNotEmpty) {
        final finder = _DuplicateExpressionFinder(variables);
        statement.accept(finder);
        for (final match in finder.matches) {
          rule.reportAtNode(match.node, arguments: [match.variableName]);
        }
      }

      // Then, collect new variable declarations from this statement
      if (statement is VariableDeclarationStatement) {
        final isFinalOrConst =
            statement.variables.isFinal || statement.variables.isConst;
        if (!isFinalOrConst) continue;

        for (final variable in statement.variables.variables) {
          final initializer = variable.initializer;
          if (initializer == null) continue;

          final source = initializer.toSource();
          // Skip trivial expressions (single identifiers, literals)
          if (_isTrivialExpression(initializer)) continue;

          variables.add((
            name: variable.name.lexeme,
            initializerSource: source,
          ));
        }
      }
    }
  }

  /// Returns true for expressions that are too simple to warrant a lint.
  static bool _isTrivialExpression(Expression expression) {
    // Single identifiers (variable references)
    if (expression is SimpleIdentifier) return true;
    // Literals
    if (expression is IntegerLiteral ||
        expression is DoubleLiteral ||
        expression is BooleanLiteral ||
        expression is StringLiteral ||
        expression is NullLiteral) {
      return true;
    }
    // Parenthesized trivial expressions
    if (expression is ParenthesizedExpression) {
      return _isTrivialExpression(expression.expression);
    }
    // Prefix expression on a literal (e.g., -1)
    if (expression is PrefixExpression) {
      return _isTrivialExpression(expression.operand);
    }
    return false;
  }
}

typedef _VariableInfo = ({String name, String initializerSource});

typedef _DuplicateMatch = ({AstNode node, String variableName});

class _DuplicateExpressionFinder extends RecursiveAstVisitor<void> {
  final List<_VariableInfo> variables;
  final List<_DuplicateMatch> matches = [];

  _DuplicateExpressionFinder(this.variables);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // Skip simple identifiers — they're trivial
    // (also avoids matching sub-expressions of larger matches)
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_checkExpression(node)) return;
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_checkExpression(node)) return;
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_checkExpression(node)) return;
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_checkExpression(node)) return;
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (_checkExpression(node)) return;
    super.visitIndexExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (_checkExpression(node)) return;
    super.visitBinaryExpression(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    if (_checkExpression(node)) return;
    super.visitConditionalExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (_checkExpression(node)) return;
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    if (_checkExpression(node)) return;
    super.visitCascadeExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (_checkExpression(node)) return;
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (_checkExpression(node)) return;
    super.visitPrefixExpression(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    if (_checkExpression(node)) return;
    super.visitAsExpression(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    if (_checkExpression(node)) return;
    super.visitIsExpression(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (_checkExpression(node)) return;
    super.visitListLiteral(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (_checkExpression(node)) return;
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (_checkExpression(node)) return;
    super.visitAwaitExpression(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    if (_checkExpression(node)) return;
    super.visitParenthesizedExpression(node);
  }

  // Stop at nested function boundaries — different execution context
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  /// Checks if [expression] matches any known variable initializer.
  /// Returns true if a match is found (to stop recursion into children).
  bool _checkExpression(Expression expression) {
    if (_Visitor._isTrivialExpression(expression)) return false;
    final source = expression.toSource();
    for (final variable in variables) {
      if (source == variable.initializerSource) {
        matches.add((node: expression, variableName: variable.name));
        return true; // Don't recurse — we matched the whole expression
      }
    }
    return false;
  }
}
