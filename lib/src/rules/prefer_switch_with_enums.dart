import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferSwitchWithEnums extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_switch_with_enums',
    "This condition compares '{0}' against several enum constants.",
    correctionMessage:
        'Use a switch so the compiler checks that every constant is '
        'handled.',
  );

  static const _minComparisons = 3;

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
    final isElseIfBranch = node.parent is IfStatement;
    if (isElseIfBranch) return;

    String? subject;
    var comparisons = 0;

    for (IfStatement? current = node; current != null;) {
      final branch = _branchComparisons(current.expression);
      if (branch == null) return;

      subject ??= branch.subject;
      if (branch.subject != subject) return;

      comparisons += branch.count;

      final elseStatement = current.elseStatement;
      current = elseStatement is IfStatement ? elseStatement : null;
    }

    if (comparisons < PreferSwitchWithEnums._minComparisons) return;

    rule.reportAtNode(node.expression, arguments: [subject!]);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'contains') return;

    if (rule.config.boolOption('ignore_contains', defaultValue: false)) {
      return;
    }

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

    if (elements.length < PreferSwitchWithEnums._minComparisons) return;
    for (final element in elements) {
      if (element is! Expression) return;
      if (!_isEnumConstant(element)) return;
    }

    rule.reportAtNode(node, arguments: [argument.toSource()]);
  }

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
