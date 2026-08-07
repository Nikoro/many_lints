// Ported from riverpod_lint (MIT, Copyright (c) 2023 Remi Rousselet).
// See the NOTICE file at the repository root.

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces `AsyncValue(:final value?)` with
/// `AsyncValue(:final value, hasValue: true)`.
class AsyncValueNullablePatternFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.asyncValueNullablePattern',
    DartFixKindPriority.standard,
    'Replace null check with hasValue: true',
  );

  AsyncValueNullablePatternFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! NullCheckPattern) return;

    await builder.addDartFileEdit(file, (builder) {
      // Drop the `?` and add the explicit `hasValue` check instead.
      builder.addDeletion(range.token(targetNode.operator));
      builder.addSimpleInsertion(targetNode.operator.end, ', hasValue: true');
    });
  }
}
