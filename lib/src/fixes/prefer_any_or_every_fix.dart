import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:many_lints/src/rules/prefer_any_or_every.dart';

/// Fix that replaces .where().isEmpty/isNotEmpty with .any()/.every().
class PreferAnyOrEveryFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferAnyOrEvery',
    DartFixKindPriority.standard,
    'Replace with any()/every()',
  );

  PreferAnyOrEveryFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! PropertyAccess) return;

    final property = targetNode.propertyName.name;
    final whereInvocation = targetNode.target;
    if (whereInvocation is! MethodInvocation) return;

    final collection = whereInvocation.target;
    if (collection == null) return;

    final predicate = whereInvocation.argumentList.arguments.firstOrNull;
    if (predicate == null) return;

    final isNotEmpty = property == 'isNotEmpty';
    final String replacement;

    if (isNotEmpty) {
      replacement = '${collection.toSource()}.any(${predicate.toSource()})';
    } else {
      final everyReplacement = buildEveryReplacement(
        collection.toSource(),
        predicate,
      );
      if (everyReplacement == null) return;
      replacement = everyReplacement;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
