import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/type_checker.dart';

/// Warns when using `map.keys.contains(key)` instead of `map.containsKey(key)`.
///
/// `.keys.contains` iterates through all keys and is significantly slower
/// than the built-in `containsKey` method.
class AvoidMapKeysContains extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_map_keys_contains',
    'Use containsKey() instead of .keys.contains().',
    correctionMessage: 'Replace with containsKey() for better performance.',
  );

  AvoidMapKeysContains()
    : super(
        name: 'avoid_map_keys_contains',
        description:
            'Warns when using .keys.contains() instead of containsKey().',
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
  final AvoidMapKeysContains rule;

  _Visitor(this.rule);

  static const _mapChecker = TypeChecker.fromUrl('dart:core#Map');

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'contains') return;
    if (node.argumentList.arguments.length != 1) return;

    final target = node.target;

    // map.keys.contains(x) — simple variable target parses as PrefixedIdentifier
    if (target case PrefixedIdentifier(
      identifier: SimpleIdentifier(name: 'keys'),
      prefix: SimpleIdentifier(staticType: final mapType?),
    ) when _mapChecker.isAssignableFromType(mapType)) {
      rule.reportAtNode(node);
      return;
    }

    // expr.keys.contains(x) — complex target parses as PropertyAccess
    if (target case PropertyAccess(
      propertyName: SimpleIdentifier(name: 'keys'),
      target: Expression(staticType: final mapType?),
    ) when _mapChecker.isAssignableFromType(mapType)) {
      rule.reportAtNode(node);
    }
  }
}
