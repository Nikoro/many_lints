import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces `.keys.contains(key)` with `.containsKey(key)`.
class AvoidMapKeysContainsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidMapKeysContains',
    DartFixKindPriority.standard,
    'Replace with containsKey()',
  );

  AvoidMapKeysContainsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! MethodInvocation) return;

    final keysAccess = targetNode.target;

    final String mapSource;
    if (keysAccess is PrefixedIdentifier) {
      mapSource = keysAccess.prefix.toSource();
    } else if (keysAccess is PropertyAccess) {
      final mapExpr = keysAccess.target;
      if (mapExpr == null) return;
      mapSource = mapExpr.toSource();
    } else {
      return;
    }

    final arg = targetNode.argumentList.arguments.firstOrNull;
    if (arg == null) return;

    final replacement = '$mapSource.containsKey(${arg.toSource()})';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
