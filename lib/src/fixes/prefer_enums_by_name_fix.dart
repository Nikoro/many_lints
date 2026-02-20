import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';

/// Fix that replaces `.firstWhere((e) => e.name == value)` with `.byName(value)`.
class PreferEnumsByNameFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferEnumsByName',
    DartFixKindPriority.standard,
    'Replace with .byName()',
  );

  PreferEnumsByNameFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! MethodInvocation) return;
    if (targetNode.methodName.name != 'firstWhere') return;

    final target = targetNode.target;
    if (target == null) return;

    final args = targetNode.argumentList.arguments;
    if (args.isEmpty) return;

    final callback = args.first;
    if (callback is! FunctionExpression) return;

    final params = callback.parameters?.parameters;
    if (params == null || params.length != 1) return;
    final paramName = params.first.name?.lexeme;
    if (paramName == null) return;

    final bodyExpr = maybeGetSingleReturnExpression(callback.body);
    if (bodyExpr is! BinaryExpression) return;
    if (bodyExpr.operator.type != TokenType.EQ_EQ) return;

    // Extract the value being compared (the non-param.name side)
    final String valueSource;
    if (_isParamNameAccess(bodyExpr.leftOperand, paramName)) {
      valueSource = bodyExpr.rightOperand.toSource();
    } else if (_isParamNameAccess(bodyExpr.rightOperand, paramName)) {
      valueSource = bodyExpr.leftOperand.toSource();
    } else {
      return;
    }

    final replacement = '${target.toSource()}.byName($valueSource)';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }

  static bool _isParamNameAccess(Expression expr, String paramName) {
    if (expr case PrefixedIdentifier(
      prefix: SimpleIdentifier(name: final prefix),
      identifier: SimpleIdentifier(name: 'name'),
    ) when prefix == paramName) {
      return true;
    }
    if (expr case PropertyAccess(
      target: SimpleIdentifier(name: final prefix),
      propertyName: SimpleIdentifier(name: 'name'),
    ) when prefix == paramName) {
      return true;
    }
    return false;
  }
}
