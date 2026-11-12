import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

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

    final isLeftToPreferFromNullable = _isNullTest(condition);
    if (isLeftToPreferFromNullable) return;

    final maxConditionComplexity = rule.config.intOption(
      'max_condition_complexity',
      defaultValue: 1,
    );
    if (_operatorCount(condition) > maxConditionComplexity) return;

    if (!_isNoneConstruction(node.elseExpression)) return;

    final wrapped = _someConstructionArgument(node.thenExpression);
    if (wrapped == null) return;

    final testsWrappedValue = _conditionMentions(condition, wrapped.toSource());
    if (!testsWrappedValue) return;

    rule.reportAtNode(node);
  }

  bool _isNullTest(Expression condition) {
    if (condition is! BinaryExpression) return false;
    final operator = condition.operator.type.lexeme;
    if (operator != '==' && operator != '!=') return false;

    return condition.leftOperand.unParenthesized is NullLiteral ||
        condition.rightOperand.unParenthesized is NullLiteral;
  }

  int _operatorCount(Expression condition) {
    final counter = _OperatorCounter();
    condition.accept(counter);
    return counter.count;
  }

  bool _conditionMentions(Expression condition, String source) {
    final finder = _SourceFinder(source);
    condition.accept(finder);
    return finder.found;
  }

  bool _isNoneConstruction(Expression expression) {
    final target = expression.unParenthesized;
    if (target is! InstanceCreationExpression) return false;

    final element = target.constructorName.element;
    if (element == null) return false;
    if (!optionChecker.isExactly(element.enclosingElement)) return false;

    final name = target.constructorName.name?.name;
    return name == 'none' || name == null;
  }

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

class _OperatorCounter extends RecursiveAstVisitor<void> {
  int count = 1;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.type.lexeme;
    if (operator == '&&' || operator == '||') count++;
    super.visitBinaryExpression(node);
  }
}

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
