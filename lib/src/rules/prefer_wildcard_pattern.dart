import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferWildcardPattern extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_wildcard_pattern',
    "Use the wildcard pattern '_' instead of 'Object()'.",
    correctionMessage: "Replace 'Object()' with '_'.",
  );

  PreferWildcardPattern()
    : super(
        name: 'prefer_wildcard_pattern',
        description:
            "Prefer the wildcard pattern '_' over 'Object()' in pattern matching.",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addSwitchExpression(this, visitor);
    registry.addSwitchStatement(this, visitor);
    registry.addIfStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferWildcardPattern rule;

  _Visitor(this.rule);

  @override
  void visitSwitchExpression(SwitchExpression node) {
    for (final caseNode in node.cases) {
      _checkPattern(caseNode.guardedPattern.pattern);
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    for (final member in node.members) {
      if (member is SwitchPatternCase) {
        _checkPattern(member.guardedPattern.pattern);
      }
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    final caseClause = node.caseClause;
    if (caseClause == null) return;
    _checkPattern(caseClause.guardedPattern.pattern);
  }

  void _checkPattern(DartPattern pattern) {
    if (pattern case ObjectPattern(
      fields: [],
      :final type,
    ) when type.name.lexeme == 'Object') {
      rule.reportAtNode(pattern);
      return;
    }

    if (pattern
        case LogicalAndPattern(:final leftOperand, :final rightOperand) ||
            LogicalOrPattern(:final leftOperand, :final rightOperand)) {
      _checkPattern(leftOperand);
      _checkPattern(rightOperand);
    }
  }
}
