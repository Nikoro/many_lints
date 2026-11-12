import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';
import '../bloc_type_checkers.dart';

class PreferMultiBlocProviderFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferMultiBlocProvider',
    DartFixKindPriority.standard,
    'Convert to Multi* provider',
  );

  PreferMultiBlocProviderFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  static const _providerTypes = [
    (blocProviderChecker, 'MultiBlocProvider'),
    (blocListenerChecker, 'MultiBlocListener'),
    (repositoryProviderChecker, 'MultiRepositoryProvider'),
  ];

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final call = resolveWidgetCall(node);
    if (call == null) return;
    final outerCall = call.node;

    final outerType = outerCall.staticType;
    if (outerType == null) return;

    final match = _providerTypes
        .where((e) => e.$1.isExactlyType(outerType))
        .firstOrNull;
    if (match == null) return;

    final checker = match.$1;
    final multiName = match.$2;

    final providers = <Expression>[];
    Expression current = outerCall;

    while (true) {
      providers.add(current);
      final childExpr = _findChildExpression(current);
      if (childExpr != null) {
        final childType = childExpr.staticType;
        if (childType != null && checker.isExactlyType(childType)) {
          current = childExpr;
          continue;
        }
      }
      break;
    }

    if (providers.length < 2) return;

    final innermostChild = _findChildExpression(providers.last);
    if (innermostChild == null) return;

    final providerEntries = <String>[];
    for (final provider in providers) {
      providerEntries.add(_buildProviderWithoutChild(provider));
    }

    final childSource = innermostChild.toSource();
    final providersStr = providerEntries.join(',\n    ');

    final replacement =
        '$multiName(\n'
        '  providers: [\n'
        '    $providersStr,\n'
        '  ],\n'
        '  child: $childSource,\n'
        ')';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(outerCall), replacement);
    });
  }

  static String _buildProviderWithoutChild(Expression node) {
    final String constructorSource;
    final ArgumentList argumentList;

    if (node is InstanceCreationExpression) {
      constructorSource = node.constructorName.toSource();
      argumentList = node.argumentList;
    } else if (node is MethodInvocation) {
      final typeArgs = node.typeArguments?.toSource() ?? '';
      constructorSource = '${node.methodName.name}$typeArgs';
      argumentList = node.argumentList;
    } else {
      return node.toSource();
    }

    final args = argumentList.arguments
        .where((arg) => arg is! NamedArgument || arg.name.lexeme != 'child')
        .map((arg) => arg.toSource())
        .join(', ');

    return '$constructorSource($args)';
  }

  static Expression? _findChildExpression(Expression node) {
    final ArgumentList argumentList;
    if (node is InstanceCreationExpression) {
      argumentList = node.argumentList;
    } else if (node is MethodInvocation) {
      argumentList = node.argumentList;
    } else {
      return null;
    }

    for (final arg in argumentList.arguments) {
      if (arg is NamedArgument && arg.name.lexeme == 'child') {
        return arg.argumentExpression;
      }
    }
    return null;
  }
}
