import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../type_inference.dart';

/// Suggests using dot shorthands instead of explicit class prefixes for static fields.
///
/// **BAD:**
/// ```dart
/// class SomeClass {
///   final String value;
///   const SomeClass(this.value);
///   static const first = SomeClass('first');
///   static const second = SomeClass('second');
/// }
///
/// void fn(SomeClass? e) {
///   switch (e) {
///     case SomeClass.first:  // LINT
///       print(e);
///   }
///   final SomeClass another = SomeClass.first; // LINT
///   if (e == SomeClass.first) {} // LINT
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// class SomeClass {
///   final String value;
///   const SomeClass(this.value);
///   static const first = SomeClass('first');
///   static const second = SomeClass('second');
/// }
///
/// void fn(SomeClass? e) {
///   switch (e) {
///     case .first:
///       print(e);
///   }
///   final SomeClass another = .first;
///   if (e == .first) {}
/// }
/// ```
class PreferShorthandsWithStaticFields extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_shorthands_with_static_fields',
    'Prefer dot shorthands instead of explicit class prefixes.',
    correctionMessage: 'Try removing the prefix.',
  );

  PreferShorthandsWithStaticFields()
    : super(
        name: 'prefer_shorthands_with_static_fields',
        description:
            'Suggests using dot shorthands instead of explicit class prefixes for static fields.',
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
  final PreferShorthandsWithStaticFields rule;

  _Visitor(this.rule);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _checkStaticFieldReference(node, node.prefix, node.identifier);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target case final target?) {
      _checkStaticFieldReference(node, target, node.propertyName);
    }
  }

  void _checkStaticFieldReference(
    Expression node,
    Expression prefixExpression,
    SimpleIdentifier identifier,
  ) {
    // The static type of the full expression
    final nodeType = node.staticType;
    if (nodeType is! InterfaceType) return;

    // Get the field element
    final element = identifier.element;
    if (element is! PropertyAccessorElement) return;

    // Check if it's a static field/getter
    if (!element.isStatic) return;

    // Get the class that declares this static field
    final enclosingElement = element.enclosingElement;
    if (enclosingElement is! InterfaceElement) return;

    // Skip enums - they have their own rule (prefer_shorthands_with_enums)
    if (enclosingElement is EnumElement) return;

    // Verify the prefix is a simple identifier matching the class name
    if (prefixExpression is! SimpleIdentifier) return;
    if (prefixExpression.name != enclosingElement.name) return;

    // The static field's type should match the class it's declared in
    final fieldType = element.returnType;
    if (fieldType is! InterfaceType) return;
    if (fieldType.element != enclosingElement) return;

    // Check if context type makes the field type inferable
    final contextType = inferContextType(node);
    if (contextType == null) return;

    // The shorthand is valid when the context type matches the field type
    if (!isTypeCompatible(contextType, enclosingElement)) return;

    // Report the lint
    rule.reportAtNode(node);
  }
}
