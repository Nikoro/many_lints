// SPDX-FileCopyrightText: 2023 Remi Rousselet
// SPDX-License-Identifier: MIT

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class MissingProviderScopeFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.missingProviderScope',
    DartFixKindPriority.standard,
    'Wrap with ProviderScope',
  );

  MissingProviderScopeFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = node.parent;
    if (invocation is! MethodInvocation) return;

    final rootWidget = invocation.argumentList.arguments.firstOrNull;
    if (rootWidget == null) return;

    await builder.addDartFileEdit(file, (builder) {
      // Edge case: reusing an imported Riverpod library spares hooks_riverpod users a second import
      final providerScope = _referenceProviderScope(builder);

      builder.addSimpleInsertion(rootWidget.offset, '$providerScope(child: ');
      builder.addSimpleInsertion(rootWidget.end, ')');
    });
  }

  String _referenceProviderScope(DartFileEditBuilder builder) {
    final candidates = [
      Uri.parse('package:hooks_riverpod/hooks_riverpod.dart'),
      Uri.parse('package:flutter_riverpod/flutter_riverpod.dart'),
    ];

    final target = candidates.firstWhere(
      builder.importsLibrary,
      orElse: () => candidates.last,
    );

    final prefix = builder.importLibraryElement(target).prefix;
    return prefix == null ? 'ProviderScope' : '$prefix.ProviderScope';
  }
}
