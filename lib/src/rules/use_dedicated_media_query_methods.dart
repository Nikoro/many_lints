import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';

/// Suggests using MediaQuery dedicated methods instead of MediaQuery.of().property.
class UseDedicatedMediaQueryMethods extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_dedicated_media_query_methods',
    'Avoid using {0} to access only one property of MediaQueryData. Using aspects of the MediaQuery avoids unnecessary rebuilds.',
    correctionMessage: 'Use the dedicated `{1}` method instead.',
  );

  UseDedicatedMediaQueryMethods()
    : super(
        name: 'use_dedicated_media_query_methods',
        description:
            'Use MediaQuery dedicated methods instead of MediaQuery.of().property.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final UseDedicatedMediaQueryMethods rule;

  _Visitor(this.rule);

  static const _supportedGetters = {
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

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isValidMediaQueryUsage(node)) return;

    final replacementSuggestion = _getReplacementSuggestion(node);
    final parent = node.parent;

    if (replacementSuggestion == null || parent == null) return;

    rule.reportAtNode(
      parent,
      arguments: [node.toSource(), replacementSuggestion],
    );
  }

  String? _getReplacementSuggestion(MethodInvocation node) {
    final methodReplacement = _getReplacementMethodName(node);
    if (methodReplacement == null) return null;

    final contextVariableName = _getContextVariableName(node);
    if (contextVariableName == null) return null;

    final usedMaybe = methodReplacement.startsWith('maybe');
    final usedGetter = _getUsedGetter(node);
    final shouldAddQuestionMark =
        usedMaybe && usedGetter != null && _isGrandParentPropertyAccess(node);

    return 'MediaQuery.$methodReplacement($contextVariableName)${shouldAddQuestionMark ? '?' : ''}';
  }

  bool _isGrandParentPropertyAccess(MethodInvocation node) =>
      node.parent?.parent is PropertyAccess;

  String? _getContextVariableName(MethodInvocation node) =>
      node.argumentList.arguments.firstWhereOrNull((e) => true)?.toString();

  String? _getReplacementMethodName(MethodInvocation node) {
    final usedGetter = _getUsedGetter(node);

    if (usedGetter == null || !_supportedGetters.contains(usedGetter)) {
      return null;
    }

    return switch (node.methodName.name) {
      'of' => '${usedGetter}Of',
      'maybeOf' =>
        'maybe${usedGetter[0].toUpperCase()}${usedGetter.substring(1)}Of',
      _ => null,
    };
  }

  bool _isValidMediaQueryUsage(MethodInvocation node) => switch (node) {
    MethodInvocation(
      target: SimpleIdentifier(name: 'MediaQuery'),
      methodName: SimpleIdentifier(name: 'of' || 'maybeOf'),
    ) =>
      false,
    _ => true,
  };

  String? _getUsedGetter(MethodInvocation node) => switch (node.parent) {
    PropertyAccess(
      target: MethodInvocation(target: SimpleIdentifier(name: 'MediaQuery')),
      propertyName: SimpleIdentifier(name: final propertyName),
    ) =>
      propertyName,
    _ => null,
  };
}
