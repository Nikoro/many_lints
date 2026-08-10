import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when `safeCast` is called without explicit type arguments, which
/// makes it always succeed.
///
/// `Either.safeCast` and `Option.safeCast` take their input as `dynamic` and
/// decide the outcome with `value is R`. When the call carries no type
/// arguments, `R` is inferred from context — and at a `var`/`final` binding,
/// or anywhere the context is itself unconstrained, that inference lands on
/// `dynamic`. Since every value satisfies `is dynamic`, the cast can never
/// fail: `Either.safeCast` always returns `Right`, `Option.safeCast` always
/// returns `Some`.
///
/// The result is a validator that silently validates nothing. Nothing about
/// the call looks wrong, the analyzer reports nothing, and the malformed
/// payload it was meant to reject flows straight through — usually to blow up
/// somewhere far away, as a cast error on a field.
///
/// fpdart's own API docs carry this warning on both constructors; this rule
/// enforces it.
///
/// **Bad:**
/// ```dart
/// // R infers as dynamic — always Right, whatever `json` is.
/// final result = Either.safeCast(json, (v) => 'not a map');
/// ```
///
/// **Good:**
/// ```dart
/// final result = Either<String, Map<String, dynamic>>.safeCast(
///   json,
///   (v) => 'not a map',
/// );
/// ```
class AvoidUntypedSafeCast extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_untyped_safe_cast',
    "This 'safeCast' has no explicit type argument, so it always succeeds.",
    correctionMessage:
        "Write the target type explicitly, as in "
        "'Either<L, R>.safeCast(...)' or 'Option<T>.safeCast(...)'.",
  );

  AvoidUntypedSafeCast()
    : super(
        name: 'avoid_untyped_safe_cast',
        description:
            'Warns when Either.safeCast or Option.safeCast is written without '
            'explicit type arguments, which infers the target type as dynamic '
            'and makes the cast always succeed.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUntypedSafeCast rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    if (constructorName.name?.name != 'safeCast') return;

    final element = constructorName.element;
    if (element == null) return;
    if (!_isFpdartCastTarget(element.enclosingElement)) return;

    // Written type arguments settle it: the author said what they meant, so
    // whatever they wrote is what gets tested.
    if (constructorName.type.typeArguments != null) return;

    if (!_inferredToDynamic(node.staticType)) return;

    rule.reportAtNode(constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // `safeCastStrict` is a static method rather than a constructor, and it
    // takes the input type too — but its target type is just as inferable.
    if (node.methodName.name != 'safeCastStrict') return;
    if (node.typeArguments != null) return;

    final target = node.realTarget;
    if (target is! Identifier) return;
    final targetElement = target.element;
    if (targetElement == null) return;
    if (!_isFpdartCastTarget(targetElement)) return;

    if (!_inferredToDynamic(node.staticType)) return;

    rule.reportAtNode(node.methodName);
  }

  /// Whether [element] is the `Either` or `Option` class.
  bool _isFpdartCastTarget(Element? element) =>
      element != null &&
      (eitherChecker.isExactly(element) || optionChecker.isExactly(element));

  /// Whether the value the call tests against was inferred as `dynamic`.
  ///
  /// This is the whole diagnosis: `value is dynamic` holds for every value, so
  /// such a call cannot fail. The tested type is the *last* type argument —
  /// `R` for `Either<L, R>`, `T` for `Option<T>` — since the left channel does
  /// not take part in the test.
  bool _inferredToDynamic(DartType? type) {
    if (type is! InterfaceType) return false;

    final typeArguments = type.typeArguments;
    if (typeArguments.isEmpty) return false;

    return typeArguments.last is DynamicType;
  }
}
