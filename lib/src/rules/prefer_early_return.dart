import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferEarlyReturn extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_early_return',
    'This `if` wraps the rest of the function body.',
    correctionMessage:
        'Invert the condition and return early, so the body reads as the '
        'happy path.',
  );

  PreferEarlyReturn()
    : super(
        name: 'prefer_early_return',
        description:
            'Warns when a trailing `if` wraps a function body that an early '
            'return would flatten.',
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

const _defaultMinStatements = 3;

class _Visitor extends SimpleAstVisitor<void> {
  final PreferEarlyReturn rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.body);

  @override
  void visitMethodDeclaration(MethodDeclaration node) => _check(node.body);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Edge case: a declaration's own function expression is visited above too
    if (node.parent is FunctionDeclaration) return;
    _check(node.body);
  }

  void _check(FunctionBody body) {
    if (body is! BlockFunctionBody) return;

    final statements = body.block.statements;
    if (statements.length != 1) return;

    final last = statements.single;
    if (last is! IfStatement) return;

    if (last.elseStatement != null) return;

    final thenBlock = last.thenStatement;
    if (thenBlock is! Block) return;

    final wrapped = thenBlock.statements;
    final minStatements = rule.config.intOption(
      'min_statements',
      defaultValue: _defaultMinStatements,
    );
    if (wrapped.length < minStatements) return;

    // Edge case: a pattern `if` binds variables the inverted branch cannot see
    if (last.caseClause != null) return;

    // Edge case: `if (!map.containsKey(k))` would invert to a longer positive guard
    if (_isNegated(last.expression)) return;

    rule.reportAtToken(last.ifKeyword);
  }

  bool _isNegated(Expression condition) {
    final expression = condition.unParenthesized;

    return expression is PrefixExpression &&
            expression.operator.type == TokenType.BANG ||
        expression is BinaryExpression &&
            expression.operator.type == TokenType.BANG_EQ;
  }
}
