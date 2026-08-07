// Ported from riverpod_lint (MIT, Copyright (c) 2023 Remi Rousselet).
// See the NOTICE file at the repository root.

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Fix that wraps the root widget passed to `runApp()` in a `ProviderScope`.
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
    // The rule reports at the `runApp` identifier.
    final invocation = node.parent;
    if (invocation is! MethodInvocation) return;

    final rootWidget = invocation.argumentList.arguments.firstOrNull;
    if (rootWidget == null) return;

    await builder.addDartFileEdit(file, (builder) {
      // Prefer a Riverpod library the file already imports, so hooks_riverpod
      // users do not gain a redundant flutter_riverpod import.
      final providerScope = _referenceProviderScope(builder);

      builder.addSimpleInsertion(rootWidget.offset, '$providerScope(child: ');
      builder.addSimpleInsertion(rootWidget.end, ')');
    });
  }

  /// Returns the source to reference `ProviderScope`, importing a library that
  /// exports it when the file does not already have one.
  String _referenceProviderScope(DartFileEditBuilder builder) {
    final candidates = [
      Uri.parse('package:hooks_riverpod/hooks_riverpod.dart'),
      Uri.parse('package:flutter_riverpod/flutter_riverpod.dart'),
    ];

    // Fall back to flutter_riverpod, adding the import when none is present.
    final target = candidates.firstWhere(
      builder.importsLibrary,
      orElse: () => candidates.last,
    );

    final prefix = builder.importLibraryElement(target).prefix;
    return prefix == null ? 'ProviderScope' : '$prefix.ProviderScope';
  }
}
