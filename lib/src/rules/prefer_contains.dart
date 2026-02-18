import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when using `.indexOf()` compared to `-1` instead of `.contains()`.
///
/// Using `.contains()` directly expresses the intent of checking for presence,
/// improving readability over the `.indexOf() == -1` idiom.
class PreferContains extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_contains',
    'Use .contains() instead of .indexOf() compared to -1.',
    correctionMessage: 'Replace with .contains() for better readability.',
  );

  PreferContains()
    : super(
        name: 'prefer_contains',
        description: 'Use .contains() instead of .indexOf() compared to -1.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferContains rule;

  _Visitor(this.rule);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final op = node.operator.type;
    if (op != TokenType.EQ_EQ && op != TokenType.BANG_EQ) return;

    final left = node.leftOperand;
    final right = node.rightOperand;

    // Check: x.indexOf(item) == -1 or x.indexOf(item) != -1
    if (_isIndexOfCall(left) && _isNegativeOne(right)) {
      rule.reportAtNode(node);
      return;
    }

    // Check reversed: -1 == x.indexOf(item) or -1 != x.indexOf(item)
    if (_isNegativeOne(left) && _isIndexOfCall(right)) {
      rule.reportAtNode(node);
    }
  }

  static bool _isIndexOfCall(Expression expr) {
    return expr is MethodInvocation && expr.methodName.name == 'indexOf';
  }

  static bool _isNegativeOne(Expression expr) {
    if (expr case PrefixExpression(
      operator: Token(type: TokenType.MINUS),
      operand: IntegerLiteral(value: 1),
    )) {
      return true;
    }
    return false;
  }
}
