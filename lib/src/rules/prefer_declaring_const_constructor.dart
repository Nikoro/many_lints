import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';

import '../many_lints_rule.dart';

/// Warns when a class could declare a `const` constructor but does not.
///
/// A `const` constructor is what lets a value be built once at compile time
/// and shared, rather than allocated at every call. In Flutter that is the
/// difference between a widget the framework can skip rebuilding and one it
/// cannot, which is why `prefer_const_constructors` is in every lint preset —
/// but that rule only fires where a `const` constructor already exists. This
/// one asks for the constructor in the first place.
///
/// A class qualifies when every field is `final`, it declares exactly one
/// generative constructor, that constructor's body is empty, and it has no
/// initializers that are not constant.
///
/// The SDK's `prefer_const_constructors_in_immutables` covers the same ground
/// for classes marked `@immutable`; this rule covers the rest, and skips a
/// class that already carries that annotation so the two never both report.
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

    // `prefer_const_constructors_in_immutables` already owns this case.
    if (node.metadata.any((a) => a.name.name == 'immutable')) return;

    final element = node.declaredFragment?.element;
    if (element == null) return;
    if (element.isAbstract) return;

    final constructors = body.members
        .whereType<ConstructorDeclaration>()
        .where((constructor) => constructor.factoryKeyword == null)
        .toList(growable: false);

    // With no constructor there is nothing to mark; with several, adding
    // `const` to one of them is a judgement this rule cannot make.
    if (constructors.length != 1) return;

    final constructor = constructors.single;
    if (constructor.constKeyword != null) return;
    if (constructor.body is! EmptyFunctionBody) return;
    // A redirect's constness is decided by its target.
    if (constructor.redirectedConstructor != null) return;

    // Every initializer must itself be constant, or `const` will not compile.
    // Checking the *kind* of initializer is not enough: `_random = random ??
    // Random.secure()` is a field initializer whose value is a call, and
    // suggesting `const` for it produces code that does not build. Both hits
    // this rule produced on a production codebase were exactly that shape.
    for (final initializer in constructor.initializers) {
      if (initializer is! ConstructorFieldInitializer) return;
      if (!_isConstEvaluable(initializer.expression)) return;
    }

    if (!_allFieldsAreFinal(body)) return;
    if (!_supertypeHasConstConstructor(element)) return;

    rule.reportAtNode(constructor, arguments: [node.namePart.typeName.lexeme]);
  }

  /// Whether [expression] can appear in a `const` constructor's initializer.
  ///
  /// Wider than a general constant check, because a constructor parameter is
  /// a legal initializer value in a const constructor even though it is not a
  /// compile-time constant on its own. Narrower in the way that matters: a
  /// call, a cascade or an `??` over one is rejected.
  bool _isConstEvaluable(Expression expression) {
    final unwrapped = expression.unParenthesized;

    return switch (unwrapped) {
      Literal() => unwrapped is! StringInterpolation,
      // A bare identifier here is a parameter or another const; either is
      // legal in a const initializer.
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
      // `const Foo()` is fine; a bare `Foo()` is not.
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

  /// Whether the superclass offers a const constructor to chain to.
  ///
  /// Without this the suggestion would not compile: a const constructor can
  /// only call a const super constructor.
  bool _supertypeHasConstConstructor(InterfaceElement element) {
    final supertype = element.supertype;
    if (supertype == null) return true;
    if (supertype.isDartCoreObject) return true;

    return supertype.element.constructors.any(
      (constructor) => constructor.isConst,
    );
  }
}
