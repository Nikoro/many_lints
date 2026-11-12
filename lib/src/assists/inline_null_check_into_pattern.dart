import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../null_check_pattern_conversion.dart';

class InlineNullCheckIntoPattern extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.inlineNullCheckIntoPattern',
    31,
    'Convert null check to destructuring pattern',
  );

  InlineNullCheckIntoPattern({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final guard = NullCheckGuard.tryRead(node);
    if (guard == null) return;

    final typeName = _typeNameOf(guard.checked);
    if (typeName == null) return;

    final asserted = _assertedField(guard);
    if (asserted == null) return;

    final (fieldName, accesses) = asserted;

    final prefix = '${guard.checkedSource} case $typeName(:final ';
    final replacement = '$prefix$fieldName?)';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(guard.condition.offset, guard.condition.length),
        replacement,
      );

      for (final access in accesses) {
        builder.addSimpleReplacement(
          SourceRange(access.offset, access.length),
          fieldName,
        );
      }

      builder.addLinkedPosition(
        SourceRange(guard.condition.offset + prefix.length, fieldName.length),
        fieldName,
      );
    });
  }

  String? _typeNameOf(Expression expression) {
    final type = expression.staticType;
    if (type is! InterfaceType) return null;
    if (type.typeArguments.isNotEmpty) return null;

    return type.element.name;
  }

  (String, List<AstNode>)? _assertedField(NullCheckGuard guard) {
    final accessesByField = <String, List<AstNode>>{};

    for (final bang in guard.bangsInGuardedBranch) {
      final parent = bang.parent;

      if (parent is! PropertyAccess) return null;
      if (parent.target != bang) return null;

      // Edge case: without the inner bang the branch never asserted the field is non-null
      final outer = parent.parent;
      if (outer is! PostfixExpression) return null;
      if (outer.operator.lexeme != '!') return null;

      accessesByField
          .putIfAbsent(parent.propertyName.name, () => [])
          .add(outer);
    }

    if (accessesByField.length != 1) return null;

    final entry = accessesByField.entries.first;
    return (entry.key, entry.value);
  }
}
