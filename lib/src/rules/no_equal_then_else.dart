import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when both branches of an `if`/`else` or a conditional expression are
/// identical.
///
/// If both branches do the same thing, the condition decides nothing. Either
/// one branch was meant to differ — the usual case, and a real bug — or the
/// branching is dead weight that should collapse to a single statement.
///
/// **Bad:**
/// ```dart
/// if (isAdmin) {
///   showDashboard();
/// } else {
///   showDashboard(); // the condition changes nothing
/// }
/// ```
///
/// **Good:**
/// ```dart
/// showDashboard();
/// ```
class NoEqualThenElse extends ManyLintsRule {
  static const LintCode code = LintCode(
    'no_equal_then_else',
    'Both branches of this condition are identical.',
    correctionMessage:
        'The condition decides nothing. Make one branch differ, or remove '
        'the branching entirely.',
  );

  NoEqualThenElse()
    : super(
        name: 'no_equal_then_else',
        description:
            'Warns when the then and else branches of an if statement or '
            'conditional expression are identical.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addIfStatement(this, visitor);
    registry.addConditionalExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final NoEqualThenElse rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    final elseStatement = node.elseStatement;
    if (elseStatement == null) return;

    // An `else if` chain is a different shape: comparing the first branch
    // against a whole nested `if` says nothing useful.
    if (elseStatement is IfStatement) return;

    if (_sameSource(node.thenStatement, elseStatement)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    if (_sameSource(node.thenExpression, node.elseExpression)) {
      rule.reportAtNode(node);
    }
  }

  /// Whether two nodes have identical source text, ignoring the block braces
  /// that wrap a single statement.
  ///
  /// Comparing source rather than structure keeps this simple and honest: two
  /// branches that read the same are the ones worth reporting, and anything
  /// that merely computes the same result is beyond a lint's reach.
  bool _sameSource(AstNode first, AstNode second) {
    final a = _unwrap(first);
    final b = _unwrap(second);

    // An empty branch pair is `if (x) {} else {}` — dead code the author is
    // usually mid-way through writing, and noisy to report.
    if (a.isEmpty || b.isEmpty) return false;

    return a == b;
  }

  /// The source of [node], with a single-statement block reduced to that
  /// statement so `{ f(); }` and `f();` compare equal.
  String _unwrap(AstNode node) {
    if (node case Block(:final statements) when statements.length == 1) {
      return statements.first.toSource();
    }

    if (node case Block(:final statements) when statements.isEmpty) return '';

    return node.toSource();
  }
}
