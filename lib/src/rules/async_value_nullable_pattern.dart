// Ported from riverpod_lint (MIT, Copyright (c) 2023 Remi Rousselet).
// See the NOTICE file at the repository root.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../riverpod_type_checkers.dart';

/// Warns when `AsyncValue(:final value?)` is used on a possibly-nullable value.
///
/// The `?` pattern matches only when the value is non-null, so a legitimately
/// `null` success value is treated as "no value yet". Matching on `hasValue`
/// instead distinguishes "loaded a null" from "not loaded".
///
/// **BAD:**
/// ```dart
/// switch (asyncValue) {
///   case AsyncValue(:final value?): // LINT when value can be null
///     print(value);
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// switch (asyncValue) {
///   case AsyncValue(:final value, hasValue: true):
///     print(value);
/// }
/// ```
class AsyncValueNullablePattern extends AnalysisRule {
  static const LintCode code = LintCode(
    'async_value_nullable_pattern',
    'Using AsyncValue(:final value?) on a possibly nullable value is unsafe.',
    correctionMessage:
        'Try using AsyncValue(:final value, hasValue: true) instead.',
  );

  AsyncValueNullablePattern()
    : super(
        name: 'async_value_nullable_pattern',
        description:
            'Warns when AsyncValue(:final value?) is used on a possibly '
            'nullable value.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addNullCheckPattern(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AsyncValueNullablePattern rule;

  _Visitor(this.rule);

  @override
  void visitNullCheckPattern(NullCheckPattern node) {
    // Looking for `case AsyncValue(:final value?)`.
    final field = node.parent;
    if (field is! PatternField || field.effectiveName != 'value') return;

    final objectPattern = field.parent;
    if (objectPattern is! ObjectPattern) return;

    final patternType = objectPattern.type.type;
    if (patternType == null) return;

    // `AsyncData` is excluded: its `hasValue` is always true, so the null
    // check is the only thing distinguishing the cases.
    if (!asyncValueNullablePatternChecker.isExactlyType(patternType)) return;
    if (patternType is! InterfaceType) return;

    var valueType = patternType.typeArguments.first;

    // For a generic `AsyncValue<T>`, the bound decides whether the value can
    // be null; an unbounded `T` behaves like `dynamic`.
    if (valueType is TypeParameterType) {
      final bound = valueType.element.bound;
      if (bound == null) {
        // Unbounded: treat as nullable and report.
        rule.reportAtNode(node);
        return;
      }
      valueType = bound;
    }

    if (valueType is! DynamicType &&
        valueType.nullabilitySuffix != NullabilitySuffix.question) {
      return;
    }

    rule.reportAtNode(node);
  }
}
