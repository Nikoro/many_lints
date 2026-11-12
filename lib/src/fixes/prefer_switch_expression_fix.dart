import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

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
    final switchNode = node.thisOrAncestorOfType<SwitchStatement>();
    if (switchNode == null) return;

    final replacement = _buildSwitchExpression(switchNode);
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(switchNode), replacement);
    });
  }

  String? _buildSwitchExpression(SwitchStatement switchStmt) {
    final members = switchStmt.members;
    if (members.isEmpty) return null;

    final firstStatement = members
        .map((m) => m.statements.firstOrNull)
        .firstWhere((s) => s != null, orElse: () => null);
    if (firstStatement == null) return null;

    final isReturnBased = firstStatement is ReturnStatement;
    final isAssignmentBased =
        firstStatement is ExpressionStatement &&
        firstStatement.expression is AssignmentExpression;

    if (!isReturnBased && !isAssignmentBased) return null;

    // Edge case: a fallthrough case has no body and joins the next case as one `a || b` pattern
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

    // Edge case: a trailing fallthrough case has no body to fall into
    if (pending.isNotEmpty) return null;

    final expression = switchStmt.expression.toSource();
    final switchExpr = 'switch ($expression) {\n$casesBuffer}';

    if (isReturnBased) {
      return 'return $switchExpr;';
    } else if (isAssignmentBased) {
      final firstExpr = firstStatement.expression;
      final target = (firstExpr as AssignmentExpression).leftHandSide
          .toSource();
      return '$target = $switchExpr;';
    }

    return null;
  }

  String _patternOf(SwitchMember member) => switch (member) {
    SwitchPatternCase(:final guardedPattern) => guardedPattern.toSource(),
    SwitchCase(:final expression) => expression.toSource(),
    SwitchDefault() => '_',
  };

  String? _buildCaseExpression(
    SwitchMember member, {
    List<String> leadingPatterns = const [],
  }) {
    final statements = member.statements;
    if (statements.isEmpty || statements.length != 1) return null;

    var pattern = _patternOf(member);
    if (leadingPatterns.isNotEmpty) {
      // Edge case: a default reached by fallthrough already covers everything, so `a || _` is `_`
      pattern = member is SwitchDefault
          ? '_'
          : [...leadingPatterns, pattern].join(' || ');
    }

    final statement = statements.first;

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
