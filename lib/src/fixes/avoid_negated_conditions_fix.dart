import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that inverts a negated condition and swaps the two branches with it.
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
    // The diagnostic is reported at the condition, so the statement or
    // expression that owns it is one step up.
    final ifStatement = node.thisOrAncestorOfType<IfStatement>();
    if (ifStatement != null && _ownsCondition(ifStatement.expression)) {
      return _fixIfStatement(builder, ifStatement);
    }

    final conditional = node.thisOrAncestorOfType<ConditionalExpression>();
    if (conditional != null && _ownsCondition(conditional.condition)) {
      return _fixConditional(builder, conditional);
    }
  }

  /// Whether [condition] is the expression the diagnostic was reported at.
  ///
  /// Without this, a negated `if` nested inside another negated `if`'s branch
  /// would be rewritten through its outer ancestor, moving code the diagnostic
  /// never pointed at.
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
      // The two branch bodies swap wholesale. Replacing each with the other's
      // text keeps both correctly indented, since they sit at the same level.
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
