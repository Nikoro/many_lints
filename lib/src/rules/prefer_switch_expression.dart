import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Suggests converting switch statements to switch expressions.
///
/// In cases where all branches of a switch statement have a return statement or
/// assign to the same variable, using a switch expression can make the code more
/// compact and easier to understand.
///
/// **BAD:**
/// ```dart
/// String getType(int value) {
///   switch (value) {
///     case 1:
///       return 'first';
///     case 2:
///       return 'second';
///   }
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// String getType(int value) {
///   return switch (value) {
///     1 => 'first',
///     2 => 'second',
///   };
/// }
/// ```
class PreferSwitchExpression extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_switch_expression',
    'This switch statement can be converted to a switch expression.',
    correctionMessage: 'Try using a switch expression instead.',
  );

  PreferSwitchExpression()
    : super(
        name: 'prefer_switch_expression',
        description:
            'Suggests converting switch statements to switch expressions.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addSwitchStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSwitchExpression rule;

  _Visitor(this.rule);

  @override
  void visitSwitchStatement(SwitchStatement node) {
    // Get all switch members (cases and defaults)
    final members = node.members;
    if (members.isEmpty) return;

    // Check if all cases can be converted to expression form
    final canConvert = _canConvertToExpression(members);
    if (!canConvert) return;

    // Report the lint at the switch keyword
    rule.reportAtToken(node.switchKeyword);
  }

  /// Checks if a switch statement can be converted to a switch expression.
  ///
  /// Returns true if:
  /// - All case bodies have exactly one return statement, OR
  /// - All case bodies assign to the same variable
  /// - There are no fallthrough cases (cases without a body)
  /// - No mixing of returns and assignments
  bool _canConvertToExpression(List<SwitchMember> members) {
    String? assignmentTarget;
    bool hasReturn = false;
    // Tracks a fallthrough case still waiting for a body to share.
    bool pendingFallthrough = false;

    for (final member in members) {
      final statements = member.statements;

      // A fallthrough case (no statements of its own) shares the next case's
      // body. A switch expression writes that as `a || b`, so with
      // `allow_fallthrough_cases: true` these are convertible too and the
      // quick fix joins the patterns. Off by default because it changes a
      // familiar shape into a less familiar one.
      if (statements.isEmpty) {
        if (rule.config.boolOption(
          'allow_fallthrough_cases',
          defaultValue: false,
        )) {
          pendingFallthrough = true;
          continue;
        }
        return false;
      }

      pendingFallthrough = false;

      // Check if the case has exactly one statement
      if (statements.length != 1) return false;

      final statement = statements.first;

      // Case 1: Single return statement
      if (statement is ReturnStatement && statement.expression != null) {
        // If we've already seen an assignment, this is inconsistent
        if (assignmentTarget != null) return false;
        hasReturn = true;
        continue;
      }

      // Case 2: Single expression statement with assignment
      if (statement is ExpressionStatement) {
        final expression = statement.expression;
        if (expression is AssignmentExpression &&
            expression.leftHandSide is SimpleIdentifier) {
          // If we've already seen a return, this is inconsistent
          if (hasReturn) return false;

          final target = (expression.leftHandSide as SimpleIdentifier).name;

          // First assignment we've seen
          if (assignmentTarget == null) {
            assignmentTarget = target;
          } else if (assignmentTarget != target) {
            // Different assignment targets
            return false;
          }
          continue;
        }
      }

      // Any other statement type means we can't convert
      return false;
    }

    // A trailing fallthrough has no body to fall into, so there is nothing to
    // merge its pattern with. The quick fix bails on the same shape.
    return !pendingFallthrough;
  }
}
