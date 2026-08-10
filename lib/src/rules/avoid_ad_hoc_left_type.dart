import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

/// Warns when an fpdart error channel carries a type outside the project's
/// failure hierarchy.
///
/// `flatMap` only composes when every step shares one left type. A pipeline
/// that starts `TaskEither<String, T>` and meets a `TaskEither<Failure, T>`
/// does not chain: it has to be bridged with `mapLeft` at each junction, and
/// the usual bridge — `(e) => e.toString()` — throws away the structure the
/// failure had. Once the left side is a `String`, the fold at the boundary can
/// no longer `switch` on what went wrong.
///
/// This rule reports nothing until `error_types` names the hierarchy, because
/// what belongs there is a project decision. Naming it makes an ad-hoc left
/// type visible at the point it is introduced rather than three layers later
/// where it has to be reconciled.
///
/// **Bad** (with `error_types: [Failure]`):
/// ```dart
/// TaskEither<String, User> load(String id) => ...;
/// ```
///
/// **Good:**
/// ```dart
/// TaskEither<Failure, User> load(String id) => ...;
/// ```
///
/// ## Options
///
/// - `error_types`: the type names allowed in the error channel. **Required** —
///   the rule is silent without it.
/// - `allow_subtypes`: when `true` (the default), a subtype of a named type is
///   accepted too, so a sealed hierarchy works by naming only its root.
class AvoidAdHocLeftType extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_ad_hoc_left_type',
    "'{0}' is not one of this project's failure types.",
    correctionMessage:
        "Use {1} in the error channel, so every step of a pipeline composes "
        'without bridging.',
  );

  AvoidAdHocLeftType()
    : super(
        name: 'avoid_ad_hoc_left_type',
        description:
            'Warns when an fpdart error channel carries a type outside the '
            'project-configured failure hierarchy. Reports nothing until '
            'error_types is set.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addNamedType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidAdHocLeftType rule;

  _Visitor(this.rule);

  @override
  void visitNamedType(NamedType node) {
    final allowed = rule.config.stringListOption('error_types');
    // A policy rule with no policy reports nothing at all.
    if (allowed.isEmpty) return;

    final typeArguments = node.typeArguments?.arguments;
    // Only the two-parameter wrappers have an error channel; `Option` and
    // `Task` have nothing to check.
    if (typeArguments == null || typeArguments.length != 2) return;

    final type = node.type;
    if (type == null) return;
    if (!failableFpdartChecker.isAssignableFromType(type)) return;

    // The error channel is the first type argument of `Either<L, R>`,
    // `TaskEither<L, R>` and `IOEither<L, R>` alike.
    final errorType = typeArguments.first;
    final resolved = errorType.type;
    if (resolved == null) return;

    if (_isAllowed(resolved, allowed)) return;

    rule.reportAtNode(
      errorType,
      arguments: [
        resolved.getDisplayString(),
        allowed.length == 1 ? "'${allowed.single}'" : _joinNames(allowed),
      ],
    );
  }

  /// Whether [type] is one of the [allowed] names, or a subtype of one.
  bool _isAllowed(DartType type, List<String> allowed) {
    final allowSubtypes = rule.config.boolOption(
      'allow_subtypes',
      defaultValue: true,
    );

    for (final name in allowed) {
      // No package pin: a project's own failure hierarchy is declared in the
      // analyzed package and has no `package:` URI to match against.
      final checker = TypeChecker.fromName(name);
      if (allowSubtypes) {
        if (checker.isAssignableFromType(type)) return true;
      } else if (checker.isExactlyType(type)) {
        return true;
      }
    }

    return false;
  }

  /// Renders the allowed names for the correction message.
  String _joinNames(List<String> names) =>
      names.map((name) => "'$name'").join(' or ');
}
