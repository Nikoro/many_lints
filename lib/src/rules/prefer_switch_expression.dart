import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Suggests converting switch statements to switch expressions.
///
/// In cases where all branches of a switch statement have a return statement or
/// assign to the same variable, using a switch expression can make the code more
/// compact and easier to understand.
///
/// Only reported when the switch is exhaustive: it has a `default` or `_` case,
/// or switches over an enum, a sealed type, or a `bool`. A switch that can fall
/// through to the code after it has no expression form.
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

    // A switch that can fall through to the following code cannot become an
    // expression.
    if (!isExhaustiveSwitch(node) && trailingReturnOf(node) == null) return;

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

/// Whether every input reaches a case of [node].
///
/// Dart 3 already requires a switch statement over an enum, a sealed type, or
/// a `bool` to be exhaustive, so those need no scan of the cases. Anything
/// else is exhaustive only through a catch-all.
bool isExhaustiveSwitch(SwitchStatement node) {
  final hasCatchAll = node.members.any(
    (member) => switch (member) {
      SwitchDefault() => true,
      SwitchPatternCase(:final guardedPattern) =>
        guardedPattern.pattern is WildcardPattern &&
            guardedPattern.whenClause == null,
      _ => false,
    },
  );
  if (hasCatchAll) return true;

  final type = node.expression.staticType;
  if (type == null) return false;
  if (type.isDartCoreBool) return true;

  return switch (type.element) {
    EnumElement() => true,
    ClassElement(:final isSealed) => isSealed,
    _ => false,
  };
}

/// The final `return value;` of the block holding [node], when it directly
/// follows [node] and [node] is return-based.
///
/// That statement is what a non-exhaustive return-based switch falls through
/// to, so it can become the switch expression's `_` case. Anything else
/// between the switch and the end of the block is code the expression could
/// not reproduce.
ReturnStatement? trailingReturnOf(SwitchStatement node) {
  final isReturnBased = node.members
      .expand((member) => member.statements)
      .every((statement) => statement is ReturnStatement);
  if (!isReturnBased) return null;

  final parent = node.parent;
  if (parent is! Block) return null;

  final statements = parent.statements;
  if (statements.length < 2 || statements[statements.length - 2] != node) {
    return null;
  }

  final last = statements.last;
  return last is ReturnStatement && last.expression != null ? last : null;
}
