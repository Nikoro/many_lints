import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a binary comparison has constant operands on both sides.
///
/// A condition like `10 == 11` or `SomeClass.value == '1'` always evaluates
/// to the same result, which usually indicates a typo or a bug.
class AvoidConstantConditions extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_constant_conditions',
    'Both sides of this comparison are constants, so the result is always the '
        'same.',
    correctionMessage:
        'Replace one operand with a variable or remove the dead condition.',
  );

  AvoidConstantConditions()
    : super(
        name: 'avoid_constant_conditions',
        description:
            'Warns when a binary comparison has constant operands on both '
            'sides.',
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
  final AvoidConstantConditions rule;

  _Visitor(this.rule);

  static const _comparisonOperators = {
    TokenType.EQ_EQ,
    TokenType.BANG_EQ,
    TokenType.LT,
    TokenType.GT,
    TokenType.LT_EQ,
    TokenType.GT_EQ,
  };

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (!_comparisonOperators.contains(node.operator.type)) return;

    if (!_isConstantExpression(node.leftOperand) ||
        !_isConstantExpression(node.rightOperand)) {
      return;
    }

    rule.reportAtNode(node);
  }

  /// Returns `true` if [expression] is a compile-time constant.
  static bool _isConstantExpression(Expression expression) {
    var expr = expression;
    while (expr is ParenthesizedExpression) {
      expr = expr.expression;
    }

    return switch (expr) {
      // Literals: 1, 'hello', true, false, null
      IntegerLiteral() => true,
      DoubleLiteral() => true,
      SimpleStringLiteral() => true,
      BooleanLiteral() => true,
      NullLiteral() => true,

      // const [1, 2] or const {1, 2}
      TypedLiteral(constKeyword: _?) => true,

      // const MyClass()
      InstanceCreationExpression(:final keyword?)
          when keyword.type == Keyword.CONST =>
        true,

      // Prefix expression on constant: -1, !true
      PrefixExpression(:final operand) => _isConstantExpression(operand),

      // Simple identifier: const x = 10; / static const field
      SimpleIdentifier() => _isConstantIdentifier(expr),

      // Prefixed identifier: SomeClass.constField
      PrefixedIdentifier(:final identifier) => _isConstantIdentifier(
        identifier,
      ),

      // Property access: SomeClass.constField (alternative AST shape)
      PropertyAccess(:final propertyName) => _isConstantIdentifier(
        propertyName,
      ),

      _ => false,
    };
  }

  /// Returns `true` if the identifier refers to a const variable or field.
  static bool _isConstantIdentifier(SimpleIdentifier id) {
    final element = id.element;

    // Local const / final variables
    if (element is VariableElement) {
      return element.isConst ||
          (element.isFinal && element.computeConstantValue() != null);
    }

    // Top-level / static const fields (resolved as synthetic getter)
    if (element is PropertyAccessorElement) {
      return element.variable.isConst;
    }

    return false;
  }
}
