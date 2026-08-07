// Ported from riverpod_lint (MIT, Copyright (c) 2023 Remi Rousselet).
// See the NOTICE file at the repository root.

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Fix that adds a stub `build` method to a `@riverpod` class.
class NotifierBuildFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.notifierBuild',
    DartFixKindPriority.standard,
    'Add build method',
  );

  NotifierBuildFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // The rule reports at the class name token.
    final classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDeclaration == null) return;

    final body = classDeclaration.body;
    if (body is! BlockClassBody) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(body.leftBracket.end, '''

  @override
  dynamic build() {
    // TODO: implement build
    throw UnimplementedError();
  }
''');
    });
  }
}
