import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_inference.dart';

class PreferShorthandsWithEnums extends ManyLintsRule {
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
    final nodeType = node.staticType;
    if (nodeType is! InterfaceType) return;

    final enumElement = nodeType.element;
    if (enumElement is! EnumElement) return;

    if (prefixExpression is! SimpleIdentifier) return;
    if (prefixExpression.name != enumElement.name) return;

    final contextType = inferContextType(node);
    if (contextType == null) return;

    if (!isTypeCompatible(contextType, enumElement)) return;

    rule.reportAtNode(node);
  }
}
