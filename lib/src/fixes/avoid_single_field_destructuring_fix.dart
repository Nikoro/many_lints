import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces single-field destructuring with direct property access.
class AvoidSingleFieldDestructuringFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidSingleFieldDestructuring',
    DartFixKindPriority.standard,
    'Replace with direct property access',
  );

  AvoidSingleFieldDestructuringFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! PatternVariableDeclaration) return;

    final pattern = targetNode.pattern;

    final PatternField field;
    if (pattern is ObjectPattern && pattern.fields.length == 1) {
      field = pattern.fields.first;
    } else if (pattern is RecordPattern && pattern.fields.length == 1) {
      field = pattern.fields.first;
    } else {
      return;
    }

    final fieldName = field.effectiveName;
    if (fieldName == null) return;

    final innerPattern = field.pattern;
    if (innerPattern is! DeclaredVariablePattern) return;

    final varName = innerPattern.name.lexeme;
    final keyword = targetNode.keyword.lexeme;
    final expressionSource = targetNode.expression.toSource();

    final replacement = '$keyword $varName = $expressionSource.$fieldName';

    // Replace the entire PatternVariableDeclaration (without trailing semicolon)
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
