import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_inference.dart';

class PreferShorthandsWithStaticFields extends ManyLintsRule {
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
  void registerManyLintsProcessors(
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
    final nodeType = node.staticType;
    if (nodeType is! InterfaceType) return;

    final element = identifier.element;
    if (element is! PropertyAccessorElement || !element.isStatic) return;

    final enclosingElement = element.enclosingElement;
    if (enclosingElement is! InterfaceElement) return;

    // Edge case: prefer_shorthands_with_enums owns enums.
    if (enclosingElement is EnumElement) return;

    if (prefixExpression is! SimpleIdentifier) return;
    if (prefixExpression.name != enclosingElement.name) return;

    final fieldType = element.returnType;
    if (fieldType is! InterfaceType) return;
    if (fieldType.element != enclosingElement) return;

    final contextType = inferContextType(node);
    if (contextType == null) return;

    if (!isTypeCompatible(contextType, enclosingElement)) return;

    rule.reportAtNode(node);
  }
}
