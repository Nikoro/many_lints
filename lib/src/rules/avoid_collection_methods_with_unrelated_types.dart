import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when collection methods are called with arguments whose types are
/// unrelated to the collection's type parameter.
///
/// Such calls always return `null`, `false`, or `-1`, indicating a likely
/// logical error.
///
/// **Bad:**
/// ```dart
/// final map = <int, String>{};
/// map.containsKey('a'); // String key on int-keyed map
///
/// final set = <int>{};
/// set.contains('a'); // String in int set
/// ```
///
/// **Good:**
/// ```dart
/// final map = <int, String>{};
/// map.containsKey(42);
///
/// final set = <int>{};
/// set.contains(42);
/// ```
class AvoidCollectionMethodsWithUnrelatedTypes extends AnalysisRule {
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
  void registerNodeProcessors(
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

  /// Methods on Iterable/List/Set that accept `Object?` but semantically
  /// expect the element type. Methods with strict `E` signatures (like
  /// `indexOf`) are already caught by the Dart analyzer.
  static const _elementMethods = {
    'contains', // Iterable<E>.contains(Object?)
    'remove', // List<E>.remove(Object?), Set<E>.remove(Object?)
    'lookup', // Set<E>.lookup(Object?)
  };

  /// Methods on Map that take a key-typed argument.
  static const _keyMethods = {
    'containsKey', // Map<K,V>.containsKey(Object?)
    'remove', // Map<K,V>.remove(Object?)
  };

  /// Methods on Map that take a value-typed argument.
  static const _valueMethods = {
    'containsValue', // Map<K,V>.containsValue(Object?)
  };

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
    final argType = firstArg.staticType;
    if (argType == null) return;

    // Check if the target is a Map type.
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

    // Check if the target is an Iterable/List/Set type.
    final elementType = _getIterableElementType(targetType);
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

    // For Map<K,V>, the index should be related to K.
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

    // For List<E>, the index should be int — but that's a different concern.
    // We only check Map index access here.
  }

  /// Returns the key and value types if [type] implements `Map<K, V>`.
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

  /// Returns the element type if [type] implements `Iterable<E>`.
  ///
  /// For `List<int>`, `Set<int>`, `Iterable<int>` the first type argument
  /// is the element type. For custom subtypes we walk `allSupertypes`.
  static DartType? _getIterableElementType(InterfaceType type) {
    // List<T>, Set<T>, Iterable<T> all have element type as first arg.
    if (type.typeArguments.isNotEmpty) {
      return type.typeArguments.first;
    }
    for (final supertype in type.element.allSupertypes) {
      if (supertype.element.name == 'Iterable' &&
          supertype.typeArguments.isNotEmpty) {
        return supertype.typeArguments.first;
      }
    }
    return null;
  }

  /// Two types are "unrelated" if neither is a subtype of the other.
  ///
  /// In strict mode, even `dynamic` and `Object` are not special-cased.
  static bool _areUnrelatedTypes(DartType argType, DartType expectedType) {
    // Never flag dynamic or void — the analyzer can't know the actual type.
    if (argType is DynamicType || expectedType is DynamicType) return false;
    if (argType is VoidType || expectedType is VoidType) return false;

    // If either type is a type parameter (generic), skip — too imprecise.
    if (argType is TypeParameterType || expectedType is TypeParameterType) {
      return false;
    }

    // Both must be interface types for meaningful comparison.
    if (argType is! InterfaceType || expectedType is! InterfaceType) {
      return false;
    }

    // Ignore nullability: `int?` and `int` should still be related.
    final argElement = argType.element;
    final expectedElement = expectedType.element;

    // Check if argType is a subtype of expectedType or vice versa.
    return !_isSubtypeOf(argElement, expectedElement) &&
        !_isSubtypeOf(expectedElement, argElement);
  }

  /// Returns true if [a] is a subtype of (or the same as) [b].
  static bool _isSubtypeOf(InterfaceElement a, InterfaceElement b) {
    if (a == b) return true;
    for (final supertype in a.allSupertypes) {
      if (supertype.element == b) return true;
    }
    return false;
  }
}
