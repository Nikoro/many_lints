import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that collapses a declare-then-return pair into a single return.
class PreferImmediateReturnFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferImmediateReturn',
    DartFixKindPriority.standard,
    'Return the expression directly',
  );

  PreferImmediateReturnFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node
        .thisOrAncestorOfType<VariableDeclarationStatement>();
    if (declaration == null) return;

    final block = declaration.parent;
    if (block is! Block) return;

    final index = block.statements.indexOf(declaration);
    if (index == -1 || index != block.statements.length - 2) return;

    final returnStatement = block.statements.last;
    if (returnStatement is! ReturnStatement) return;

    final initializer = declaration.variables.variables.first.initializer;
    if (initializer == null) return;

    await builder.addDartFileEdit(file, (builder) {
      // Replace both statements with a single return of the initializer.
      builder.addSimpleReplacement(
        range.startEnd(declaration, returnStatement),
        'return ${initializer.toSource()};',
      );
    });
  }
}
