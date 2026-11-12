import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class UseExistingVariable extends ManyLintsRule {
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
  void registerManyLintsProcessors(
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
    final variables = <_VariableInfo>[];

    for (final statement in node.statements) {
      if (variables.isNotEmpty) {
        final finder = _DuplicateExpressionFinder(variables);
        statement.accept(finder);
        for (final match in finder.matches) {
          rule.reportAtNode(match.node, arguments: [match.variableName]);
        }
      }

      if (statement is VariableDeclarationStatement) {
        final isFinalOrConst =
            statement.variables.isFinal || statement.variables.isConst;
        if (!isFinalOrConst) continue;

        for (final variable in statement.variables.variables) {
          final initializer = variable.initializer;
          if (initializer == null) continue;

          final source = initializer.toSource();
          if (_isTrivialExpression(initializer)) continue;
          if (_producesFreshValueEachTime(initializer)) continue;

          variables.add((
            name: variable.name.lexeme,
            initializerSource: source,
          ));
        }
      }
    }
  }

  static bool _producesFreshValueEachTime(Expression expression) {
    return switch (expression) {
      InstanceCreationExpression() => true,
      AwaitExpression() => true,
      CascadeExpression() => true,
      ParenthesizedExpression(:final expression) => _producesFreshValueEachTime(
        expression,
      ),
      _ => false,
    };
  }

  static bool _isTrivialExpression(Expression expression) {
    if (expression is SimpleIdentifier) return true;
    if (expression is IntegerLiteral ||
        expression is DoubleLiteral ||
        expression is BooleanLiteral ||
        expression is StringLiteral ||
        expression is NullLiteral) {
      return true;
    }
    if (expression is ParenthesizedExpression) {
      return _isTrivialExpression(expression.expression);
    }
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
  void visitSimpleIdentifier(SimpleIdentifier node) {}

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

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  bool _checkExpression(Expression expression) {
    if (_Visitor._isTrivialExpression(expression)) return false;
    final source = expression.toSource();
    for (final variable in variables) {
      if (source == variable.initializerSource) {
        matches.add((node: expression, variableName: variable.name));
        return true;
      }
    }
    return false;
  }
}
