import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a function has more independent paths through it than the
/// configured budget.
///
/// Cyclomatic complexity counts decisions: every branch, loop, `catch`, `&&`,
/// `||`, `?:` and `??` adds one path a reader has to keep straight and a test
/// has to cover. It measures something the line and statement budgets miss —
/// twenty sequential statements are easy, while six nested conditions in five
/// lines are not.
///
/// The limit is `max_complexity`, defaulting to 10, which is the threshold
/// most tools have converged on.
///
/// A `switch` is counted per case, since each is a distinct path. But an
/// *exhaustive* switch over an enum or sealed type is counted as one by
/// default: the compiler proves every case is handled, so the paths are not
/// something the reader has to verify, and counting them would report exactly
/// the exhaustive pattern matching Dart 3 encourages. Set
/// `count_exhaustive_switches: true` to count them individually.
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

/// The threshold most complexity tools have settled on.
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

    // A hand-written `==` is one `&&` per field, and a `copyWith` is one `??`
    // per parameter. Both grow with the field count rather than with any
    // decision the reader has to follow, and neither can be split — so their
    // complexity is not the kind this rule is about. Together they were the
    // majority of the rule's hits on a production codebase.
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

    // Complexity starts at 1: a function with no decisions still has one path.
    final complexity = counter.decisions + 1;
    if (complexity <= maxComplexity) return;

    final arguments = ['$complexity', '$maxComplexity'];
    if (name != null) {
      rule.reportAtToken(name, arguments: arguments);
    } else if (fallback != null) {
      rule.reportAtNode(fallback, arguments: arguments);
    }
  }

  /// Whether [name] belongs to a member whose branch count is decided by how
  /// many fields the class has, rather than by its own logic.
  bool _isFieldCountShaped(Token? name) => switch (name?.lexeme) {
    '==' || 'copyWith' => true,
    _ => false,
  };
}

/// Counts the decision points of one function, not descending into nested
/// function bodies — a callback is measured against its own budget.
class _ComplexityCounter extends RecursiveAstVisitor<void> {
  _ComplexityCounter({required this.countExhaustiveSwitches});

  final bool countExhaustiveSwitches;

  int decisions = 0;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // A callback carries its own complexity, measured where it is declared.
  }

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

  /// Whether the compiler can prove a switch over [selector] exhaustive, in
  /// which case its cases are not paths the reader has to check.
  ///
  /// Read from the static type rather than the cases, so it holds regardless
  /// of how the patterns are written.
  bool _isExhaustible(Expression selector) {
    final element = selector.staticType?.element;

    // A mixin cannot be sealed in Dart, so `class` and `enum` are the only
    // declarations a switch can be exhaustive over.
    return switch (element) {
      EnumElement() => true,
      ClassElement(:final isSealed) => isSealed,
      _ => false,
    };
  }
}
