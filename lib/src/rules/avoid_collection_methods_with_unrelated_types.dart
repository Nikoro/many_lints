import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_inference.dart';

class AvoidCollectionMethodsWithUnrelatedTypes extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_collection_methods_with_unrelated_types',
    "The argument type '{0}' is unrelated to the collection's type '{1}'.",
    correctionMessage: 'Use an argument that matches the collection type.',
  );

  AvoidCollectionMethodsWithUnrelatedTypes()
    : super(
        name: 'avoid_collection_methods_with_unrelated_types',
        description:
            'Warns when collection methods are called with unrelated types.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addIndexExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidCollectionMethodsWithUnrelatedTypes rule;

  _Visitor(this.rule);

  // Edge case: methods typed E, such as indexOf, are already reported by the analyzer
  static const _elementMethods = {'contains', 'remove', 'lookup'};

  static const _keyMethods = {'containsKey', 'remove'};

  static const _valueMethods = {'containsValue'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.realTarget;
    if (target == null) return;

    final targetType = target.staticType;
    if (targetType is! InterfaceType) return;

    final methodName = node.methodName.name;
    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final firstArg = args.first;
    final argType = firstArg.argumentExpression.staticType;
    if (argType == null) return;

    final mapKeyValueTypes = _getMapTypes(targetType);
    if (mapKeyValueTypes != null) {
      final (keyType, valueType) = mapKeyValueTypes;

      if (_keyMethods.contains(methodName)) {
        if (_areUnrelatedTypes(argType, keyType)) {
          rule.reportAtNode(
            node,
            arguments: [argType.getDisplayString(), keyType.getDisplayString()],
          );
        }
        return;
      }

      if (_valueMethods.contains(methodName)) {
        if (_areUnrelatedTypes(argType, valueType)) {
          rule.reportAtNode(
            node,
            arguments: [
              argType.getDisplayString(),
              valueType.getDisplayString(),
            ],
          );
        }
        return;
      }
    }

    final elementType = iterableElementType(targetType);
    if (elementType != null && _elementMethods.contains(methodName)) {
      if (_areUnrelatedTypes(argType, elementType)) {
        rule.reportAtNode(
          node,
          arguments: [
            argType.getDisplayString(),
            elementType.getDisplayString(),
          ],
        );
      }
    }
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    final target = node.realTarget;
    final targetType = target.staticType;
    if (targetType is! InterfaceType) return;

    final index = node.index;
    final indexType = index.staticType;
    if (indexType == null) return;

    final mapTypes = _getMapTypes(targetType);
    if (mapTypes != null) {
      final (keyType, _) = mapTypes;
      if (_areUnrelatedTypes(indexType, keyType)) {
        rule.reportAtNode(
          node,
          arguments: [indexType.getDisplayString(), keyType.getDisplayString()],
        );
      }
      return;
    }
  }

  static (DartType, DartType)? _getMapTypes(InterfaceType type) {
    if (type.element.name == 'Map' && type.typeArguments.length == 2) {
      return (type.typeArguments[0], type.typeArguments[1]);
    }
    for (final supertype in type.element.allSupertypes) {
      if (supertype.element.name == 'Map' &&
          supertype.typeArguments.length == 2) {
        return (supertype.typeArguments[0], supertype.typeArguments[1]);
      }
    }
    return null;
  }

  bool _areUnrelatedTypes(DartType argType, DartType expectedType) {
    final strict = rule.config.boolOption('strict', defaultValue: false);

    if (argType is VoidType || expectedType is VoidType) return false;

    if (argType is DynamicType || expectedType is DynamicType) {
      return strict &&
          argType is DynamicType &&
          expectedType is InterfaceType &&
          !expectedType.isDartCoreObject;
    }

    // Edge case: a type parameter is unknown until instantiation, even in strict mode
    if (argType is TypeParameterType || expectedType is TypeParameterType) {
      return false;
    }

    if (argType is! InterfaceType || expectedType is! InterfaceType) {
      return false;
    }

    // Edge case: elements, not types, so int? and int still count as related
    final argElement = argType.element;
    final expectedElement = expectedType.element;

    return !_isSubtypeOf(argElement, expectedElement) &&
        !_isSubtypeOf(expectedElement, argElement);
  }

  static bool _isSubtypeOf(InterfaceElement a, InterfaceElement b) {
    if (a == b) return true;
    for (final supertype in a.allSupertypes) {
      if (supertype.element == b) return true;
    }
    return false;
  }
}
