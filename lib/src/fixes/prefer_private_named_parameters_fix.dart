import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';

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

    // Edge case: only same-name is fixed; `this._id` for `identifier` would rename the argument
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

    final buffer = StringBuffer();
    if (parameter.requiredKeyword != null) buffer.write('required ');
    buffer.write('this.$fieldName');
    if (parameter.defaultClause case final defaultClause?) {
      buffer.write(
        ' ${defaultClause.separator.lexeme} ${defaultClause.value.toSource()}',
      );
    }

    // Edge case: starting at `required` or the type keeps the parameter's annotations
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
        builder.addDeletion(range.endEnd(constructor.parameters, initializer));
      } else {
        builder.addDeletion(
          range.nodeInList(constructor.initializers, initializer),
        );
      }
    });
  }
}
