import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when an if-case pattern uses `!= null && final field` instead of
/// the simpler `final field?` syntax, or `!= null && final Type field` where
/// the null check is redundant because the type annotation already guarantees
/// non-nullability.
class PreferSimplerPatternsNullCheck extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_simpler_patterns_null_check',
    'Use a simpler null-check pattern.',
    correctionMessage:
        'Replace with a simpler pattern that achieves the same result.',
  );

  PreferSimplerPatternsNullCheck()
    : super(
        name: 'prefer_simpler_patterns_null_check',
        description:
            'Prefer simpler null-check patterns in if-case expressions.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addIfStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSimplerPatternsNullCheck rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    final caseClause = node.caseClause;
    if (caseClause == null) return;

    final pattern = caseClause.guardedPattern.pattern;
    _checkPattern(pattern);
  }

  void _checkPattern(DartPattern pattern) {
    if (pattern is! LogicalAndPattern) return;

    final left = pattern.leftOperand;
    final right = pattern.rightOperand;

    if (left is! RelationalPattern) return;
    if (left.operator.lexeme != '!=' || left.operand is! NullLiteral) return;

    // At this point we have `!= null && <right>`
    if (right is DeclaredVariablePattern) {
      // `!= null && final field` or `!= null && final Type field`
      rule.reportAtNode(pattern);
    }
  }
}
