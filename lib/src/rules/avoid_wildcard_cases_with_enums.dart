import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a switch over an enum uses a wildcard or `default` case.
///
/// Switching over an enum without a catch-all gives you an exhaustiveness
/// check for free: add a constant to the enum and the compiler points at
/// every switch that must handle it. A `_` or `default` case silences that
/// check permanently — new constants fall into the catch-all and take
/// whatever behaviour was written for the cases nobody thought about.
class AvoidWildcardCasesWithEnums extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_wildcard_cases_with_enums',
    'This catch-all case disables exhaustiveness checking for {0}.',
    correctionMessage:
        'List the remaining constants explicitly so adding a new one '
        'becomes a compile error instead of silent fallthrough.',
  );

  AvoidWildcardCasesWithEnums()
    : super(
        name: 'avoid_wildcard_cases_with_enums',
        description:
            'Warns when a switch over an enum uses a wildcard or default '
            'case, which disables exhaustiveness checking.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addSwitchStatement(this, visitor);
    registry.addSwitchExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidWildcardCasesWithEnums rule;

  _Visitor(this.rule);

  @override
  void visitSwitchStatement(SwitchStatement node) {
    final enumName = _enumName(node.expression);
    if (enumName == null) return;

    for (final member in node.members) {
      switch (member) {
        case SwitchDefault():
          rule.reportAtToken(member.keyword, arguments: [enumName]);
        case SwitchPatternCase(:final guardedPattern):
          // A guarded case is conditional, so it does not make the switch
          // exhaustive and the compiler still checks the rest.
          if (guardedPattern.whenClause != null) continue;
          if (guardedPattern.pattern is WildcardPattern) {
            rule.reportAtNode(guardedPattern.pattern, arguments: [enumName]);
          }
        default:
          continue;
      }
    }
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    final enumName = _enumName(node.expression);
    if (enumName == null) return;

    for (final caseNode in node.cases) {
      final guardedPattern = caseNode.guardedPattern;
      if (guardedPattern.whenClause != null) continue;
      if (guardedPattern.pattern is WildcardPattern) {
        rule.reportAtNode(guardedPattern.pattern, arguments: [enumName]);
      }
    }
  }

  /// Returns the enum's name when [expression] switches over an enum.
  String? _enumName(Expression expression) {
    final type = expression.staticType;
    if (type is! InterfaceType) return null;

    // A nullable enum genuinely needs a null case, and `_` is a reasonable
    // way to write it.
    if (type.nullabilitySuffix != NullabilitySuffix.none) return null;

    final element = type.element;
    if (element is! EnumElement) return null;
    return element.name;
  }
}
