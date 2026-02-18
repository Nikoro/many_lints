import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces `Isolate.run(callback)` with `compute(callback, null)`.
///
/// Transforms the callback to accept a message parameter since `compute`
/// requires `ComputeCallback<Q, R>` which takes one argument.
class PreferComputeOverIsolateRunFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferComputeOverIsolateRun',
    DartFixKindPriority.standard,
    "Replace with 'compute()'",
  );

  PreferComputeOverIsolateRunFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! MethodInvocation) return;

    final args = targetNode.argumentList.arguments;
    if (args.isEmpty) return;

    final callback = args.first;
    final callbackSource = _transformCallback(callback);

    await builder.addDartFileEdit(file, (builder) {
      builder.importLibrary(Uri.parse('package:flutter/foundation.dart'));
      builder.addSimpleReplacement(
        range.node(targetNode),
        'compute($callbackSource, null)',
      );
    });
  }

  /// Transforms the callback to accept a message parameter.
  ///
  /// - `() => expr` → `(_) => expr`
  /// - `() { body }` → `(_) { body }`
  /// - `() async => expr` → `(_) async => expr`
  /// - `() async { body }` → `(_) async { body }`
  /// - `myFunction` → `(_) => myFunction()`
  String _transformCallback(Expression callback) {
    if (callback is FunctionExpression) {
      final params = callback.parameters;
      if (params != null && params.parameters.isEmpty) {
        // Replace empty parens () with (_)
        final source = callback.toSource();
        final paramsSource = params.toSource();
        return source.replaceFirst(paramsSource, '(_)');
      }
      return callback.toSource();
    }

    // For identifier references (e.g., myFunction), wrap as (_) => myFunction()
    return '(_) => ${callback.toSource()}()';
  }
}
