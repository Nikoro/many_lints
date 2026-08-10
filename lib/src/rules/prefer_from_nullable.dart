import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when a null check is used to build an `Option` by hand.
///
/// `Option.fromNullable` exists for exactly this, and the conditional spells
/// out a decision the constructor already makes. Beyond the length, the manual
/// form has to name the value twice — once in the test and once in the `Some`
/// — which is where the copy-paste bug lives: `x != null ? Option.of(y) : ...`
/// compiles happily.
///
/// **Bad:**
/// ```dart
/// final option = name != null ? Option.of(name) : const Option<String>.none();
/// ```
///
/// **Good:**
/// ```dart
/// final option = Option.fromNullable(name);
/// ```
class PreferFromNullable extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_from_nullable',
    "Use 'Option.fromNullable' instead of a null check.",
    correctionMessage:
        "Replace the conditional with 'Option.fromNullable(value)'.",
  );

  PreferFromNullable()
    : super(
        name: 'prefer_from_nullable',
        description:
            'Warns when a null-check conditional builds an Option by hand '
            'instead of using Option.fromNullable.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addConditionalExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferFromNullable rule;

  _Visitor(this.rule);

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    final condition = node.condition.unParenthesized;
    if (condition is! BinaryExpression) return;

    // Work out which branch runs when the value is non-null. `x != null`
    // puts it in `then`; `x == null` swaps them.
    final Expression someBranch;
    final Expression noneBranch;
    switch (condition.operator.type.lexeme) {
      case '!=':
        someBranch = node.thenExpression;
        noneBranch = node.elseExpression;
      case '==':
        someBranch = node.elseExpression;
        noneBranch = node.thenExpression;
      default:
        return;
    }

    final tested = _nullTestedOperand(condition);
    if (tested == null) return;

    if (!_isNoneConstruction(noneBranch)) return;

    // The `Some` branch must wrap the *same* value the condition tested;
    // otherwise the conditional is doing something else entirely and
    // rewriting it would change behaviour.
    final wrapped = _someConstructionArgument(someBranch);
    if (wrapped == null) return;
    if (wrapped.toSource() != tested.toSource()) return;

    rule.reportAtNode(node);
  }

  /// The operand compared against `null`, or null when neither side is a
  /// `null` literal.
  Expression? _nullTestedOperand(BinaryExpression condition) {
    final left = condition.leftOperand.unParenthesized;
    final right = condition.rightOperand.unParenthesized;

    if (right is NullLiteral) return left;
    if (left is NullLiteral) return right;
    return null;
  }

  /// Whether [expression] builds a `None`.
  bool _isNoneConstruction(Expression expression) {
    final target = expression.unParenthesized;

    if (target is InstanceCreationExpression) {
      final element = target.constructorName.element;
      if (element == null) return false;
      if (!optionChecker.isExactly(element.enclosingElement)) return false;

      final name = target.constructorName.name?.name;
      // `Option.none()` and the `None()` subclass both spell the empty case.
      return name == 'none' || name == null;
    }

    return false;
  }

  /// The value passed to a `Some`/`Option.of` construction, or null when
  /// [expression] is not one.
  Expression? _someConstructionArgument(Expression expression) {
    final target = expression.unParenthesized;
    if (target is! InstanceCreationExpression) return null;

    final element = target.constructorName.element;
    if (element == null) return null;
    if (!optionChecker.isExactly(element.enclosingElement)) return null;

    final name = target.constructorName.name?.name;
    if (name != 'of' && name != null) return null;

    final arguments = target.argumentList.arguments;
    if (arguments.length != 1) return null;

    final argument = arguments.first;
    return argument is Expression ? argument : null;
  }
}
