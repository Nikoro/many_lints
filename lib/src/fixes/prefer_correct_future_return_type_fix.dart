import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../type_checker.dart';

/// Fix that gives an `async` declaration a non-nullable `Future` return type.
class PreferCorrectFutureReturnTypeFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferCorrectFutureReturnType',
    DartFixKindPriority.standard,
    "Use a non-nullable 'Future' return type",
  );

  PreferCorrectFutureReturnTypeFix({required super.context});

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');
  static const _futureOrChecker = TypeChecker.fromUrl('dart:async#FutureOr');

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final annotation = node.thisOrAncestorOfType<NamedType>();
    final type = annotation?.type;
    if (annotation == null || type == null) return;

    String replacement;
    if (_futureChecker.isExactlyType(type)) {
      if (annotation.question == null) return;
      final valueType = _valueTypeSource(annotation);
      if (valueType == null) return;
      replacement = 'Future<$valueType>';
    } else if (_futureOrChecker.isExactlyType(type)) {
      final valueType = _valueTypeSource(annotation);
      if (valueType == null) return;
      replacement = 'Future<$valueType>';
    } else if (type is DynamicType || type.isDartCoreObject) {
      replacement = 'Future<${annotation.toSource()}>';
    } else {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(annotation), replacement);
    });
  }

  String? _valueTypeSource(NamedType annotation) {
    final arguments = annotation.typeArguments?.arguments;
    if (arguments == null || arguments.length != 1) return null;
    return arguments.first.toSource();
  }
}
