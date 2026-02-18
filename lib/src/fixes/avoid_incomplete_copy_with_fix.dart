import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Fix that adds missing constructor parameters to a `copyWith` method.
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
    // node is the copyWith method name token — parent is MethodDeclaration
    final copyWithMethod = node.parent;
    if (copyWithMethod is! MethodDeclaration) return;

    final classDecl = copyWithMethod.parent;
    if (classDecl is! BlockClassBody) return;
    final classNode = classDecl.parent;
    if (classNode is! ClassDeclaration) return;

    // Find the default (unnamed) constructor
    final constructor = classDecl.members
        .whereType<ConstructorDeclaration>()
        .where((c) => c.name == null)
        .firstOrNull;
    if (constructor == null) return;

    // Collect constructor parameter names and their types
    final constructorParams = <String, String?>{};
    for (final param in constructor.parameters.parameters) {
      final (name, type) = _extractParamInfo(param);
      if (name != null) constructorParams[name] = type;
    }

    // Collect copyWith parameter names
    final copyWithParams = <String>{};
    final parameters = copyWithMethod.parameters?.parameters;
    if (parameters != null) {
      for (final param in parameters) {
        final (name, _) = _extractParamInfo(param);
        if (name != null) copyWithParams.add(name);
      }
    }

    // Find missing parameters
    final missing = constructorParams.keys.where(
      (k) => !copyWithParams.contains(k),
    );
    if (missing.isEmpty) return;

    // Build new parameter strings
    final newParams = missing.map((name) {
      final type = constructorParams[name];
      if (type != null) {
        final nullableType = type.endsWith('?') ? type : '$type?';
        return '$nullableType $name';
      }
      return 'dynamic $name';
    });

    // Find insertion point for parameters
    final parameterList = copyWithMethod.parameters;
    if (parameterList == null) return;

    // Determine if using named parameters (has { })
    final hasNamedParams = parameterList.parameters.any(
      (p) => p is DefaultFormalParameter && p.isNamed,
    );

    final insertParams = newParams.join(', ');

    await builder.addDartFileEdit(file, (builder) {
      if (hasNamedParams && parameters != null && parameters.isNotEmpty) {
        // Insert after last existing parameter
        final lastParam = parameters.last;
        builder.addSimpleInsertion(lastParam.end, ', $insertParams');
      } else if (hasNamedParams) {
        // Empty named params — insert between { }
        final leftBrace = parameterList.leftDelimiter;
        if (leftBrace == null) return;
        builder.addSimpleInsertion(leftBrace.end, insertParams);
      } else {
        // No named params — wrap in { }
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
    final actual = switch (param) {
      DefaultFormalParameter(:final parameter) => parameter,
      _ => param,
    };

    final name = actual.name?.lexeme;
    String? type;

    if (actual is SimpleFormalParameter && actual.type != null) {
      type = actual.type!.toSource();
    } else if (actual is FieldFormalParameter) {
      type = actual.type?.toSource();
    } else if (actual is SuperFormalParameter) {
      type = actual.type?.toSource();
    }

    return (name, type);
  }
}
