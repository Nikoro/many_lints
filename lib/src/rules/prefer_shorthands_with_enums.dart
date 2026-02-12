import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../type_inference.dart';

/// Suggests using dot shorthands instead of explicit enum prefixes.
///
/// **BAD:**
/// ```dart
/// enum MyEnum { first, second }
/// void fn(MyEnum? e) {
///   switch (e) {
///     case MyEnum.first:  // LINT
///       print(e);
///   }
///   final MyEnum another = MyEnum.first; // LINT
///   if (e == MyEnum.first) {} // LINT
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// enum MyEnum { first, second }
/// void fn(MyEnum? e) {
///   switch (e) {
///     case .first:
///       print(e);
///   }
///   final MyEnum another = .first;
///   if (e == .first) {}
/// }
/// ```
class PreferShorthandsWithEnums extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_shorthands_with_enums',
    'Prefer dot shorthands instead of explicit enum prefixes.',
    correctionMessage: 'Try removing the enum prefix.',
  );

  PreferShorthandsWithEnums()
    : super(
        name: 'prefer_shorthands_with_enums',
        description:
            'Suggests using dot shorthands instead of explicit enum prefixes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addPrefixedIdentifier(this, visitor);
    registry.addPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferShorthandsWithEnums rule;

  _Visitor(this.rule);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _checkEnumReference(node, node.prefix, node.identifier);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target case final target?) {
      _checkEnumReference(node, target, node.propertyName);
    }
  }

  void _checkEnumReference(
    Expression node,
    Expression prefixExpression,
    SimpleIdentifier identifier,
  ) {
    // The static type of the full expression should be an enum type
    final nodeType = node.staticType;
    if (nodeType is! InterfaceType) return;

    final enumElement = nodeType.element;
    if (enumElement is! EnumElement) return;

    // Verify the prefix is a simple identifier matching the enum name
    if (prefixExpression is! SimpleIdentifier) return;
    if (prefixExpression.name != enumElement.name) return;

    // Check if context type makes the enum type inferable
    final contextType = inferContextType(node);
    if (contextType == null) return;

    // The shorthand is valid when the context type matches the enum type
    if (!isTypeCompatible(contextType, enumElement)) return;

    // Report the lint
    rule.reportAtNode(node);
  }
}
