import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when test matchers are used with incompatible types in `expect()`.
///
/// Using incorrect matchers can lead to tests that always pass (hiding bugs)
/// or always fail (making the matcher redundant).
///
/// **Bad:**
/// ```dart
/// expect(42, isNull);         // int cannot be null
/// expect(42, isEmpty);        // int has no isEmpty property
/// expect('hello', isList);    // String is not a List
/// expect(42, hasLength(1));   // int has no length property
/// ```
///
/// **Good:**
/// ```dart
/// expect([1, 2], isList);     // List is a List
/// expect([1, 2], hasLength(2)); // List has length
/// expect(null, isNull);       // nullable type with isNull
/// ```
class AvoidMisusedTestMatchers extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_misused_test_matchers',
    "The matcher '{0}' is incompatible with the actual value type '{1}'.",
    correctionMessage: 'Use a matcher that is compatible with the actual type.',
  );

  AvoidMisusedTestMatchers()
    : super(
        name: 'avoid_misused_test_matchers',
        description:
            'Warns when test matchers are used with incompatible types.',
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

/// Categories of matchers and what types they require.
enum _MatcherCategory {
  /// isNull, isNotNull — only meaningful on nullable types.
  nullability,

  /// isEmpty, isNotEmpty — requires types with an isEmpty property
  /// (String, Iterable, Map).
  emptiness,

  /// isList — actual must be assignable to List.
  isList,

  /// isMap — actual must be assignable to Map.
  isMap,

  /// hasLength — requires types with a length property
  /// (String, Iterable, Map).
  hasLength,

  /// isZero, isNaN, isPositive, isNegative — requires num types.
  numeric,

  /// isTrue, isFalse — requires bool types.
  boolean,
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidMisusedTestMatchers rule;

  _Visitor(this.rule);

  /// Maps matcher names to their category.
  static const _matcherCategories = <String, _MatcherCategory>{
    'isNull': _MatcherCategory.nullability,
    'isNotNull': _MatcherCategory.nullability,
    'isEmpty': _MatcherCategory.emptiness,
    'isNotEmpty': _MatcherCategory.emptiness,
    'isList': _MatcherCategory.isList,
    'isMap': _MatcherCategory.isMap,
    'isZero': _MatcherCategory.numeric,
    'isNaN': _MatcherCategory.numeric,
    'isPositive': _MatcherCategory.numeric,
    'isNegative': _MatcherCategory.numeric,
    'isTrue': _MatcherCategory.boolean,
    'isFalse': _MatcherCategory.boolean,
  };

  /// Matchers that are function calls: hasLength(n).
  static const _callMatcherCategories = <String, _MatcherCategory>{
    'hasLength': _MatcherCategory.hasLength,
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'expect') return;

    final args = node.argumentList.arguments;
    if (args.length < 2) return;

    final actualExpr = args[0];
    final matcherExpr = args[1];

    final actualType = actualExpr.staticType;
    if (actualType == null || actualType is DynamicType) return;

    // Determine matcher name and category
    final (matcherName, category) = _resolveMatcherCategory(matcherExpr);
    if (matcherName == null || category == null) return;

    if (_isMisused(actualType, category)) {
      rule.reportAtNode(
        matcherExpr,
        arguments: [matcherName, actualType.getDisplayString()],
      );
    }
  }

  /// Resolves the matcher expression to its name and category.
  (String?, _MatcherCategory?) _resolveMatcherCategory(Expression expr) {
    // Simple identifier: isNull, isEmpty, isList, etc.
    if (expr is SimpleIdentifier) {
      final name = expr.name;
      return (name, _matcherCategories[name]);
    }

    // Function call: hasLength(n)
    if (expr is MethodInvocation) {
      final name = expr.methodName.name;
      return (name, _callMatcherCategories[name]);
    }

    return (null, null);
  }

  /// Returns true if the matcher is misused with the given actual type.
  bool _isMisused(DartType actualType, _MatcherCategory category) {
    return switch (category) {
      _MatcherCategory.nullability => !_isNullable(actualType),
      _MatcherCategory.emptiness => !_hasEmptinessProperty(actualType),
      _MatcherCategory.isList => !_isAssignableToList(actualType),
      _MatcherCategory.isMap => !_isAssignableToMap(actualType),
      _MatcherCategory.hasLength => !_hasLengthProperty(actualType),
      _MatcherCategory.numeric => !_isNumType(actualType),
      _MatcherCategory.boolean => !_isBoolType(actualType),
    };
  }

  /// Returns true if the type is nullable.
  static bool _isNullable(DartType type) {
    return type.nullabilitySuffix == NullabilitySuffix.question ||
        type is DynamicType;
  }

  /// Returns true if the type has isEmpty/isNotEmpty
  /// (String, Iterable, Map).
  static bool _hasEmptinessProperty(DartType type) {
    if (type is! InterfaceType) return false;
    return _isOrSubtypeOf(type, 'Iterable') ||
        _isOrSubtypeOf(type, 'Map') ||
        _isOrSubtypeOf(type, 'String');
  }

  /// Returns true if the type is assignable to List.
  static bool _isAssignableToList(DartType type) {
    if (type is! InterfaceType) return false;
    return _isOrSubtypeOf(type, 'List');
  }

  /// Returns true if the type is assignable to Map.
  static bool _isAssignableToMap(DartType type) {
    if (type is! InterfaceType) return false;
    return _isOrSubtypeOf(type, 'Map');
  }

  /// Returns true if the type has length property
  /// (String, Iterable, Map).
  static bool _hasLengthProperty(DartType type) {
    if (type is! InterfaceType) return false;
    return _isOrSubtypeOf(type, 'Iterable') ||
        _isOrSubtypeOf(type, 'Map') ||
        _isOrSubtypeOf(type, 'String');
  }

  /// Returns true if the type is num or a subtype of num (int, double).
  static bool _isNumType(DartType type) {
    if (type is! InterfaceType) return false;
    return _isOrSubtypeOf(type, 'num');
  }

  /// Returns true if the type is bool.
  static bool _isBoolType(DartType type) {
    if (type is! InterfaceType) return false;
    return type.element.name == 'bool';
  }

  /// Checks if [type] is or is a subtype of [targetName] from dart:core.
  static bool _isOrSubtypeOf(InterfaceType type, String targetName) {
    if (type.element.name == targetName) return true;
    for (final supertype in type.element.allSupertypes) {
      if (supertype.element.name == targetName) return true;
    }
    return false;
  }
}
