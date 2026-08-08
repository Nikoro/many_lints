import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a condition compares one enum value against several
/// constants.
///
/// Three shapes are reported: an if-else chain, a single condition that
/// `||`-chains comparisons, and `{E.a, E.b, E.c}.contains(value)`.
///
/// A `switch` over an enum is checked for exhaustiveness: add a constant
/// and the compiler points at every switch that must handle it. None of
/// these shapes gets that check, so a new constant silently falls through
/// to the final `else` — or to nothing at all.
class PreferSwitchWithEnums extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_switch_with_enums',
    "This condition compares '{0}' against several enum constants.",
    correctionMessage:
        'Use a switch so the compiler checks that every constant is '
        'handled.',
  );

  /// Minimum number of chained comparisons before a switch is worth it.
  static const _threshold = 3;

  PreferSwitchWithEnums()
    : super(
        name: 'prefer_switch_with_enums',
        description:
            'Warns when an if-else chain compares an enum value against '
            'several constants instead of using a switch.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addIfStatement(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSwitchWithEnums rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    // Only look at the head of a chain, so one chain reports once.
    if (node.parent is IfStatement) return;

    String? subject;
    var comparisons = 0;

    for (IfStatement? current = node; current != null;) {
      // A branch may test the same value several times with `||`, as in
      // `v == E.a || v == E.b`. Each comparison counts toward the threshold.
      final branch = _branchComparisons(current.expression);
      if (branch == null) return;

      subject ??= branch.subject;
      // Every branch must test the same value for a switch to replace it.
      if (branch.subject != subject) return;

      comparisons += branch.count;

      final elseStatement = current.elseStatement;
      current = elseStatement is IfStatement ? elseStatement : null;
    }

    if (comparisons < PreferSwitchWithEnums._threshold) return;

    rule.reportAtNode(node.expression, arguments: [subject!]);
  }

  /// Reports `{E.a, E.b, E.c}.contains(value)` used as a condition.
  ///
  /// A membership test over a literal set of constants has the same blind
  /// spot as an if-else chain: adding a constant changes nothing and the
  /// compiler stays silent. Only a literal receiver is reported — a named
  /// collection is a deliberate, reusable set, not an inlined branch.
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'contains') return;

    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return;

    final argument = arguments.first;
    if (argument is! Expression) return;
    if (!_isNonNullableEnum(argument)) return;

    final target = node.realTarget;
    if (target == null) return;

    final elements = switch (target) {
      ListLiteral(:final elements) => elements,
      SetOrMapLiteral(:final elements) => elements,
      _ => null,
    };
    if (elements == null) return;

    // Every element must be an enum constant, and there must be enough of
    // them that a switch is clearer than the test.
    if (elements.length < PreferSwitchWithEnums._threshold) return;
    for (final element in elements) {
      if (element is! Expression) return;
      if (!_isEnumConstant(element)) return;
    }

    rule.reportAtNode(node, arguments: [argument.toSource()]);
  }

  /// Counts the enum comparisons in one branch condition.
  ///
  /// Handles a single `subject == E.a` and an `||` chain of them. Returns
  /// `null` when the condition tests anything else, or mixes subjects.
  ({String subject, int count})? _branchComparisons(Expression expression) {
    if (expression is BinaryExpression && expression.operator.lexeme == '||') {
      final left = _branchComparisons(expression.leftOperand);
      if (left == null) return null;

      final right = _branchComparisons(expression.rightOperand);
      if (right == null) return null;

      if (left.subject != right.subject) return null;

      return (subject: left.subject, count: left.count + right.count);
    }

    final subject = _comparedEnumSubject(expression);
    if (subject == null) return null;

    return (subject: subject, count: 1);
  }

  /// Returns the source of the compared value when [expression] is
  /// `subject == EnumType.constant`, or `null` otherwise.
  String? _comparedEnumSubject(Expression expression) {
    if (expression is! BinaryExpression) return null;
    if (expression.operator.lexeme != '==') return null;

    final left = expression.leftOperand;
    final right = expression.rightOperand;

    if (_isEnumConstant(right) && _isNonNullableEnum(left)) {
      return left.toSource();
    }
    if (_isEnumConstant(left) && _isNonNullableEnum(right)) {
      return right.toSource();
    }
    return null;
  }

  bool _isEnumConstant(Expression expression) {
    final element = switch (expression) {
      PrefixedIdentifier(:final identifier) => identifier.element,
      PropertyAccess(:final propertyName) => propertyName.element,
      _ => null,
    };

    if (element is! GetterElement) return false;
    final variable = element.variable;
    return variable is FieldElement && variable.enclosingElement is EnumElement;
  }

  bool _isNonNullableEnum(Expression expression) {
    final type = expression.staticType;
    if (type is! InterfaceType) return false;
    if (type.nullabilitySuffix != NullabilitySuffix.none) return false;
    return type.element is EnumElement;
  }
}
