import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidMisusedTestMatchers extends ManyLintsRule {
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
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

enum _MatcherCategory {
  nullability,
  emptiness,
  isList,
  isMap,
  hasLength,
  numeric,
  boolean,
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidMisusedTestMatchers rule;

  _Visitor(this.rule);

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
    if (actualExpr is! Expression || matcherExpr is! Expression) return;

    final actualType = actualExpr.staticType;
    if (actualType == null || actualType is DynamicType) return;

    final (matcherName, category) = _resolveMatcherCategory(matcherExpr);
    if (matcherName == null || category == null) return;

    if (_isMisused(actualType, category)) {
      rule.reportAtNode(
        matcherExpr,
        arguments: [matcherName, actualType.getDisplayString()],
      );
    }
  }

  (String?, _MatcherCategory?) _resolveMatcherCategory(Expression expr) {
    if (expr is SimpleIdentifier) {
      final name = expr.name;
      return (name, _matcherCategories[name]);
    }

    if (expr is MethodInvocation) {
      final name = expr.methodName.name;
      return (name, _callMatcherCategories[name]);
    }

    return (null, null);
  }

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

  static bool _isNullable(DartType type) {
    return type.nullabilitySuffix == NullabilitySuffix.question ||
        type is DynamicType;
  }

  static bool _hasEmptinessProperty(DartType type) {
    if (type is! InterfaceType) return false;
    return _isOrSubtypeOf(type, 'Iterable') ||
        _isOrSubtypeOf(type, 'Map') ||
        _isOrSubtypeOf(type, 'String');
  }

  static bool _isAssignableToList(DartType type) {
    if (type is! InterfaceType) return false;
    return _isOrSubtypeOf(type, 'List');
  }

  static bool _isAssignableToMap(DartType type) {
    if (type is! InterfaceType) return false;
    return _isOrSubtypeOf(type, 'Map');
  }

  static bool _hasLengthProperty(DartType type) {
    if (type is! InterfaceType) return false;
    return _isOrSubtypeOf(type, 'Iterable') ||
        _isOrSubtypeOf(type, 'Map') ||
        _isOrSubtypeOf(type, 'String');
  }

  static bool _isNumType(DartType type) {
    if (type is! InterfaceType) return false;
    return _isOrSubtypeOf(type, 'num');
  }

  static bool _isBoolType(DartType type) {
    if (type is! InterfaceType) return false;
    return type.element.name == 'bool';
  }

  static bool _isOrSubtypeOf(InterfaceType type, String targetName) {
    if (type.element.name == targetName) return true;
    for (final supertype in type.element.allSupertypes) {
      if (supertype.element.name == targetName) return true;
    }
    return false;
  }
}
