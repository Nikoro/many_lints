import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AvoidIncompleteCopyWithFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidIncompleteCopyWith',
    DartFixKindPriority.standard,
    'Add missing parameters to copyWith',
  );

  AvoidIncompleteCopyWithFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final copyWithMethod = node.thisOrAncestorOfType<MethodDeclaration>();
    if (copyWithMethod == null) return;

    final classNode = copyWithMethod.thisOrAncestorOfType<ClassDeclaration>();
    if (classNode == null) return;

    final classBody = classNode.body;
    if (classBody is! BlockClassBody) return;

    final constructor = classBody.members
        .whereType<ConstructorDeclaration>()
        .where((c) => c.name == null)
        .firstOrNull;
    if (constructor == null) return;

    final constructorParams = <String, String?>{};
    for (final param in constructor.parameters.parameters) {
      final (name, type) = _extractParamInfo(param);
      if (name != null) constructorParams[name] = type;
    }

    final copyWithParams = <String>{};
    final parameters = copyWithMethod.parameters?.parameters;
    if (parameters != null) {
      for (final param in parameters) {
        final (name, _) = _extractParamInfo(param);
        if (name != null) copyWithParams.add(name);
      }
    }

    final missing = constructorParams.keys.where(
      (k) => !copyWithParams.contains(k),
    );
    if (missing.isEmpty) return;

    final newParams = missing.map((name) {
      final type = constructorParams[name];
      if (type != null) {
        final nullableType = type.endsWith('?') ? type : '$type?';
        return '$nullableType $name';
      }
      return 'dynamic $name';
    });

    final parameterList = copyWithMethod.parameters;
    if (parameterList == null) return;

    final hasNamedParams = parameterList.parameters.any((p) => p.isNamed);

    final insertParams = newParams.join(', ');

    await builder.addDartFileEdit(file, (builder) {
      if (hasNamedParams && parameters != null && parameters.isNotEmpty) {
        final lastParam = parameters.last;
        builder.addSimpleInsertion(lastParam.end, ', $insertParams');
      } else if (hasNamedParams) {
        final leftBrace = parameterList.leftDelimiter;
        if (leftBrace == null) return;
        builder.addSimpleInsertion(leftBrace.end, insertParams);
      } else {
        final rightParen = parameterList.rightParenthesis;
        if (parameters != null && parameters.isNotEmpty) {
          final lastParam = parameters.last;
          builder.addSimpleInsertion(lastParam.end, ', {$insertParams}');
        } else {
          builder.addSimpleInsertion(rightParen.offset, '{$insertParams}');
        }
      }
    });
  }

  static (String?, String?) _extractParamInfo(FormalParameter param) {
    final name = param.name?.lexeme;

    if (param is RegularFormalParameter && param.functionTypedSuffix != null) {
      return (name, null);
    }

    final annotation = param.type?.toSource();
    if (annotation != null) return (name, annotation);

    // Edge case: a field formal has no annotation, so without the element type it becomes dynamic
    final type = param.declaredFragment?.element.type;
    if (type == null) return (name, null);

    return (name, type.getDisplayString());
  }
}
