import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces MediaQuery.of(context).property with MediaQuery.propertyOf(context).
class UseDedicatedMediaQueryMethodsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.useDedicatedMediaQueryMethods',
    DartFixKindPriority.standard,
    'Use dedicated MediaQuery method',
  );

  UseDedicatedMediaQueryMethodsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! PropertyAccess) return;

    final methodInvocation = targetNode.target;
    if (methodInvocation is! MethodInvocation) return;

    final replacement = _getReplacementSuggestion(methodInvocation, targetNode);
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }

  String? _getReplacementSuggestion(
    MethodInvocation node,
    PropertyAccess propertyAccess,
  ) {
    final methodReplacement = _getReplacementMethodName(node, propertyAccess);
    if (methodReplacement == null) return null;

    final contextVariableName = node.argumentList.arguments.firstOrNull
        ?.toString();
    if (contextVariableName == null) return null;

    final usedMaybe = methodReplacement.startsWith('maybe');
    final shouldAddQuestionMark =
        usedMaybe && node.parent?.parent is PropertyAccess;

    return 'MediaQuery.$methodReplacement($contextVariableName)${shouldAddQuestionMark ? '?' : ''}';
  }

  String? _getReplacementMethodName(
    MethodInvocation node,
    PropertyAccess propertyAccess,
  ) {
    final usedGetter = propertyAccess.propertyName.name;

    const supportedGetters = {
      'size',
      'orientation',
      'devicePixelRatio',
      'textScaleFactor',
      'textScaler',
      'platformBrightness',
      'padding',
      'viewInsets',
      'systemGestureInsets',
      'viewPadding',
      'alwaysUse24HourFormat',
      'accessibleNavigation',
      'invertColors',
      'highContrast',
      'onOffSwitchLabels',
      'disableAnimations',
      'boldText',
      'navigationMode',
      'gestureSettings',
      'displayFeatures',
      'supportsShowingSystemContextMenu',
    };

    if (!supportedGetters.contains(usedGetter)) return null;

    return switch (node.methodName.name) {
      'of' => '${usedGetter}Of',
      'maybeOf' =>
        'maybe${usedGetter[0].toUpperCase()}${usedGetter.substring(1)}Of',
      _ => null,
    };
  }
}
