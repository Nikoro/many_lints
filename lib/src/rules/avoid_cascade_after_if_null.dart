import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a cascade expression follows an if-null (`??`) operator
/// without parentheses, which can produce unexpected results due to
/// operator precedence.
///
/// **Bad:**
/// ```dart
/// final cow = nullableCow ?? Cow()..moo();
/// ```
///
/// **Good:**
/// ```dart
/// final cow = (nullableCow ?? Cow())..moo();
/// final cow = nullableCow ?? (Cow()..moo());
/// ```
class AvoidCascadeAfterIfNull extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_cascade_after_if_null',
    'Cascade after if-null operator without parentheses can produce '
        'unexpected results.',
    correctionMessage:
        'Wrap the expression in parentheses to clarify precedence.',
  );

  AvoidCascadeAfterIfNull()
    : super(
        name: 'avoid_cascade_after_if_null',
        description:
            'Warns when a cascade follows an if-null operator '
            'without parentheses.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addCascadeExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidCascadeAfterIfNull rule;

  _Visitor(this.rule);

  @override
  void visitCascadeExpression(CascadeExpression node) {
    final target = node.target;
    if (target is BinaryExpression &&
        target.operator.type == TokenType.QUESTION_QUESTION) {
      rule.reportAtNode(node);
    }
  }
}
