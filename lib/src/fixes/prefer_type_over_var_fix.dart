import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces 'var' with an explicit type annotation.
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
    // The node should be the 'var' keyword token
    // We need to navigate to the VariableDeclarationList
    final parent = node.parent;
    if (parent is! VariableDeclarationList) return;

    final variables = parent.variables;
    if (variables.isEmpty) return;

    // Get the type from the first variable's initializer
    final firstVariable = variables.first;
    final initializer = firstVariable.initializer;
    if (initializer == null) return;

    final inferredType = initializer.staticType;
    if (inferredType == null) return;

    // Get the type string representation
    final typeString = inferredType.getDisplayString();

    await builder.addDartFileEdit(file, (builder) {
      // Replace 'var' keyword with the explicit type
      builder.addSimpleReplacement(range.token(parent.keyword!), typeString);
    });
  }
}
