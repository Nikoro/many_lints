import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when `Object()` is used as a pattern instead of the wildcard `_`.
///
/// Using `Object()` without field destructuring is equivalent to `_` but less
/// idiomatic. The wildcard pattern `_` is clearer and more concise for matching
/// any value.
///
/// **BAD:**
/// ```dart
/// final value = switch (object) {
///   WithField() => 'good',
///   Object() => 'bad',
/// };
/// ```
///
/// **GOOD:**
/// ```dart
/// final value = switch (object) {
///   WithField() => 'good',
///   _ => 'good',
/// };
/// ```
class PreferWildcardPattern extends AnalysisRule {
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
  void registerNodeProcessors(
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
    if (pattern is ObjectPattern &&
        pattern.type.name.lexeme == 'Object' &&
        pattern.fields.isEmpty) {
      rule.reportAtNode(pattern);
      return;
    }

    // Walk nested patterns (e.g., Object() && somePattern)
    if (pattern is LogicalAndPattern) {
      _checkPattern(pattern.leftOperand);
      _checkPattern(pattern.rightOperand);
    }
    if (pattern is LogicalOrPattern) {
      _checkPattern(pattern.leftOperand);
      _checkPattern(pattern.rightOperand);
    }
  }
}
