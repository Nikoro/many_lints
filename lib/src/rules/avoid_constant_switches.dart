import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a switch statement or expression evaluates a constant expression.
///
/// A switch on a constant like `switch (SomeClass.constField)` or
/// `switch (42)` always takes the same branch, which usually indicates
/// a typo or a bug.
class AvoidConstantSwitches extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_constant_switches',
    'The switch expression is a constant, so the result is always the same.',
    correctionMessage:
        'Replace the switch expression with a variable or parameter.',
  );

  AvoidConstantSwitches()
    : super(
        name: 'avoid_constant_switches',
        description:
            'Warns when a switch statement or expression evaluates a constant '
            'expression.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addSwitchStatement(this, visitor);
    registry.addSwitchExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidConstantSwitches rule;

  _Visitor(this.rule);

  @override
  void visitSwitchStatement(SwitchStatement node) {
    if (_isConstantExpression(node.expression)) {
      rule.reportAtNode(node.expression);
    }
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    if (_isConstantExpression(node.expression)) {
      rule.reportAtNode(node.expression);
    }
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
