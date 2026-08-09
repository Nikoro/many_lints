import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns about an `as` cast or `is` check between unrelated types.
///
/// When neither type is a subtype of the other, no value can ever satisfy the
/// relation: the `as` always throws at runtime and the `is` is always `false`.
/// Both are the shape of a real mistake — a wrong variable, a stale type after
/// a refactor — rather than a deliberate narrowing.
///
/// The SDK's `unrelated_type_equality_checks` covers the `==` form of this
/// idea; casts and type tests are left uncovered, which is the gap this rule
/// fills.
///
/// **Bad:**
/// ```dart
/// void f(String value) {
///   final n = value as int; // always throws
///   if (value is int) { }   // always false
/// }
/// ```
class AvoidUnrelatedTypeCasts extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unrelated_type_casts',
    "'{0}' and '{1}' are unrelated, so this never succeeds.",
    correctionMessage:
        'Cast or test against a type in the same hierarchy, or correct the '
        'expression being checked.',
  );

  AvoidUnrelatedTypeCasts()
    : super(
        name: 'avoid_unrelated_type_casts',
        description:
            'Warns about as casts and is checks between unrelated types, '
            'which always throw or are always false.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addAsExpression(this, visitor);
    registry.addIsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnrelatedTypeCasts rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitAsExpression(AsExpression node) =>
      _check(node, node.expression.staticType, node.type.type);

  @override
  void visitIsExpression(IsExpression node) {
    // `is` checks are only reported when opted in: a downcast test on a
    // `dynamic`-typed value is idiomatic, and narrowing a sealed hierarchy can
    // look unrelated to a purely syntactic reading.
    final reportIsChecks = rule.config.boolOption(
      'report_is_checks',
      defaultValue: true,
    );
    if (!reportIsChecks) return;

    _check(node, node.expression.staticType, node.type.type);
  }

  void _check(AstNode node, DartType? sourceType, DartType? targetType) {
    if (sourceType == null || targetType == null) return;

    // `dynamic` and `Object` are compatible with everything by design, and a
    // cast from them is the normal way to narrow an untyped value.
    if (_isPermissive(sourceType) || _isPermissive(targetType)) return;

    // A type variable's real argument is unknown here, so any conclusion
    // would be guesswork.
    if (sourceType is TypeParameterType || targetType is TypeParameterType) {
      return;
    }

    // Only interface types have a hierarchy to compare. Function types,
    // records and the like are left alone.
    if (sourceType is! InterfaceType || targetType is! InterfaceType) return;

    final typeSystem = context.typeSystem;

    // Nullability is irrelevant to relatedness: `String?` and `String` are the
    // same hierarchy, and a null-only mismatch is the analyzer's business.
    // `promoteToNonNull` widens the static type back to `DartType`, so narrow
    // it again before the interface-specific checks below.
    final source = typeSystem.promoteToNonNull(sourceType);
    final target = typeSystem.promoteToNonNull(targetType);
    if (source is! InterfaceType || target is! InterfaceType) return;

    // Related in either direction is fine: downcast (target is a subtype) and
    // upcast (source is a subtype) are both legitimate.
    if (typeSystem.isSubtypeOf(source, target)) return;
    if (typeSystem.isSubtypeOf(target, source)) return;

    // A class either side could still be implemented by a common subtype, so
    // the relation is only impossible when neither can be extended into the
    // other. Bail out unless both are effectively closed to that.
    if (_couldShareSubtype(source, target)) return;

    rule.reportAtNode(
      node,
      arguments: [sourceType.getDisplayString(), targetType.getDisplayString()],
    );
  }

  /// Whether either type is compatible with everything, making any cast valid.
  bool _isPermissive(DartType type) =>
      type is DynamicType ||
      type is InvalidType ||
      type.isDartCoreObject ||
      type is VoidType;

  /// Whether some third type could implement both [source] and [target].
  ///
  /// A non-final class can always be extended by a subtype that also
  /// implements the other side, so `a as B` between two open classes is
  /// merely unusual, not impossible. Only when both sides are closed to that
  /// — final, sealed, or a type nothing can implement — is the cast provably
  /// dead.
  bool _couldShareSubtype(InterfaceType source, InterfaceType target) =>
      _isOpenToSubtypes(source) || _isOpenToSubtypes(target);

  bool _isOpenToSubtypes(InterfaceType type) {
    final element = type.element;

    // An enum has a fixed set of values; nothing new can implement it.
    if (element is EnumElement) return false;

    // `final` and `sealed` classes cannot gain outside implementations.
    if (element is ClassElement) {
      if (element.isFinal || element.isSealed) return false;

      // A class from `dart:core` such as `String` or `int` cannot be
      // meaningfully implemented alongside an unrelated one in practice.
      if (element.library.isDartCore) return false;

      return true;
    }

    // Mixins and interfaces are implementable by definition.
    return true;
  }
}
