import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that converts a switch statement to a switch expression.
///
/// Transforms:
/// ```dart
/// switch (value) {
///   case 1:
///     return 'first';
///   case 2:
///     return 'second';
/// }
/// ```
///
/// Into:
/// ```dart
/// return switch (value) {
///   1 => 'first',
///   2 => 'second',
/// };
/// ```
class PreferSwitchExpressionFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferSwitchExpression',
    DartFixKindPriority.standard,
    'Convert to switch expression',
  );

  PreferSwitchExpressionFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Find the switch statement
    // The rule reports at the `switch` keyword, so the covering node is
    // already the statement — `node.parent` would overshoot it.
    final switchNode = node.thisOrAncestorOfType<SwitchStatement>();
    if (switchNode == null) return;

    // Determine the conversion type and build the replacement
    final replacement = _buildSwitchExpression(switchNode);
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(switchNode), replacement);
    });
  }

  /// Builds a switch expression from a switch statement.
  ///
  /// Returns null if the switch cannot be converted.
  String? _buildSwitchExpression(SwitchStatement switchStmt) {
    final members = switchStmt.members;
    if (members.isEmpty) return null;

    // Check what type of conversion we need. Leading fallthrough cases have
    // no statements of their own, so look at the first member that does.
    final firstStatement = members
        .map((m) => m.statements.firstOrNull)
        .firstWhere((s) => s != null, orElse: () => null);
    if (firstStatement == null) return null;

    final isReturnBased = firstStatement is ReturnStatement;
    final isAssignmentBased =
        firstStatement is ExpressionStatement &&
        firstStatement.expression is AssignmentExpression;

    if (!isReturnBased && !isAssignmentBased) return null;

    // Build the switch expression cases.
    //
    // A fallthrough case (`case a:` with no body) shares the next case's
    // body, which a switch expression writes as a single `a || b` pattern.
    // Pending patterns accumulate until a member with a body closes them.
    final casesBuffer = StringBuffer();
    final pending = <String>[];
    for (final member in members) {
      final pattern = _patternOf(member);

      if (member.statements.isEmpty) {
        pending.add(pattern);
        continue;
      }

      final caseStr = _buildCaseExpression(member, leadingPatterns: pending);
      if (caseStr == null) return null;
      pending.clear();

      casesBuffer.write(caseStr);
      casesBuffer.writeln(',');
    }

    // A trailing fallthrough case has no body to fall into, so the switch is
    // not convertible — bail rather than silently dropping it.
    if (pending.isNotEmpty) return null;

    final expression = switchStmt.expression.toSource();
    final switchExpr = 'switch ($expression) {\n$casesBuffer}';

    if (isReturnBased) {
      return 'return $switchExpr;';
    } else if (isAssignmentBased) {
      // Get the assignment target from the first statement
      final firstExpr = firstStatement.expression;
      final target = (firstExpr as AssignmentExpression).leftHandSide
          .toSource();
      return '$target = $switchExpr;';
    }

    return null;
  }

  /// The pattern text for [member].
  ///
  /// Dart 3 parses `case Foo.bar:` as a `SwitchPatternCase`; only pre-3.0
  /// constant cases are `SwitchCase`.
  String _patternOf(SwitchMember member) => switch (member) {
    SwitchPatternCase(:final guardedPattern) => guardedPattern.toSource(),
    SwitchCase(:final expression) => expression.toSource(),
    SwitchDefault() => '_',
  };

  /// Builds a single case expression for the switch expression.
  ///
  /// [leadingPatterns] holds the patterns of any fallthrough cases directly
  /// above this one; they are joined with `||` so several labels sharing one
  /// body become a single case.
  ///
  /// Returns null if the case cannot be converted.
  String? _buildCaseExpression(
    SwitchMember member, {
    List<String> leadingPatterns = const [],
  }) {
    final statements = member.statements;
    if (statements.isEmpty || statements.length != 1) return null;

    var pattern = _patternOf(member);
    if (leadingPatterns.isNotEmpty) {
      // A `default` reached by fallthrough already covers everything, so
      // `a || _` would be redundant — collapse to the wildcard.
      pattern = member is SwitchDefault
          ? '_'
          : [...leadingPatterns, pattern].join(' || ');
    }

    final statement = statements.first;

    // Extract the value to return/assign
    String? value;

    if (statement is ReturnStatement && statement.expression != null) {
      value = statement.expression!.toSource();
    } else if (statement is ExpressionStatement) {
      final expression = statement.expression;
      if (expression is AssignmentExpression) {
        value = expression.rightHandSide.toSource();
      }
    }

    if (value == null) return null;

    return '  $pattern => $value';
  }
}
