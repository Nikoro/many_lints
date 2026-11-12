import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class PreferTypeOverVarFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferTypeOverVar',
    DartFixKindPriority.standard,
    "Replace 'var' with explicit type",
  );

  PreferTypeOverVarFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final parent = node.thisOrAncestorOfType<VariableDeclarationList>();
    if (parent == null) return;

    final variables = parent.variables;
    if (variables.isEmpty) return;

    final firstVariable = variables.first;
    final initializer = firstVariable.initializer;
    if (initializer == null) return;

    final inferredType = initializer.staticType;
    if (inferredType == null) return;

    final typeString = inferredType.getDisplayString();

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(parent.keyword!), typeString);
    });
  }
}
