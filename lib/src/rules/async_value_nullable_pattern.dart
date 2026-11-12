// SPDX-FileCopyrightText: 2023 Remi Rousselet
// SPDX-License-Identifier: MIT

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../riverpod_type_checkers.dart';

class AsyncValueNullablePattern extends ManyLintsRule {
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
  void registerManyLintsProcessors(
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
    final field = node.parent;
    if (field is! PatternField || field.effectiveName != 'value') return;

    final objectPattern = field.parent;
    if (objectPattern is! ObjectPattern) return;

    final patternType = objectPattern.type.type;
    if (patternType == null) return;

    // Edge case: AsyncData always has a value, so a null check on it is deliberate and exempt
    if (!asyncValueNullablePatternChecker.isExactlyType(patternType)) return;
    if (patternType is! InterfaceType) return;

    var valueType = patternType.typeArguments.first;

    if (valueType is TypeParameterType) {
      final bound = valueType.element.bound;
      // Edge case: an unbounded type parameter behaves like dynamic
      if (bound == null) {
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
