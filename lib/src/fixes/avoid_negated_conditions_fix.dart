import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AvoidNegatedConditionsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidNegatedConditions',
    DartFixKindPriority.standard,
    'Invert the condition and swap the branches',
  );

  AvoidNegatedConditionsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final ifStatement = node.thisOrAncestorOfType<IfStatement>();
    if (ifStatement != null && _ownsCondition(ifStatement.expression)) {
      return _fixIfStatement(builder, ifStatement);
    }

    final conditional = node.thisOrAncestorOfType<ConditionalExpression>();
    if (conditional != null && _ownsCondition(conditional.condition)) {
      return _fixConditional(builder, conditional);
    }
  }

  bool _ownsCondition(Expression condition) =>
      condition == node || condition.offset == node.offset;

  Future<void> _fixIfStatement(
    ChangeBuilder builder,
    IfStatement statement,
  ) async {
    final elseStatement = statement.elseStatement;
    if (elseStatement == null || elseStatement is IfStatement) return;

    final inverted = utils.invertCondition(statement.expression);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(statement.expression), inverted);
      // Edge case: both branches sit at the same depth, so swapping their text keeps indentation
      builder.addSimpleReplacement(
        range.node(statement.thenStatement),
        utils.getNodeText(elseStatement),
      );
      builder.addSimpleReplacement(
        range.node(elseStatement),
        utils.getNodeText(statement.thenStatement),
      );
    });
  }

  Future<void> _fixConditional(
    ChangeBuilder builder,
    ConditionalExpression expression,
  ) async {
    final inverted = utils.invertCondition(expression.condition);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(expression.condition), inverted);
      builder.addSimpleReplacement(
        range.node(expression.thenExpression),
        utils.getNodeText(expression.elseExpression),
      );
      builder.addSimpleReplacement(
        range.node(expression.elseExpression),
        utils.getNodeText(expression.thenExpression),
      );
    });
  }
}
