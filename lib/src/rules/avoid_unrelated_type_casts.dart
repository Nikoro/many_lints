import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidUnrelatedTypeCasts extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unrelated_type_casts',
    "'{0}' and '{1}' are unrelated, so this never succeeds.",
    correctionMessage:
        'Cast or test against a type in the same hierarchy, or correct the '
        'expression being checked.',
  );

  AvoidUnrelatedTypeCasts()
    : super(
        name: 'avoid_unrelated_type_casts',
        description:
            'Warns about as casts and is checks between unrelated types, '
            'which always throw or are always false.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addAsExpression(this, visitor);
    registry.addIsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnrelatedTypeCasts rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitAsExpression(AsExpression node) =>
      _check(node, node.expression.staticType, node.type.type);

  @override
  void visitIsExpression(IsExpression node) {
    final reportIsChecks = rule.config.boolOption(
      'report_is_checks',
      defaultValue: true,
    );
    if (!reportIsChecks) return;

    _check(node, node.expression.staticType, node.type.type);
  }

  void _check(AstNode node, DartType? sourceType, DartType? targetType) {
    if (sourceType == null || targetType == null) return;

    if (_isPermissive(sourceType) || _isPermissive(targetType)) return;

    if (sourceType is TypeParameterType || targetType is TypeParameterType) {
      return;
    }

    if (sourceType is! InterfaceType || targetType is! InterfaceType) return;

    final typeSystem = context.typeSystem;

    // Edge case: promoting to non-null widens back to DartType, so the interface checks repeat
    final source = typeSystem.promoteToNonNull(sourceType);
    final target = typeSystem.promoteToNonNull(targetType);
    if (source is! InterfaceType || target is! InterfaceType) return;

    if (typeSystem.isSubtypeOf(source, target)) return;
    if (typeSystem.isSubtypeOf(target, source)) return;

    if (_couldShareSubtype(source, target)) return;

    rule.reportAtNode(
      node,
      arguments: [sourceType.getDisplayString(), targetType.getDisplayString()],
    );
  }

  bool _isPermissive(DartType type) =>
      type is DynamicType ||
      type is InvalidType ||
      type.isDartCoreObject ||
      type is VoidType;

  bool _couldShareSubtype(InterfaceType source, InterfaceType target) =>
      _isOpenToSubtypes(source) || _isOpenToSubtypes(target);

  bool _isOpenToSubtypes(InterfaceType type) {
    final element = type.element;

    if (element is EnumElement) return false;

    if (element is ClassElement) {
      if (element.isFinal || element.isSealed) return false;

      // Edge case: dart:core types like String or int are never implemented beside unrelated ones
      if (element.library.isDartCore) return false;

      return true;
    }

    return true;
  }
}
