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
    final switchNode = node.parent;
    if (switchNode is! SwitchStatement) return;

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

    // Check what type of conversion we need
    final firstStatement = members.first.statements.firstOrNull;
    if (firstStatement == null) return null;

    final isReturnBased = firstStatement is ReturnStatement;
    final isAssignmentBased =
        firstStatement is ExpressionStatement &&
        firstStatement.expression is AssignmentExpression;

    if (!isReturnBased && !isAssignmentBased) return null;

    // Build the switch expression cases
    final casesBuffer = StringBuffer();
    for (var i = 0; i < members.length; i++) {
      final member = members[i];
      final caseStr = _buildCaseExpression(member);
      if (caseStr == null) return null;

      casesBuffer.write(caseStr);
      if (i < members.length - 1) {
        casesBuffer.writeln(',');
      } else {
        casesBuffer.writeln(',');
      }
    }

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

  /// Builds a single case expression for the switch expression.
  ///
  /// Returns null if the case cannot be converted.
  String? _buildCaseExpression(SwitchMember member) {
    final statements = member.statements;
    if (statements.isEmpty || statements.length != 1) return null;

    String pattern;

    // Get the pattern/guard
    if (member is SwitchCase) {
      pattern = member.expression.toSource();
    } else if (member is SwitchDefault) {
      pattern = '_';
    } else {
      return null;
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
