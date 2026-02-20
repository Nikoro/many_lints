import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../type_checker.dart';

/// Fix that converts nested BlocProvider / BlocListener / RepositoryProvider
/// into MultiBlocProvider / MultiBlocListener / MultiRepositoryProvider.
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
    (
      TypeChecker.fromName('BlocProvider', packageName: 'flutter_bloc'),
      'MultiBlocProvider',
    ),
    (
      TypeChecker.fromName('BlocListener', packageName: 'flutter_bloc'),
      'MultiBlocListener',
    ),
    (
      TypeChecker.fromName('RepositoryProvider', packageName: 'flutter_bloc'),
      'MultiRepositoryProvider',
    ),
  ];

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    // The reported node is either a ConstructorName or a SimpleIdentifier
    // depending on whether the AST parsed it as InstanceCreationExpression
    // or MethodInvocation.
    final Expression outerCall;
    if (targetNode is ConstructorName &&
        targetNode.parent is InstanceCreationExpression) {
      outerCall = targetNode.parent! as InstanceCreationExpression;
    } else if (targetNode is SimpleIdentifier &&
        targetNode.parent is MethodInvocation) {
      outerCall = targetNode.parent! as MethodInvocation;
    } else {
      return;
    }

    final outerType = outerCall.staticType;
    if (outerType == null) return;

    // Find which provider type
    final match = _providerTypes
        .where((e) => e.$1.isExactlyType(outerType))
        .firstOrNull;
    if (match == null) return;

    final checker = match.$1;
    final multiName = match.$2;

    // Collect all consecutive nested providers and the final child
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

    // The innermost child (non-provider) is the child of the last provider
    final innermostChild = _findChildExpression(providers.last);
    if (innermostChild == null) return;

    // Build each provider entry (without its child: arg)
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

  /// Builds a provider source without the `child:` argument.
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
        .where(
          (arg) => arg is! NamedExpression || arg.name.label.name != 'child',
        )
        .map((arg) => arg.toSource())
        .join(', ');

    return '$constructorSource($args)';
  }

  /// Extracts the `child:` expression from a provider call.
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
      if (arg is NamedExpression && arg.name.label.name == 'child') {
        return arg.expression;
      }
    }
    return null;
  }
}
