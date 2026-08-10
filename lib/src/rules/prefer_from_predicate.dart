import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when a conditional builds an `Option` from a predicate by hand.
///
/// `Option.fromPredicate(value, test)` is the one-expression form of exactly
/// this shape. The conditional spells out a decision the constructor makes,
/// and names the value twice — once in the test and once in the `Some` — which
/// is where the mismatched-variable bug lives.
///
/// Only single-condition guards are reported by default. A three-clause
/// condition often reads better as a conditional than folded into a lambda, so
/// the threshold is a knob rather than a rule.
///
/// **Bad:**
/// ```dart
/// final option = age > 18 ? Option.of(age) : Option<int>.none();
/// ```
///
/// **Good:**
/// ```dart
/// final option = Option.fromPredicate(age, (a) => a > 18);
/// ```
///
/// ## Options
///
/// - `max_condition_complexity`: how many boolean operators the condition may
///   contain and still be reported. Defaults to `1` — a single condition.
class PreferFromPredicate extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_from_predicate',
    "Use 'Option.fromPredicate' instead of a conditional.",
    correctionMessage:
        "Replace the conditional with "
        "'Option.fromPredicate(value, (v) => condition)'.",
  );

  PreferFromPredicate()
    : super(
        name: 'prefer_from_predicate',
        description:
            'Warns when a conditional builds an Option from a predicate by '
            'hand instead of using Option.fromPredicate.',
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
  final PreferFromPredicate rule;

  _Visitor(this.rule);

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    final condition = node.condition.unParenthesized;

    // A null test is `Option.fromNullable`, reported by `prefer_from_nullable`
    // with a fix that produces better code than this rule's would.
    if (_isNullTest(condition)) return;

    if (_operatorCount(condition) >
        rule.config.intOption('max_condition_complexity', defaultValue: 1)) {
      return;
    }

    if (!_isNoneConstruction(node.elseExpression)) return;

    final wrapped = _someConstructionArgument(node.thenExpression);
    if (wrapped == null) return;

    // The wrapped value must appear in the condition, or the conditional is
    // testing one thing and wrapping another — not a predicate at all.
    if (!_conditionMentions(condition, wrapped.toSource())) return;

    rule.reportAtNode(node);
  }

  /// Whether [condition] compares something against `null`.
  bool _isNullTest(Expression condition) {
    if (condition is! BinaryExpression) return false;
    final operator = condition.operator.type.lexeme;
    if (operator != '==' && operator != '!=') return false;

    return condition.leftOperand.unParenthesized is NullLiteral ||
        condition.rightOperand.unParenthesized is NullLiteral;
  }

  /// How many boolean operators [condition] contains.
  int _operatorCount(Expression condition) {
    final counter = _OperatorCounter();
    condition.accept(counter);
    return counter.count;
  }

  /// Whether [condition] refers to [source] anywhere.
  bool _conditionMentions(Expression condition, String source) {
    final finder = _SourceFinder(source);
    condition.accept(finder);
    return finder.found;
  }

  /// Whether [expression] builds a `None`.
  bool _isNoneConstruction(Expression expression) {
    final target = expression.unParenthesized;
    if (target is! InstanceCreationExpression) return false;

    final element = target.constructorName.element;
    if (element == null) return false;
    if (!optionChecker.isExactly(element.enclosingElement)) return false;

    final name = target.constructorName.name?.name;
    return name == 'none' || name == null;
  }

  /// The value passed to a `Some`/`Option.of` construction.
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

/// Counts the boolean operators in a condition.
class _OperatorCounter extends RecursiveAstVisitor<void> {
  int count = 1;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.type.lexeme;
    if (operator == '&&' || operator == '||') count++;
    super.visitBinaryExpression(node);
  }
}

/// Looks for an expression with a given source text.
class _SourceFinder extends RecursiveAstVisitor<void> {
  final String source;
  bool found = false;

  _SourceFinder(this.source);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.toSource() == source) found = true;
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.toSource() == source) {
      found = true;
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.toSource() == source) {
      found = true;
      return;
    }
    super.visitPropertyAccess(node);
  }
}
