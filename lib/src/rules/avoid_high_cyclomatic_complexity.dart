import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidHighCyclomaticComplexity extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_high_cyclomatic_complexity',
    'This function has a cyclomatic complexity of {0}, over the limit '
        'of {1}.',
    correctionMessage:
        'Extract a decision into its own function, or raise max_complexity.',
  );

  AvoidHighCyclomaticComplexity()
    : super(
        name: 'avoid_high_cyclomatic_complexity',
        description:
            'Warns when a function has more independent paths than the '
            'configured budget.',
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
    registry.addConstructorDeclaration(this, visitor);
  }
}

const _defaultMaxComplexity = 10;

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidHighCyclomaticComplexity rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.body, node.name);

  @override
  void visitMethodDeclaration(MethodDeclaration node) =>
      _check(node.body, node.name);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) =>
      _check(node.body, node.name, fallback: node);

  void _check(FunctionBody body, Token? name, {AstNode? fallback}) {
    if (body is EmptyFunctionBody) return;

    // Edge case: == and copyWith grow with the field count, not with decisions, and cannot be split
    if (_isFieldCountShaped(name)) return;

    final maxComplexity = rule.config.intOption(
      'max_complexity',
      defaultValue: _defaultMaxComplexity,
    );
    final countExhaustiveSwitches = rule.config.boolOption(
      'count_exhaustive_switches',
      defaultValue: false,
    );

    final counter = _ComplexityCounter(
      countExhaustiveSwitches: countExhaustiveSwitches,
    );
    body.accept(counter);

    final complexity = counter.decisions + 1;
    if (complexity <= maxComplexity) return;

    final arguments = ['$complexity', '$maxComplexity'];
    if (name != null) {
      rule.reportAtToken(name, arguments: arguments);
    } else if (fallback != null) {
      rule.reportAtNode(fallback, arguments: arguments);
    }
  }

  bool _isFieldCountShaped(Token? name) => switch (name?.lexeme) {
    '==' || 'copyWith' => true,
    _ => false,
  };
}

class _ComplexityCounter extends RecursiveAstVisitor<void> {
  _ComplexityCounter({required this.countExhaustiveSwitches});

  final bool countExhaustiveSwitches;

  int decisions = 0;

  // Edge case: a callback carries its own complexity, measured where it is declared
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitIfStatement(IfStatement node) {
    decisions++;
    super.visitIfStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    decisions++;
    super.visitForStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    decisions++;
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    decisions++;
    super.visitDoStatement(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    decisions++;
    super.visitCatchClause(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    decisions++;
    super.visitConditionalExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final lexeme = node.operator.lexeme;
    if (lexeme == '&&' || lexeme == '||' || lexeme == '??') {
      decisions++;
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _countSwitch(node.members.length, node.expression);
    super.visitSwitchStatement(node);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _countSwitch(node.cases.length, node.expression);
    super.visitSwitchExpression(node);
  }

  void _countSwitch(int caseCount, Expression selector) {
    if (!countExhaustiveSwitches && _isExhaustible(selector)) {
      decisions++;
      return;
    }

    decisions += caseCount;
  }

  bool _isExhaustible(Expression selector) {
    final element = selector.staticType?.element;

    return switch (element) {
      EnumElement() => true,
      // Edge case: a mixin cannot be sealed, so only enums and sealed classes are exhaustive
      ClassElement(:final isSealed) => isSealed,
      _ => false,
    };
  }
}
