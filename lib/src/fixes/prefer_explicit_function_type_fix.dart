import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class PreferExplicitFunctionTypeFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferExplicitFunctionType',
    DartFixKindPriority.standard,
    "Convert to 'void Function()'",
  );

  PreferExplicitFunctionTypeFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! NamedType) return;

    if (targetNode.name.lexeme != 'Function') return;

    await builder.addDartFileEdit(file, (builder) {
      final isNullable = targetNode.question != null;
      final replacement = isNullable ? 'void Function()?' : 'void Function()';

      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
