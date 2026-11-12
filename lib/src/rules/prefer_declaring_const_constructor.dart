import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';

import '../many_lints_rule.dart';

class PreferDeclaringConstConstructor extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_declaring_const_constructor',
    "'{0}' could declare a const constructor.",
    correctionMessage:
        "Add 'const' to the constructor, so call sites can build it at "
        'compile time.',
  );

  PreferDeclaringConstConstructor()
    : super(
        name: 'prefer_declaring_const_constructor',
        description:
            'Warns when a class could declare a const constructor but does '
            'not.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferDeclaringConstConstructor rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    // Edge case: `prefer_const_constructors_in_immutables` already reports these
    if (node.metadata.any((a) => a.name.name == 'immutable')) return;

    final element = node.declaredFragment?.element;
    if (element == null) return;
    if (element.isAbstract) return;

    final constructors = body.members
        .whereType<ConstructorDeclaration>()
        .where((constructor) => constructor.factoryKeyword == null)
        .toList(growable: false);

    if (constructors.length != 1) return;

    final constructor = constructors.single;
    if (constructor.constKeyword != null) return;
    if (constructor.body is! EmptyFunctionBody) return;
    if (constructor.redirectedConstructor != null) return;

    // Edge case: `_random = random ?? Random.secure()` is a field initializer that is not const
    for (final initializer in constructor.initializers) {
      if (initializer is! ConstructorFieldInitializer) return;
      if (!_isConstEvaluable(initializer.expression)) return;
    }

    if (!_allFieldsAreFinal(body)) return;
    if (!_supertypeHasConstConstructor(element)) return;

    rule.reportAtNode(constructor, arguments: [node.namePart.typeName.lexeme]);
  }

  bool _isConstEvaluable(Expression expression) {
    final unwrapped = expression.unParenthesized;

    return switch (unwrapped) {
      Literal() => unwrapped is! StringInterpolation,
      // Edge case: a bare identifier is a parameter or a const, both legal here
      SimpleIdentifier() => true,
      BinaryExpression(:final leftOperand, :final rightOperand) =>
        _isConstEvaluable(leftOperand) && _isConstEvaluable(rightOperand),
      PrefixExpression(:final operand) => _isConstEvaluable(operand),
      ConditionalExpression(
        :final condition,
        :final thenExpression,
        :final elseExpression,
      ) =>
        _isConstEvaluable(condition) &&
            _isConstEvaluable(thenExpression) &&
            _isConstEvaluable(elseExpression),
      InstanceCreationExpression(:final keyword) =>
        keyword?.keyword == Keyword.CONST,
      _ => false,
    };
  }

  bool _allFieldsAreFinal(BlockClassBody body) {
    for (final field in body.members.whereType<FieldDeclaration>()) {
      if (field.isStatic) continue;
      if (!field.fields.isFinal) return false;
    }

    return true;
  }

  bool _supertypeHasConstConstructor(InterfaceElement element) {
    final supertype = element.supertype;
    if (supertype == null) return true;
    if (supertype.isDartCoreObject) return true;

    return supertype.element.constructors.any(
      (constructor) => constructor.isConst,
    );
  }
}
