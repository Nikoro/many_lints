import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';

/// Fix that converts a public named parameter with a `_field = field`
/// initializer into a private named parameter (`this._field`).
class PreferPrivateNamedParametersFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferPrivateNamedParameters',
    DartFixKindPriority.standard,
    'Convert to a private named parameter',
  );

  PreferPrivateNamedParametersFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final parameter = node.thisOrAncestorOfType<FormalParameter>();
    if (parameter is! RegularFormalParameter) return;

    final parameterName = parameter.name?.lexeme;
    if (parameterName == null) return;

    // Only the same-name case is fixable. Under `only_same_name: false` the
    // rule also reports a renamed parameter (`_id` from `identifier`), but
    // `this._id` would rename the named argument too — a breaking change to
    // the constructor's API that a quick fix must not make silently. The
    // lookup below finds no initializer for `_$parameterName` in that case,
    // so the fix simply declines and the diagnostic stays.
    final fieldName = '_$parameterName';

    final constructor = parameter
        .thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) return;

    final initializer = constructor.initializers
        .whereType<ConstructorFieldInitializer>()
        .firstWhereOrNull(
          (i) =>
              i.fieldName.name == fieldName &&
              i.expression is SimpleIdentifier &&
              (i.expression as SimpleIdentifier).name == parameterName,
        );
    if (initializer == null) return;

    // Rebuild the parameter, preserving `required` and any default value.
    final buffer = StringBuffer();
    if (parameter.requiredKeyword != null) buffer.write('required ');
    buffer.write('this.$fieldName');
    if (parameter.defaultClause case final defaultClause?) {
      buffer.write(
        ' ${defaultClause.separator.lexeme} ${defaultClause.value.toSource()}',
      );
    }

    // Keep parameter metadata (annotations) intact by replacing from the
    // first token after it.
    final SyntacticEntity start =
        parameter.requiredKeyword ??
        parameter.constFinalOrVarKeyword ??
        parameter.type ??
        parameter.name!;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.startEnd(start, parameter),
        buffer.toString(),
      );

      if (constructor.initializers.length == 1) {
        // Remove the whole `: _field = field` clause.
        builder.addDeletion(range.endEnd(constructor.parameters, initializer));
      } else {
        builder.addDeletion(
          range.nodeInList(constructor.initializers, initializer),
        );
      }
    });
  }
}
