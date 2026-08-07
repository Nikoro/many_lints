// Ported from riverpod_lint (MIT, Copyright (c) 2023 Remi Rousselet).
// See the NOTICE file at the repository root.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../riverpod_type_checkers.dart';

/// Warns when a family provider is passed an argument that has no stable
/// equality.
///
/// Riverpod caches one provider instance per family argument, keyed by `==`.
/// An argument that builds a new object on every rebuild — a non-const literal,
/// a closure, or an instance of a class that does not override `==` — never
/// compares equal to the previous one, so the provider is recreated endlessly
/// and its state is lost.
///
/// **BAD:**
/// ```dart
/// ref.watch(myProvider([1, 2, 3]));   // LINT: new list every build
/// ref.watch(myProvider(() => 42));    // LINT: new closure every build
/// ref.watch(myProvider(Foo()));       // LINT: Foo has no ==
/// ```
///
/// **GOOD:**
/// ```dart
/// ref.watch(myProvider(const [1, 2, 3]));
/// ref.watch(myProvider(42));
/// ref.watch(myProvider(const Foo()));
/// ```
class ProviderParameters extends AnalysisRule {
  static const LintCode code = LintCode(
    'provider_parameters',
    'This argument has no stable equality, so the provider is recreated on '
        'every rebuild.',
    correctionMessage:
        'Try passing a const value, or a type that overrides ==.',
  );

  ProviderParameters()
    : super(
        name: 'provider_parameters',
        description:
            'Warns when a family provider is passed an argument that has no '
            'stable equality.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    // A family is invoked as a callable, never constructed, so instance
    // creations cannot carry family arguments.
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final ProviderParameters rule;

  _Visitor(this.rule);

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _checkExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkExpression(node);
  }

  void _checkExpression(Expression node) {
    // The expression must evaluate to a provider for its arguments to be
    // family parameters.
    final staticType = node.staticType;
    if (staticType == null) return;
    if (!providerBaseChecker.isAssignableFromType(staticType)) return;

    final arguments = _familyArgumentsOf(node);
    if (arguments == null) return;

    // Guard against provider *declarations*: `Provider.family(...)` also
    // returns a provider type, but its argument is the create callback, not a
    // family parameter. Only a call whose target is itself a family passes.
    if (!_isFamilyInvocation(node)) return;

    for (final argument in arguments.arguments) {
      final value = argument.argumentExpression;
      if (_hasUnstableEquality(value)) {
        rule.reportAtNode(value);
      }
    }
  }

  /// Returns the arguments passed to a family provider, or `null` when [node]
  /// is not a family invocation.
  ///
  /// Only a direct call carries family arguments — `myProvider(id)`. Walking
  /// through targets and property accesses (`a.b.myProvider(id)`) matches how
  /// providers are usually referenced.
  ArgumentList? _familyArgumentsOf(Expression node) {
    return switch (node) {
      FunctionExpressionInvocation() => node.argumentList,
      MethodInvocation() => node.argumentList,
      _ => null,
    };
  }

  /// Whether [node] calls an existing family to obtain a provider, rather than
  /// declaring one.
  ///
  /// `myProvider(id)` invokes a `Family`, so its arguments are the family
  /// parameters this rule checks. `Provider.family<int, T>((ref, arg) => ...)`
  /// merely builds the family, and its callback argument is not a parameter.
  bool _isFamilyInvocation(Expression node) {
    final target = switch (node) {
      FunctionExpressionInvocation() => node.function,
      MethodInvocation() => node.target,
      _ => null,
    };

    final targetType = target?.staticType;
    if (targetType == null) return false;

    return familyChecker.isAssignableFromType(targetType);
  }

  /// Whether re-evaluating [value] produces something that will not compare
  /// equal to the previous evaluation.
  bool _hasUnstableEquality(Expression value) {
    // Non-const collection literals allocate a fresh instance and do not
    // override ==.
    if (value is TypedLiteral) return !value.isConst;

    // A closure is never equal to another closure with the same body.
    if (value is FunctionExpression) return true;

    if (value is InstanceCreationExpression) {
      if (value.isConst) return false;

      final constructor = value.constructorName.element
          ?.applyRedirectedConstructors();
      var type = constructor?.enclosingElement;

      // Extension types have no identity of their own — check the underlying
      // representation type instead.
      if (type is ExtensionTypeElement) {
        final erasure = value.staticType?.extensionTypeErasure.element;
        type = erasure is InterfaceElement ? erasure : null;
      }

      // Without an `==` override, each instance is distinct.
      return type?.recursiveGetMethod('==') == null;
    }

    return false;
  }
}

extension on ConstructorElement {
  /// Follows redirecting constructors to the one that actually runs.
  ConstructorElement applyRedirectedConstructors() {
    final redirected = redirectedConstructor;
    if (redirected != null) return redirected.applyRedirectedConstructors();
    return this;
  }
}

extension on InterfaceElement {
  /// Looks up [name] on this type and its supertypes, ignoring `Object`'s
  /// identity-based implementation.
  MethodElement? recursiveGetMethod(String name) {
    if (thisType.isDartCoreObject) return null;

    final thisMethod = getMethod(name);
    if (thisMethod != null) return thisMethod;

    for (final superType in allSupertypes) {
      if (superType.isDartCoreObject) continue;

      final superMethod = superType.getMethod(name);
      if (superMethod != null) return superMethod;
    }

    return null;
  }
}
